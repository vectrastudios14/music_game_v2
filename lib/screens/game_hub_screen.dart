import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

import 'gts/setup_screen.dart';
import 'boa/boa_setup_screen.dart';
import 'time_survival/ts_setup_screen.dart';

import '../services/background_music_service.dart';

class GameHubScreen extends StatefulWidget {
  const GameHubScreen({super.key});

  @override
  State<GameHubScreen> createState() => _GameHubScreenState();
}

class _GameHubScreenState extends State<GameHubScreen> with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _breatheController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Start background music
    BackgroundMusicService.instance.playMenuMusic();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Dynamic Visualizer Background
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: AnimatedBuilder(
                animation: _bgController,
                builder: (context, child) {
                  return CustomPaint(painter: _VisualizerPainter(_bgController.value));
                },
              ),
            ),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeInDown(
                  child: Image.asset(
                    'assets/Musica_logo.png',
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 10),
                FadeInDown(
                  child: Text(
                    'Choose Your Game',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
                const SizedBox(height: 40),
                
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: AnimatedBuilder(
                    animation: _breatheController,
                    builder: (context, child) {
                      final scale = 1.0 + (_breatheController.value * 0.02);
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Guess That Song Game
                        FadeInUp(
                          delay: const Duration(milliseconds: 200),
                          child: _GameModeCard(
                            title: 'Guess That Song',
                            imagePath: 'assets/Guess_that_song_logo.png',
                            backgroundColor: const Color(0xFF1E1E2C),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const GtsSetupScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        
                        const SizedBox(width: 30),
      
                        // Before or After Game
                        FadeInUp(
                          delay: const Duration(milliseconds: 400),
                          child: _GameModeCard(
                            title: 'Before or After?',
                            imagePath: 'assets/Before_or_after_logo.png',
                            backgroundColor: const Color(0xFF1E1E2C),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const BoaSetupScreen(),
                                ),
                              );
                            },
                          ),
                        ),
      
                        const SizedBox(width: 30),
      
                        // Time Survival Game
                        FadeInUp(
                           delay: const Duration(milliseconds: 600),
                           child: _GameModeCard(
                              title: 'Time Survival',
                              imagePath: 'assets/TimeSurvival_logo.png',
                              backgroundColor: const Color(0xFF1E1E2C),
                              onTap: () {
                                 Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                       builder: (context) => const TsSetupScreen(),
                                    )
                                 );
                              },
                           ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameModeCard extends StatefulWidget {
  final String title;
  final String? imagePath;
  final IconData? icon;
  final Color? backgroundColor;
  final VoidCallback onTap;

  const _GameModeCard({
    required this.title,
    this.imagePath,
    this.icon,
    this.backgroundColor,
    required this.onTap,
  }) : assert(imagePath != null || icon != null);

  @override
  State<_GameModeCard> createState() => _GameModeCardState();
}

class _GameModeCardState extends State<_GameModeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 350,
          height: 250,
          transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered 
                  ? Theme.of(context).primaryColor 
                  : Colors.white.withOpacity(0.1),
              width: _isHovered ? 3 : 2,
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.4),
                  blurRadius: 25,
                  spreadRadius: 2,
                  offset: const Offset(0, 5),
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(0.0),
                  child: widget.imagePath != null 
                    ? Image.asset(
                        widget.imagePath!,
                        fit: BoxFit.contain,
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           Icon(widget.icon, size: 80, color: Colors.white),
                           const SizedBox(height: 10),
                           Text(
                              widget.title,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                 color: Colors.white,
                                 fontWeight: FontWeight.bold
                              )
                           )
                        ],
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _VisualizerPainter extends CustomPainter {
  final double animationValue;
  _VisualizerPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final maxRadius = (size.width > size.height ? size.width : size.height) * 0.8;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 5; i++) {
      double offset = (animationValue + (i * 0.2)) % 1.0;
      double radius = maxRadius * offset; 
      double opacity = (1.0 - offset).clamp(0.0, 1.0);

      paint.color = const Color(0xFF6C63FF).withOpacity(opacity * 0.4); 
      paint.strokeWidth = 2 + (10 * offset);
      canvas.drawCircle(Offset(centerX, centerY), radius, paint);
    }

    final Paint particlePaint = Paint()..color = const Color(0xFF00E676);
    for (int i = 0; i < 15; i++) {
      double angle = (2 * 3.14159 / 15) * i + (animationValue * 2 * 3.14159);
      double distance = (maxRadius * 0.3) + (30 * (i % 3));
      double x = centerX + distance * (animationValue * 0.5 + 0.5) * (i.isEven ? 1 : -1);
      double y = centerY + distance * (animationValue * 0.5 + 0.5) * (i.isOdd ? 1 : -1);
      
      canvas.drawCircle(Offset(x % size.width, y % size.height), 2, particlePaint..color = particlePaint.color.withOpacity(0.3));
    }
  }

  @override
  bool shouldRepaint(covariant _VisualizerPainter oldDelegate) => true;
}
