import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../audio/audio_service.dart';
import '../audio/audio_state.dart';

class SongPickerScreen extends ConsumerStatefulWidget {
  const SongPickerScreen({super.key});

  @override
  ConsumerState<SongPickerScreen> createState() => _SongPickerScreenState();
}

class _SongPickerScreenState extends ConsumerState<SongPickerScreen> {
  List<SongItem> _songs = [];
  bool _loading = false;
  int? _startingSongId;
  String? _statusMessage;
  SongLoadState _statusState = SongLoadState.idle;

  @override
  void initState() {
    super.initState();
    _loadCachedSongs();
  }

  Future<void> _loadCachedSongs() async {
    final service = ref.read(audioServiceProvider);
    await service.loadPersistedSongs();
    if (!mounted) return;
    setState(() {
      _songs = service.songs;
      _statusState = _songs.isEmpty ? SongLoadState.cancelled : SongLoadState.idle;
      _statusMessage = _songs.isEmpty
          ? 'No songs in your library yet. Add tracks to start playback.'
          : null;
    });
  }

  Future<void> _pickSongs() async {
    setState(() => _loading = true);
    final service = ref.read(audioServiceProvider);
    final songs = await service.fetchSongs(repick: true);
    if (mounted) {
      setState(() {
        _songs = songs;
        _statusState = service.songLoadState;
        _statusMessage = service.songLoadMessage;
        _loading = false;
      });
    }
  }

  Future<void> _handlePrimaryAction() async {
    if (_statusState == SongLoadState.permissionDenied) {
      await openAppSettings();
      return;
    }
    await _pickSongs();
  }

  String formatDuration(int? ms) {
    if (ms == null) return '--:--';
    final d = Duration(milliseconds: ms);
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.read(audioServiceProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'YOUR MUSIC',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Re-pick files button
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFFFF2D9B)),
            onPressed: _pickSongs,
            tooltip: 'Add songs',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: Colors.white12),
        ),
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFFF2D9B)),
                  SizedBox(height: 16),
                  Text(
                    'Loading your library...',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            )
          : _songs.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.audio_file_rounded,
                            color: Colors.white24, size: 56),
                        const SizedBox(height: 20),
                        Text(
                          _statusState == SongLoadState.permissionDenied
                              ? 'Music access required'
                              : _statusState == SongLoadState.readFailure
                                  ? 'Unable to read selected files'
                                  : 'No songs loaded yet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _statusMessage ??
                              'Tap the + button to pick music\nfrom your device storage',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 13,
                            height: 1.8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        GestureDetector(
                          onTap: _handlePrimaryAction,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: const Color(0xFFFF2D9B)),
                            ),
                            child: Text(
                              _statusState == SongLoadState.permissionDenied
                                  ? 'Open settings'
                                  : 'Browse files',
                              style: const TextStyle(
                                color: Color(0xFFFF2D9B),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _songs.length,
                  itemBuilder: (context, index) {
                    final song = _songs[index];
                    final isCurrent = service.currentSong?.id == song.id;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFFFF2D9B).withValues(alpha: 0.15)
                              : Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: song.artworkBytes != null
                            ? Image.memory(
                                song.artworkBytes!,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => Icon(
                                  isCurrent
                                      ? Icons.equalizer_rounded
                                      : Icons.album_rounded,
                                  color: isCurrent
                                      ? const Color(0xFFFF2D9B)
                                      : Colors.white38,
                                  size: 20,
                                ),
                              )
                            : Icon(
                                isCurrent
                                    ? Icons.equalizer_rounded
                                    : Icons.album_rounded,
                                color: isCurrent
                                    ? const Color(0xFFFF2D9B)
                                    : Colors.white38,
                                size: 20,
                              ),
                      ),
                      title: Text(
                        song.title,
                        style: TextStyle(
                          color: isCurrent
                              ? const Color(0xFFFF2D9B)
                              : Colors.white,
                          fontSize: 14,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${song.artist} • ${formatDuration(song.duration)}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isCurrent
                          ? (_startingSongId == song.id
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.1,
                                      color: Color(0xFFFF2D9B),
                                    ),
                                  )
                                : null)
                          : (_startingSongId == song.id
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.1,
                                      color: Color(0xFFFF2D9B),
                                    ),
                                  )
                                : const Icon(
                                    Icons.play_circle_outline_rounded,
                                    color: Colors.white24,
                                    size: 20,
                                  )),
                      onTap: () async {
                        if (_startingSongId != null) return;
                        setState(() => _startingSongId = song.id);
                        final started = await service.playSong(song);
                        if (mounted) {
                          setState(() => _startingSongId = null);
                        }
                        if (started) {
                          if (context.mounted) Navigator.pop(context);
                          return;
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Unable to start this track. Try another file.',
                              ),
                              backgroundColor: Colors.black87,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
    );
  }
}
