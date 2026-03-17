import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../audio/audio_state.dart';
import '../widgets/visualizer_canvas.dart';
import 'song_picker_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _backgroundIndicatorController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _backgroundIndicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _backgroundIndicatorController.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    final service = ref.read(audioServiceProvider);
    if (service.currentSong == null) {
      _openPicker();
      return;
    }
    await service.togglePlayPause();
  }

  Future<void> _playPrevious() async {
    final service = ref.read(audioServiceProvider);
    if (service.currentSong == null) {
      // If no song is playing, opening the picker is reasonable,
      // but "Previous" usually implies going back in the queue or history.
      // If the queue is empty, maybe just open picker or do nothing.
      _openPicker();
      return;
    }
    
    // Check if we are more than 3 seconds into the song; if so, restart it.
    if (service.currentDurationMs > 3000) {
      await service.seekToMs(0);
    } else {
      await service.playPrevious();
    }
  }

  Future<void> _playNext() async {
    final service = ref.read(audioServiceProvider);
    if (service.currentSong == null) {
      _openPicker();
      return;
    }
    await service.playNext();
  }

  void _openPicker() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SongPickerScreen()),
    );
  }

  void _switchMode(VisualizerMode mode) {
    ref.read(visualizerModeProvider.notifier).state = mode;
  }

  String formatDuration(int ms) {
    final d = Duration(milliseconds: ms);
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isListening = ref.watch(isListeningProvider).value ?? false;
    final currentMode = ref.watch(visualizerModeProvider);
    final service = ref.watch(audioServiceProvider);
    final currentSong = ref.watch(currentSongProvider).value;

    if (isListening && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
      _backgroundIndicatorController.repeat();
    } else if (!isListening && _pulseController.isAnimating) {
      _pulseController.animateTo(0.0, duration: const Duration(milliseconds: 300));
      _backgroundIndicatorController.stop();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [

            // ── Top bar ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AURALIZE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                    ),
                  ).animate().fadeIn(duration: 800.ms).slideX(begin: -0.2, curve: Curves.easeOut),
                  Row(
                    children: [
                      if (isListening)
                        const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Color(0xFF00FFCC),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      const SizedBox(width: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isListening
                              ? const Color(0xFF00FFCC)
                              : Colors.white24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Now playing bar ───────────────────────────
            GestureDetector(
              onTap: _openPicker,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: currentSong?.artworkBytes != null
                          ? Image.memory(
                              currentSong!.artworkBytes!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                Icons.album_rounded,
                                color: Color(0xFFFF2D9B),
                                size: 20,
                              ),
                            )
                          : const Icon(
                              Icons.album_rounded,
                              color: Color(0xFFFF2D9B),
                              size: 20,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: currentSong == null
                          ? const Text(
                              'Tap to choose a song from your library',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 13,
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentSong.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  currentSong.artist,
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (currentSong.album != null &&
                                    currentSong.album!.isNotEmpty)
                                  Text(
                                    currentSong.album!,
                                    style: const TextStyle(
                                      color: Colors.white30,
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (isListening)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: AnimatedBuilder(
                                      animation: _backgroundIndicatorController,
                                      builder: (context, child) {
                                        final value =
                                            _backgroundIndicatorController.value;
                                        final pulseA = 0.35 +
                                            0.65 *
                                                (0.5 +
                                                    0.5 *
                                                        math.sin(
                                                          (value * 2 * math.pi),
                                                        ));
                                        final pulseB = 0.35 +
                                            0.65 *
                                                (0.5 +
                                                    0.5 *
                                                        math.sin(
                                                          ((value + 0.2) *
                                                              2 *
                                                              math.pi),
                                                        ));
                                        final pulseC = 0.35 +
                                            0.65 *
                                                (0.5 +
                                                    0.5 *
                                                        math.sin(
                                                          ((value + 0.4) *
                                                              2 *
                                                              math.pi),
                                                        ));

                                        return Row(
                                          children: [
                                            _LevelBar(heightFactor: pulseA),
                                            const SizedBox(width: 2),
                                            _LevelBar(heightFactor: pulseB),
                                            const SizedBox(width: 2),
                                            _LevelBar(heightFactor: pulseC),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'PLAYING IN BACKGROUND',
                                              style: TextStyle(
                                                color: Color(0xFF00FFCC),
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white24,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Visualizer canvas ─────────────────────────
            const Expanded(child: VisualizerCanvas()),

            // ── Progress bar ──────────────────────────────
            if (currentSong != null)
              StreamBuilder<int>(
                stream: service.positionMsStream,
                builder: (context, snapshot) {
                  final currentMs = snapshot.data ?? 0;
                  final maxMs = service.maxDurationMs.clamp(1, 999999999);
                  final progress = (currentMs / maxMs).clamp(0.0, 1.0);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 5,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                            activeTrackColor: const Color(0xFFFF2D9B),
                            inactiveTrackColor: Colors.white12,
                            thumbColor: Colors.white,
                            overlayColor: const Color(0xFFFF2D9B)
                                .withValues(alpha: 0.2),
                          ),
                          child: Slider(
                            value: progress,
                            onChanged: (val) async {
                              final seekMs = (val * maxMs).toInt();
                              await service.seekToMs(seekMs);
                            },
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                formatDuration(currentMs),
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                formatDuration(maxMs),
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            // ── Mode switcher ─────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ModeButton(
                    label: 'BARS',
                    icon: Icons.equalizer_rounded,
                    isActive: currentMode == VisualizerMode.bars,
                    onTap: () => _switchMode(VisualizerMode.bars),
                  ),
                  const SizedBox(width: 12),
                  _ModeButton(
                    label: 'RING',
                    icon: Icons.radio_button_unchecked_rounded,
                    isActive: currentMode == VisualizerMode.circular,
                    onTap: () => _switchMode(VisualizerMode.circular),
                  ),
                  const SizedBox(width: 12),
                  _ModeButton(
                    label: 'PARTICLES',
                    icon: Icons.bubble_chart_rounded,
                    isActive: currentMode == VisualizerMode.particles,
                    onTap: () => _switchMode(VisualizerMode.particles),
                  ),
                  const SizedBox(width: 12),
                  _ModeButton(
                    label: 'WAVE',
                    icon: Icons.waves_rounded,
                    isActive: currentMode == VisualizerMode.wave,
                    onTap: () => _switchMode(VisualizerMode.wave),
                  ),
                ],
              ),
            ),

            // ── Play / pause button ───────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TransportButton(
                    icon: Icons.skip_previous_rounded,
                    onTap: service.hasPrevious ? _playPrevious : null,
                    isPrimary: false,
                  ),
                  const SizedBox(width: 18),
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) => Transform.scale(
                        scale: isListening ? _pulseAnimation.value : 1.0,
                        child: child,
                      ),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isListening
                              ? const Color(0xFFFF2D9B)
                              : Colors.white12,
                          border: Border.all(
                            color: isListening
                                ? const Color(0xFFFF2D9B)
                                : Colors.white30,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          isListening
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  _TransportButton(
                    icon: Icons.skip_next_rounded,
                    onTap: service.hasNext ? _playNext : null,
                    isPrimary: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mode button ───────────────────────────────────────────────
class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: isActive
              ? const Color(0xFFFF2D9B).withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border.all(
            color: isActive ? const Color(0xFFFF2D9B) : Colors.white24,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? const Color(0xFFFF2D9B) : Colors.white38,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFFFF2D9B) : Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    ).animate(target: isActive ? 1 : 0)
    .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 200.ms, curve: Curves.easeOutBack)
    .shimmer(duration: 800.ms, color: Colors.white10);
  }
}

class _LevelBar extends StatelessWidget {
  final double heightFactor;

  const _LevelBar({required this.heightFactor});

  @override
  Widget build(BuildContext context) {
    final safeHeightFactor = heightFactor.clamp(0.2, 1.0);
    return Container(
      width: 3,
      height: 10,
      alignment: Alignment.bottomCenter,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.white10,
      ),
      child: FractionallySizedBox(
        heightFactor: safeHeightFactor,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: const Color(0xFF00FFCC),
          ),
        ),
      ),
    );
  }
}

class _TransportButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isPrimary;

  const _TransportButton({
    required this.icon,
    required this.onTap,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: isPrimary ? 64 : 48,
        height: isPrimary ? 64 : 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? Colors.white12 : Colors.white10,
          border: Border.all(
            color: enabled ? Colors.white30 : Colors.white24,
            width: 1.2,
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : Colors.white24,
          size: isPrimary ? 30 : 24,
        ),
      ),
    );
  }
}
