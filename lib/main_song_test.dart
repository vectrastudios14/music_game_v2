import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/song_test_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 800),
    center: true,
    backgroundColor: Color(0xFF1E1E2C),
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const SongTestApp());
}

class SongTestApp extends StatelessWidget {
  const SongTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Song Verify Tool',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E2C),
        colorScheme: const ColorScheme.dark(primary: Colors.blueAccent),
      ),
      home: const SongTestScreen(),
    );
  }
}
