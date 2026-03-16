import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize background audio BEFORE runApp
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.bouric0076.auralize.playback',
      androidNotificationChannelName: 'Auralize Playback',
      androidNotificationOngoing: true,
    );
  } catch (e) {
    debugPrint('Background audio init failed: $e');
  }

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  // Full immersive black screen - hides status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
    ),
  );
  runApp(const ProviderScope(child: AuralizeApp()));
}
