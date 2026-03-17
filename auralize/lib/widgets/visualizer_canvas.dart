import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../audio/audio_service.dart';
import '../audio/audio_state.dart';
import '../visualizers/bar_visualizer.dart';
import '../visualizers/circular_visualizer.dart';
import '../visualizers/particle_visualizer.dart';
import '../visualizers/wave_visualizer.dart'; // New import

enum VisualizerMode { bars, circular, particles, wave } // Added wave

final visualizerModeProvider = StateProvider<VisualizerMode>(
  (ref) => VisualizerMode.wave, // Default to wave for testing
);

class VisualizerCanvas extends ConsumerStatefulWidget {
  const VisualizerCanvas({super.key});

  @override
  ConsumerState<VisualizerCanvas> createState() => _VisualizerCanvasState();
}

class _VisualizerCanvasState extends ConsumerState<VisualizerCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _controller.addListener(() {
      final AudioService service = ref.read(audioServiceProvider);
      service.updateFFT();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AudioService service = ref.watch(audioServiceProvider);
    final VisualizerMode mode = ref.watch(visualizerModeProvider);
    final bool isListening = ref.watch(isListeningProvider).value ?? false;

    bool needsAnimation = isListening;
    if (!isListening) {
      // Keep animating briefly to allow FFT bars to decay smoothly and particles to disappear
      if (mode == VisualizerMode.particles && _particles.isNotEmpty) {
        needsAnimation = true;
      } else {
        for (final val in service.smoothedFFT) {
          if (val > 0.01) {
            needsAnimation = true;
            break;
          }
        }
      }
    }

    if (needsAnimation && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!needsAnimation && _controller.isAnimating) {
      _controller.stop();
    }

    if (service.currentSong == null) {
      return const Center(
        child: Text(
          'Pick a track and tap play to start',
          style: TextStyle(
            color: Color(0x66FFFFFF),
            fontSize: 16,
            letterSpacing: 1.5,
          ),
        ),
      );
    }

    CustomPainter painter;
    switch (mode) {
      case VisualizerMode.bars:
        painter = BarVisualizer(fftData: service.smoothedFFT);
        break;
      case VisualizerMode.circular:
        painter = CircularVisualizer(fftData: service.smoothedFFT);
        break;
      case VisualizerMode.particles:
        painter = ParticleVisualizer(
          fftData: service.smoothedFFT,
          particles: _particles,
          beatDetected: service.detectBeat(),
        );
        break;
      case VisualizerMode.wave:
        painter = WaveVisualizer(fftData: service.smoothedFFT);
        break;
    }

    return CustomPaint(
      painter: painter,
      child: const SizedBox.expand(),
    );
  }
}
