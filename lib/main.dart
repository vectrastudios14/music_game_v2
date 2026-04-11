import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart'; // Ensure package is available
import 'theme/app_theme.dart';
import 'services/song_repository.dart';
import 'screens/splash_screen.dart';
import 'utils/custom_scroll_behavior.dart'; // IMPORT
import 'dart:async';

import 'package:window_manager/window_manager.dart'; // IMPORT

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Window Manager
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setMinimumSize(const Size(1024, 768));
      await windowManager.setTitle('Musica');
    });

    // AudioPlayers doesn't need explicit init on Windows usually, 
    // but we can keep main clean.

    runApp(const MusicaApp());
  }, (error, stack) {
    debugPrint("CRITICAL APP CRASH: $error\n$stack");
  });
}

class MusicaApp extends StatelessWidget {
  const MusicaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SongRepository>(
          create: (_) => SongRepository(),
        ),
      ],
      child: MaterialApp(
        title: 'Musica',
        debugShowCheckedModeBanner: false,
        scrollBehavior: CustomScrollBehavior(), // ENABLE MOUSE DRAG
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
