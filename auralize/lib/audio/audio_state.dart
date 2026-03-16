import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'audio_service.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(service.dispose);
  return service;
});

final currentSongProvider = StreamProvider<SongItem?>((ref) {
  final service = ref.watch(audioServiceProvider);
  return service.currentSongStream;
});

final isListeningProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(audioServiceProvider);
  return service.playingStream;
});

// Songs are now loaded via file picker — no FutureProvider needed