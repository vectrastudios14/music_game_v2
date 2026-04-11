import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'game_hub_screen.dart';
import 'package:audioplayers/audioplayers.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}



class _IntroScreenState extends State<IntroScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer(); // Audio Player
  final int _durationSeconds = 10;

  @override
  void initState() {
    super.initState();
    print("DEBUG: IntroScreen initState called (v2)");
    
    // Setup Animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); 

    // Play Music
    _playIntroMusic();

    // Navigate after 10 seconds
    _timer = Timer(Duration(seconds: _durationSeconds), _navigateToHome);
  }

  Future<void> _playIntroMusic() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.release); // Don't loop short sfx
      await _audioPlayer.play(AssetSource('logo_reveal.mp3'));
      await _audioPlayer.setVolume(1.0); // Full volume for accent
    } catch (e) {
      print("Error playing intro music: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    _audioPlayer.stop(); // Stop music
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _fadeOutMusic() async {
    try {
      // Fade out over 1.5 seconds, 30 steps (50ms each)
      const int steps = 30;
      const double startVolume = 0.5;
      
      for (int i = steps; i >= 0; i--) {
        if (!mounted) break;
        double volume = (i / steps) * startVolume; 
        await _audioPlayer.setVolume(volume);
        await Future.delayed(const Duration(milliseconds: 50));
      }
      await _audioPlayer.stop();
    } catch (e) {
      print("Error fading out music: $e");
    }
  }

  void _navigateToHome() async {
    if (!mounted) return;
    
    _timer?.cancel(); // Cancel timer if called manually
    await _fadeOutMusic(); // Fade out before navigating

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const GameHubScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Matches Game Hub (0xFF0F172A)
      body: GestureDetector(
        onTap: _navigateToHome, // Allow tap to skip
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Animated Background / Visualizer
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: VisualizerPainter(_controller.value),
                  );
                },
              ),
            ),
            
            // Central Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Glowing Text
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(seconds: 2),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value, 
                        child: Transform.scale(
                          scale: 0.8 + (0.2 * value), // Subtle zoom in
                          child: child,
                        ),
                      );
                    },
                    child: const Text(
                      'MUSICA',
                      style: TextStyle(
                        fontFamily: 'Outfit', // Ensure this font is available or use default
                        fontSize: 80,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF00E5FF), // Cyan/Teal neon
                        shadows: [
                          Shadow(
                            color: Color(0xFF00E5FF),
                            blurRadius: 50,
                          ),
                          Shadow(
                            color: Colors.white,
                            blurRadius: 10,
                          ),
                        ],
                        letterSpacing: 8.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TweenAnimationBuilder<double>(
                     tween: Tween(begin: 0.0, end: 1.0),
                     duration: const Duration(milliseconds: 1500),
                     curve: Curves.easeOut,
                     builder: (context, value, child) {
                       return Opacity(
                         opacity: value,
                         child: Transform.translate(
                           offset: Offset(0, 20 * (1 - value)),
                           child: child,
                         ),
                       );
                     },
                     child: Text(
                      'FEEL THE RHYTHM',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 18,
                        letterSpacing: 4.0,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Skip Text at bottom
             Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(seconds: 2),
                  builder: (context, value, child) {
                     return Opacity(
                       opacity: value > 0.5 ? 1.0 : 0.0, // Fade in late
                       child: child,
                     );
                  },
                  child: Text(
                    'Tap to Skip',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VisualizerPainter extends CustomPainter {
  final double animationValue;

  VisualizerPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final maxRadius = min(size.width, size.height) * 0.8;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw concentric pulsing circles/waves
    for (int i = 0; i < 5; i++) {
      double offset = (animationValue + (i * 0.2)) % 1.0;
      double radius = maxRadius * offset; 
      double opacity = 1.0 - offset; // Fade out as it expands

      paint.color = const Color(0xFF6200EE).withOpacity(opacity * 0.5); // Purple
      paint.strokeWidth = 2 + (5 * offset);

      canvas.drawCircle(Offset(centerX, centerY), radius, paint);
    }

    // Draw some dynamic lines/particles
    final Paint particlePaint = Paint()..color = const Color(0xFF03DAC6); // Teal
    
    // We want the particles to move outwards
    for (int i = 0; i < 20; i++) {
      double angle = (2 * pi / 20) * i + (animationValue * pi); // Rotate
      double distance = (maxRadius * 0.5) + (50 * sin(animationValue * 2 * pi + i));
      
      double x = centerX + distance * cos(angle);
      double y = centerY + distance * sin(angle);
      
      particlePaint.color = const Color(0xFF03DAC6).withOpacity(0.6 + 0.4 * sin(animationValue * 2 * pi));
      canvas.drawCircle(Offset(x, y), 3, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant VisualizerPainter oldDelegate) {
     return true; // Always repaint for animation
  }
}
