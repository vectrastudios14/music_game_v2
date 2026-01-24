import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart'; // Ensure package is available
import 'theme/app_theme.dart';
import 'services/song_repository.dart';
import 'screens/splash_screen.dart';
import 'dart:async';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
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
        title: 'Musica V2',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
