import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/song_repository.dart';
import 'game_hub_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Play Intro Sound
    try {
      await _audioPlayer.play(AssetSource('intro.mp3'), volume: 0.5);
    } catch (e) {
      debugPrint("Intro Sound Error (or missing asset): $e");
    }

    // 2. Load Songs
    final repo = Provider.of<SongRepository>(context, listen: false);
    await repo.loadSongs();

    // 2. Wait minimum time for animation (and to let intro play a bit)
    await Future.delayed(const Duration(seconds: 4));

    // 3. Navigate to Menu
    if (mounted) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => const GameHubScreen())
      );
    }
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeInDown(
              duration: const Duration(seconds: 1),
              child: Text(
                'MUSICA',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(
                      color: Theme.of(context).primaryColor,
                      blurRadius: 30,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            // Visualizer instead of Loader
            const MusicVisualizer(),
            
            const SizedBox(height: 10),
            const SizedBox(height: 10),
            // Removed "Loading library..." text
          ],
        ),
      ),
    );
  }
}

class MusicVisualizer extends StatelessWidget {
  const MusicVisualizer({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) => VisualizerBar(delay: index * 100)),
    );
  }
}

class VisualizerBar extends StatefulWidget {
  final int delay;
  const VisualizerBar({super.key, required this.delay});

  @override
  State<VisualizerBar> createState() => _VisualizerBarState();
}

class _VisualizerBarState extends State<VisualizerBar> {
  Timer? _timer;
  double _height = 10;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Offset start time
    Future.delayed(Duration(milliseconds: widget.delay), () {
        if (mounted) _startAnimating();
    });
  }

  void _startAnimating() {
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (mounted) {
        setState(() {
           _height = 10.0 + _random.nextInt(40).toDouble();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: 8,
      height: _height,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.5), blurRadius: 5)
        ]
      ),
    );
  }
}
