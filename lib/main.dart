import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart'; // IMPORT
import 'firebase_options.dart'; // IMPORT
import 'theme/app_theme.dart';
import 'services/song_repository.dart';
import 'screens/splash_screen.dart';
import 'screens/mobile_controller/controller_setup_screen.dart'; // IMPORT
import 'utils/custom_scroll_behavior.dart';
import 'package:flutter/foundation.dart'; // IMPORT kIsWeb
import 'dart:async';
import 'package:flutter/services.dart'; // IMPORT for keyboard shortcuts

import 'package:window_manager/window_manager.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    if (!kIsWeb) {
      // Initialize Window Manager ONLY on Desktop
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
        await windowManager.setTitle('Musica');
        
        // Add a slight delay before triggering fullscreen to prevent native initialization crashes
        await Future.delayed(const Duration(milliseconds: 150));
        await windowManager.setFullScreen(true);
      });
    }

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
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.f11): const ToggleFullscreenIntent(),
        },
        actions: {
          ToggleFullscreenIntent: CallbackAction<ToggleFullscreenIntent>(
            onInvoke: (intent) async {
              if (!kIsWeb) {
                final isFull = await windowManager.isFullScreen();
                await windowManager.setFullScreen(!isFull);
              }
              return null;
            },
          ),
        },
        initialRoute: kIsWeb ? null : '/',
        onGenerateRoute: (settings) {
          if (settings.name != null && settings.name!.startsWith('/controller')) {
            final uri = Uri.parse(settings.name!);
            final roomCode = uri.queryParameters['room'] ?? '';
            return MaterialPageRoute(
              builder: (context) => ControllerSetupScreen(roomCode: roomCode),
            );
          }
          
          // If on web and no valid route, show a blank/error screen instead of the Windows game
          if (kIsWeb) {
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
                backgroundColor: Colors.black,
                body: Center(child: Text('Invalid Room Link', style: TextStyle(color: Colors.white))),
              ),
            );
          }

          return MaterialPageRoute(builder: (context) => const SplashScreen());
        },
      ),
    );
  }
}

class ToggleFullscreenIntent extends Intent {
  const ToggleFullscreenIntent();
}
