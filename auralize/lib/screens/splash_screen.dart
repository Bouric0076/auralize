import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to Home after animation
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background pulsing rings
            ...List.generate(3, (index) {
              return Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00FFCC).withValues(alpha: 0.1),
                    width: 2,
                  ),
                ),
              )
              .animate(
                onPlay: (controller) => controller.repeat(),
              )
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(2.0, 2.0),
                duration: 2000.ms,
                delay: (index * 600).ms,
                curve: Curves.easeOut,
              )
              .fadeOut(
                begin: 0.5,
                duration: 2000.ms,
                delay: (index * 600).ms,
                curve: Curves.easeOut,
              );
            }),

            // "AURALIZE" Text
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AURALIZE',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                )
                .animate()
                .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                .slideY(begin: 0.3, end: 0, duration: 800.ms, curve: Curves.easeOutQuad)
                .then(delay: 200.ms)
                .shimmer(duration: 1500.ms, color: const Color(0xFF00FFCC))
                .then(delay: 400.ms)
                .blur(begin: const Offset(0, 0), end: const Offset(10, 10), duration: 600.ms) // Fade out blur
                .fadeOut(duration: 600.ms),

                const SizedBox(height: 16),

                // Subtitle
                Text(
                  'WHERE SOUND MEETS SIGHT',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white54,
                    fontSize: 12,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w300,
                  ),
                )
                .animate()
                .fadeIn(delay: 600.ms, duration: 800.ms)
                .slideY(begin: 0.5, end: 0, delay: 600.ms, duration: 800.ms)
                .then(delay: 1800.ms)
                .fadeOut(duration: 600.ms),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
