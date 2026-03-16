import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:audio_waveforms/audio_waveforms.dart' show PlayerController;
import 'package:dart_tags/dart_tags.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:just_audio_background/just_audio_background.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SongLoadState { idle, permissionDenied, cancelled, readFailure }

class SongItem {
  final String path;
  final String title;
  final String artist;
  final int? duration;
  final int id;
  final String? album;
  final String? artworkBase64;

  SongItem({
    required this.path,
    required this.title,
    required this.artist,
    this.duration,
    required this.id,
    this.album,
    this.artworkBase64,
  });

  Uint8List? get artworkBytes {
    if (artworkBase64 == null || artworkBase64!.isEmpty) return null;
    try {
      return base64Decode(artworkBase64!);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'title': title,
      'artist': artist,
      'duration': duration,
      'id': id,
      'album': album,
      'artworkBase64': artworkBase64,
    };
  }

  factory SongItem.fromJson(Map<String, dynamic> json) {
    return SongItem(
      path: json['path'] as String,
      title: (json['title'] as String?) ?? 'Unknown Title',
      artist: (json['artist'] as String?) ?? 'Unknown',
      duration: json['duration'] as int?,
      id: (json['id'] as int?) ?? (json['path'] as String).hashCode,
      album: json['album'] as String?,
      artworkBase64: json['artworkBase64'] as String?,
    );
  }
}

class AudioService {
  final ja.AudioPlayer _audioPlayer = ja.AudioPlayer();
  final PlayerController _waveformController = PlayerController();
  final TagProcessor _tagProcessor = TagProcessor();

  SongItem? currentSong;
  List<double> _extractedWaveform = [];
  int _currentDurationMs = 0;
  int _maxDurationMs = 1;
  List<SongItem> _songs = [];
  bool _libraryLoaded = false;
  bool _queueDirty = true;
  final String _storageKey = 'auralize_song_library_v1';
  SongLoadState _songLoadState = SongLoadState.idle;
  String? _songLoadMessage;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<ja.SequenceState>? _sequenceStateSub;
  StreamSubscription<ja.PlayerState>? _playerStateSub;

  final List<double> smoothedFFT = List.filled(256, 0.0);

  final StreamController<SongItem?> _currentSongController = StreamController<SongItem?>.broadcast();
  Stream<SongItem?> get currentSongStream => _currentSongController.stream;

  AudioService() {
    _positionSub = _audioPlayer.positionStream.listen((position) {
      _currentDurationMs = position.inMilliseconds;
    });
    _durationSub = _audioPlayer.durationStream.listen((duration) {
      final ms = duration?.inMilliseconds ?? 1;
      _maxDurationMs = ms > 0 ? ms : 1;
    });
    _sequenceStateSub = _audioPlayer.sequenceStateStream.listen((state) {
      final source = state.currentSource;
      if (source == null) return;
      final tag = source.tag as MediaItem?;
      if (tag == null) return;
      try {
        currentSong = _songs.firstWhere((s) => s.path == tag.id);
        _currentSongController.add(currentSong);
        unawaited(_extractWaveformFor(currentSong!));
      } catch (_) {}
    });
    _playerStateSub = _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ja.ProcessingState.completed) {
        unawaited(
          _audioPlayer.seek(
            Duration.zero,
            index: _audioPlayer.currentIndex,
          ),
        );
        unawaited(_audioPlayer.pause());
      }
    });
    unawaited(loadPersistedSongs());
  }

  Future<void> loadPersistedSongs() async {
    if (_libraryLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _songs = decoded
              .whereType<Map>()
              .map((e) => SongItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
      final beforeCount = _songs.length;
      _songs = _songs.where((song) {
        if (_isContentUriPath(song.path)) return true;
        if (_isHttpUriPath(song.path)) return true;
        return File(song.path).existsSync();
      }).toList();
      _queueDirty = true;
      if (_songs.length != beforeCount) {
        await _persistSongs();
      }

      // Check if player is already running (e.g. app restart) and sync state
      final currentSource = _audioPlayer.sequenceState.currentSource;
      if (currentSource != null && currentSong == null) {
        final tag = currentSource.tag as MediaItem?;
        if (tag != null) {
          try {
            currentSong = _songs.firstWhere((s) => s.path == tag.id);
            unawaited(_extractWaveformFor(currentSong!));
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('loadPersistedSongs error: $e');
    } finally {
      _libraryLoaded = true;
    }
  }

  Future<void> _persistSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode(_songs.map((song) => song.toJson()).toList());
      await prefs.setString(_storageKey, payload);
    } catch (e) {
      debugPrint('persistSongs error: $e');
    }
  }

  ({String title, String artist}) _parseMetadata(String filename) {
    // Remove the file extension generically
    final lastDotIndex = filename.lastIndexOf('.');
    final withoutExtension = lastDotIndex != -1 
        ? filename.substring(0, lastDotIndex) 
        : filename;
        
    final parts = withoutExtension.split(RegExp(r'\s+-\s+'));
    if (parts.length >= 2) {
      return (title: parts.sublist(1).join(' - '), artist: parts.first.trim());
    }
    return (title: withoutExtension.trim(), artist: 'Unknown');
  }

  bool _isContentUriPath(String path) {
    return path.startsWith('content://');
  }

  bool _isHttpUriPath(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  bool _isLocalFilePath(String path) {
    return !_isContentUriPath(path) &&
        !_isHttpUriPath(path) &&
        !path.startsWith('file://');
  }

  Uri _toPlayableUri(String path) {
    if (_isContentUriPath(path) ||
        _isHttpUriPath(path) ||
        path.startsWith('file://')) {
      return Uri.parse(path);
    }
    return Uri.file(path);
  }

  int get _currentSongIndex {
    final song = currentSong;
    if (song == null) return -1;
    return _songs.indexWhere((item) => item.path == song.path);
  }

  Future<bool> _ensureAudioPermission() async {
    if (!Platform.isAndroid) return true;
    
    // Request audio permission
    final audioStatus = await Permission.audio.request();
    // Request video permission for Android 13+
    final videoStatus = await Permission.videos.request();
    
    if ((audioStatus.isGranted || audioStatus.isLimited) && 
        (videoStatus.isGranted || videoStatus.isLimited)) {
      return true;
    }
    
    // Fallback for older Android versions
    final storageStatus = await Permission.storage.request();
    return storageStatus.isGranted || storageStatus.isLimited;
  }

  Future<SongItem> _buildSongItem(PlatformFile file) async {
    final String path = file.path!;
    final parsed = _parseMetadata(file.name);
    String title = parsed.title;
    String artist = parsed.artist;
    String? album;
    String? artworkBase64;
    int? duration;

    if (_isLocalFilePath(path)) {
      try {
        final file = File(path);
        if (await file.exists()) {
          // Try to read tags using dart_tags
          // Note: This library primarily supports audio tags.
          // For video files, this might return empty list or fail gracefully.
          try {
            final tags = await _tagProcessor.getTagsFromByteArray(
              file.readAsBytes(),
            );
            for (final tag in tags) {
              final data = tag.tags;
              final tagTitle = (data['title'] ?? data['TIT2'])?.toString().trim();
              final tagArtist = (data['artist'] ?? data['TPE1'])?.toString().trim();
              final tagAlbum = (data['album'] ?? data['TALB'])?.toString().trim();
              final lengthRaw = data['TLEN']?.toString().trim();
              final picture = data['picture'] ?? data['APIC'];

              if (tagTitle != null && tagTitle.isNotEmpty) {
                title = tagTitle;
              }
              if (tagArtist != null && tagArtist.isNotEmpty) {
                artist = tagArtist;
              }
              if (tagAlbum != null && tagAlbum.isNotEmpty) {
                album = tagAlbum;
              }
              if (lengthRaw != null) {
                final parsedDuration = int.tryParse(lengthRaw);
                if (parsedDuration != null && parsedDuration > 0) {
                  duration = parsedDuration;
                }
              }
              if (picture is AttachedPicture && picture.imageData.isNotEmpty) {
                artworkBase64 = picture.imageData64;
              } else if (picture is List && picture.isNotEmpty) {
                final firstPicture = picture.firstWhere(
                  (item) => item is AttachedPicture,
                  orElse: () => null,
                );
                if (firstPicture is AttachedPicture &&
                    firstPicture.imageData.isNotEmpty) {
                  artworkBase64 = firstPicture.imageData64;
                }
              }
            }
          } catch (e) {
             debugPrint('Tag processing failed for $path: $e');
             // Proceed with default metadata if tag reading fails
          }
        }
      } catch (e) {
        debugPrint('metadata read error for $path: $e');
      }
    }

    return SongItem(
      path: path,
      title: title,
      artist: artist,
      duration: duration,
      id: path.hashCode,
      album: album,
      artworkBase64: artworkBase64,
    );
  }

  Future<List<SongItem>> fetchSongs({bool repick = false}) async {
    try {
      _songLoadState = SongLoadState.idle;
      _songLoadMessage = null;
      await loadPersistedSongs();
      if (_songs.isNotEmpty && !repick) return _songs;

      final hasPermission = await _ensureAudioPermission();
      if (!hasPermission) {
        _songLoadState = SongLoadState.permissionDenied;
        _songLoadMessage =
            'Media access is denied. Enable permissions in app settings.';
        return _songs;
      }

      // Allow selecting both audio and video files with comprehensive format support
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          // Audio
          'mp3', 'wav', 'aac', 'flac', 'm4a', 'ogg', 'wma', 'opus', 'amr', 'aiff', 'alac', 'pcm',
          // Video
          'mp4', 'webm', 'mkv', 'mov', 'avi', 'wmv', 'm4v', '3gp', 'ts', 'flv', 'f4v', 'mpg', 'mpeg'
        ],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        _songLoadState = SongLoadState.cancelled;
        _songLoadMessage = 'No media files were selected.';
        return _songs;
      }

      final List<SongItem> loaded = [];
      for (final file in result.files) {
        if (file.path == null) continue;
        try {
           loaded.add(await _buildSongItem(file));
        } catch (e) {
           debugPrint('Error loading file ${file.name}: $e');
        }
      }

      if (repick && _songs.isNotEmpty) {
        final Map<String, SongItem> merged = {
          for (final song in _songs) song.path: song,
        };
        for (final song in loaded) {
          merged[song.path] = song;
        }
        _songs = merged.values.toList();
      } else {
        _songs = loaded;
      }
      _queueDirty = true;
      await _persistSongs();
      return _songs;
    } catch (e) {
      _songLoadState = SongLoadState.readFailure;
      _songLoadMessage = 'Could not read the selected files. Try again.';
      debugPrint('fetchSongs error: $e');
      return _songs;
    }
  }

  List<SongItem> get songs => _songs;

  Future<void> _extractWaveformFor(SongItem song) async {
    try {
      // Basic check for video extensions to potentially skip or handle differently
      // The audio_waveforms package might fail on video files.
      // If it fails, we catch the error and set an empty waveform.
      
      // Update: audio_waveforms often fails on files without standard extensions or specific codecs
      // We will try to extract, but if it fails, we'll generate a dummy waveform so visualizers still work (simulated)
      
      try {
        _extractedWaveform =
            await _waveformController.waveformExtraction.extractWaveformData(
          path: song.path,
          noOfSamples: 256,
        );
      } catch (e) {
        debugPrint('Real waveform extraction failed: $e. Using fallback.');
        _extractedWaveform = [];
      }
      
      if (_extractedWaveform.isEmpty) {
         // Clear the waveform to trigger the dynamic fallback in updateFFT
         _extractedWaveform = [];
      }
    } catch (e) {
      _extractedWaveform = [];
      debugPrint('extractWaveform critical error for ${song.title}: $e');
    }
  }

  Future<void> _setQueueAndSelectIndex(int index) async {
    final sources = _songs
        .map(
          (song) => ja.AudioSource.uri(
            _toPlayableUri(song.path),
            tag: MediaItem(
              id: song.path,
              title: song.title,
              artist: song.artist,
              duration: song.duration == null
                  ? null
                  : Duration(milliseconds: song.duration!),
            ),
          ),
        )
        .toList();
    
    // just_audio_background recommends setAudioSources
    await _audioPlayer.setAudioSources(
      sources,
      initialIndex: index,
      initialPosition: Duration.zero,
    );
    _queueDirty = false;
  }

  Future<void> _setSingleSource(SongItem song) async {
    await _audioPlayer.setAudioSource(
      ja.AudioSource.uri(
        _toPlayableUri(song.path),
        tag: MediaItem(
          id: song.path,
          title: song.title,
          artist: song.artist,
          duration: song.duration == null
              ? null
              : Duration(milliseconds: song.duration!),
        ),
      ),
      initialPosition: Duration.zero,
    );
  }

  Future<bool> playSong(SongItem song) async {
    try {
      debugPrint('Attempting to play: ${song.title} (${song.path})');
      await loadPersistedSongs();
      int index = _songs.indexWhere((s) => s.path == song.path);
      if (index == -1) {
        _songs.add(song);
        index = _songs.length - 1;
        _queueDirty = true;
        await _persistSongs();
      }
      currentSong = song;
      _currentSongController.add(currentSong);
      _currentDurationMs = 0;
      if (_queueDirty || _audioPlayer.audioSource == null) {
        try {
          await _setQueueAndSelectIndex(index);
        } catch (e) {
          debugPrint('queue load fallback error: $e');
          // Try single source fallback
          try {
             await _setSingleSource(song);
             _queueDirty = false;
          } catch (e2) {
             debugPrint('Single source fallback failed: $e2');
             return false;
          }
        }
      } else {
        try {
          await _audioPlayer.seek(Duration.zero, index: index);
        } catch (e) {
          debugPrint('Seek failed: $e. Retrying with single source.');
          try {
             await _setSingleSource(song);
             _queueDirty = false;
          } catch (e2) {
             debugPrint('Single source fallback after seek failed: $e2');
             return false;
          }
        }
      }
      await _audioPlayer.play();
      unawaited(_extractWaveformFor(song));
      debugPrint('Successfully playing: ${song.title}');
      return true;
    } catch (e) {
      debugPrint('playSong critical error: $e');
      return false;
    }
  }

  Future<void> togglePlayPause() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> playNext() async {
    if (!_audioPlayer.hasNext && _songs.length > 1 && currentSong != null) {
      final currentIndex = _currentSongIndex;
      if (currentIndex >= 0) {
        await _setQueueAndSelectIndex(currentIndex);
      }
    }
    if (_audioPlayer.hasNext) {
      await _audioPlayer.seekToNext();
      await _audioPlayer.play();
    }
  }

  Future<void> playPrevious() async {
    if (!_audioPlayer.hasPrevious && _songs.length > 1 && currentSong != null) {
      final currentIndex = _currentSongIndex;
      if (currentIndex >= 0) {
        await _setQueueAndSelectIndex(currentIndex);
      }
    }
    if (_audioPlayer.hasPrevious) {
      await _audioPlayer.seekToPrevious();
      await _audioPlayer.play();
    }
  }

  Future<void> seekToMs(int milliseconds) async {
    await _audioPlayer.seek(Duration(milliseconds: milliseconds));
  }

  void stopListening() {
    _audioPlayer.stop();
  }

  void updateFFT() {
    // If not listening, just decay the FFT
    if (!isListening) {
      for (int i = 0; i < 256; i++) {
        smoothedFFT[i] *= 0.92;
      }
      return;
    }

    // If no waveform is available (e.g. unsupported file type), generate dynamic random data
    if (_extractedWaveform.isEmpty) {
       final random = math.Random();
       for (int i = 0; i < 256; i++) {
         // Create a more organic movement by smoothing the random values
         final target = random.nextDouble();
         smoothedFFT[i] = smoothedFFT[i] * 0.7 + target * 0.3;
       }
       return;
    }

    try {
      final int safeDuration = _maxDurationMs > 0 ? _maxDurationMs : 1;
      // Ensure we don't divide by zero or get NaN
      final double progress =
          (_currentDurationMs / safeDuration).clamp(0.0, 1.0);
      
      // If waveform is very short, treat it as if it's empty/failed and use random fallback
      if (_extractedWaveform.length < 256) {
          final random = math.Random();
          for (int i = 0; i < 256; i++) {
             final target = random.nextDouble();
             smoothedFFT[i] = smoothedFFT[i] * 0.7 + target * 0.3;
          }
          return;
      }

      final int center = (progress * (_extractedWaveform.length - 1)).floor();
      const int halfWindow = 128;

      for (int i = 0; i < 256; i++) {
        final int srcIndex =
            (center - halfWindow + i).clamp(0, _extractedWaveform.length - 1);
        
        double rawValue = _extractedWaveform[srcIndex].abs();
        final double freqCurve = 1.0 - (i / 256.0) * 0.5;
        final double value = (rawValue * freqCurve).clamp(0.0, 1.0);
        smoothedFFT[i] = smoothedFFT[i] * 0.72 + value * 0.28;
      }
    } catch (e) {
      debugPrint('updateFFT error: $e');
    }
  }

  bool detectBeat({double threshold = 0.4}) {
    if (!isListening) return false;
    double bass = 0;
    for (int i = 0; i < 10; i++) {
      bass += smoothedFFT[i];
    }
    return (bass / 10) > threshold;
  }

  int get currentDurationMs => _currentDurationMs;
  int get maxDurationMs => _maxDurationMs;
  bool get hasNext {
    if (_audioPlayer.hasNext) return true;
    final currentIndex = _currentSongIndex;
    return currentIndex >= 0 && currentIndex < _songs.length - 1;
  }

  bool get hasPrevious {
    if (_audioPlayer.hasPrevious) return true;
    final currentIndex = _currentSongIndex;
    return currentIndex > 0 && currentIndex < _songs.length;
  }
  SongLoadState get songLoadState => _songLoadState;
  String? get songLoadMessage => _songLoadMessage;
  Stream<int> get positionMsStream =>
      _audioPlayer.positionStream.map((d) => d.inMilliseconds);
  bool get isListening => _audioPlayer.playing;
  bool get isActuallyPlaying => _audioPlayer.playing;
  Stream<bool> get playingStream => _audioPlayer.playingStream;

  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _sequenceStateSub?.cancel();
    _playerStateSub?.cancel();
    _currentSongController.close();
    _audioPlayer.dispose();
    _waveformController.dispose();
  }
}
