import 'dart:math';
import 'package:flutter/material.dart';

class LiquidTube extends StatefulWidget {
  final double score; 
  final double startScore; 
  final double maxScore;
  final Color color;
  final double height;
  final double width;
  final bool isBroken; // New
  final bool isWinner; // New
  final bool isHorizontal; // New

  const LiquidTube({
    super.key,
    required this.score,
    required this.maxScore,
    required this.color,
    this.startScore = -1, 
    this.height = 200,
    this.width = 60,
    this.isBroken = false,
    this.isWinner = false,
    this.isHorizontal = false,
  });

  @override
  State<LiquidTube> createState() => _LiquidTubeState();
}

class _LiquidTubeState extends State<LiquidTube> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late double _wavePhaseOffset;
  late double _waveSpeedMultiplier;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _wavePhaseOffset = _random.nextDouble() * 2 * pi;
    _waveSpeedMultiplier = 0.8 + _random.nextDouble() * 0.4; 

    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 2000)
    )..repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double safeScore = widget.score < 0 ? 0 : widget.score;
    double safeStart = widget.startScore < 0 ? 0 : widget.startScore;
    if (widget.startScore == -1) safeStart = safeScore;

    double finalFill = (safeScore / widget.maxScore).clamp(0.0, 1.0);
    double startFill = (safeStart / widget.maxScore).clamp(0.0, 1.0);

    if (finalFill < 0.05 && safeScore > 0) finalFill = 0.05;
    if (startFill < 0.05 && (safeStart > 0 || safeScore > 0)) startFill = 0.05;

    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: Stack(
        alignment: widget.isHorizontal ? Alignment.centerLeft : Alignment.bottomCenter,
        children: [
          // Background 
          Container(
            decoration: BoxDecoration(
              color: widget.isHorizontal ? Colors.black38 : null,
              gradient: widget.isHorizontal ? null : LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ]
              ),
              borderRadius: BorderRadius.circular(
                widget.isHorizontal ? 8 : widget.width / 2
              ),
              border: Border.all(
                color: widget.isWinner ? Colors.amberAccent : (widget.isHorizontal ? Colors.white10 : Colors.white24), 
                width: widget.isWinner ? 2.5 : 1.5
              ),
              boxShadow: widget.isWinner 
                ? [BoxShadow(color: Colors.amberAccent.withOpacity(0.4), blurRadius: widget.isHorizontal ? 10 : 20, spreadRadius: 2)] 
                : null
            ),
            child: widget.isHorizontal ? null : CustomPaint(
              painter: _TubeMarkingsPainter(isHorizontal: false),
              size: Size(widget.width, widget.height),
            ),
          ),
          
          // Content
          ClipRRect(
            borderRadius: BorderRadius.circular(
              widget.isHorizontal ? 6 : widget.width / 2
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: startFill, end: finalFill),
              duration: const Duration(milliseconds: 3000), 
              curve: Curves.easeInOutQuart,
              builder: (context, fillValue, child) {
                 return AnimatedBuilder(
                   animation: _controller,
                   builder: (context, _) {
                     if (widget.isHorizontal) {
                       return CustomPaint(
                         painter: _NeonEnergyPainter(
                           color: widget.color,
                           fillPercentage: fillValue,
                           animationValue: _controller.value,
                           isWinner: widget.isWinner,
                           isDead: widget.isBroken,
                         ),
                         size: Size(widget.width, widget.height),
                       );
                     }
                     return CustomPaint(
                       painter: _RealisticLiquidPainter(
                         color: widget.color,
                         fillPercentage: fillValue,
                         animationValue: _controller.value,
                         phaseOffset: _wavePhaseOffset,
                         isHorizontal: false,
                       ),
                       size: Size(widget.width, widget.height),
                     );
                   },
                 );
              },
            ),
          ),
          
          // CRACKS OVERLAY (Only for vertical tubes)
          if (widget.isBroken && !widget.isHorizontal)
            IgnorePointer(
               child: CustomPaint(
                 painter: _CrackedGlassPainter(isHorizontal: false),
                 size: Size(widget.width, widget.height),
               ),
            ),

          // High-Gloss Reflection (Only for vertical tubes)
          if (!widget.isHorizontal)
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.width / 2),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.white.withOpacity(0.1),
                    ],
                    stops: const [0.0, 0.2, 0.8, 1.0],
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NeonEnergyPainter extends CustomPainter {
  final Color color;
  final double fillPercentage;
  final double animationValue;
  final bool isWinner;
  final bool isDead;

  _NeonEnergyPainter({
    required this.color,
    required this.fillPercentage,
    required this.animationValue,
    this.isWinner = false,
    this.isDead = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fillPercentage <= 0) return;

    final double barWidth = size.width * fillPercentage;
    final baseColor = isDead ? Colors.redAccent : color;
    
    // 1. Shadow/Glow under the energy
    final glowPaint = Paint()
      ..color = baseColor.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRect(Rect.fromLTWH(0, 0, barWidth, size.height), glowPaint);

    // 2. Main Energy Bar
    final mainPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          baseColor.withOpacity(0.6),
          baseColor,
          baseColor.withOpacity(0.8),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, barWidth, size.height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, barWidth, size.height), mainPaint);

    // 3. Technical Grid/Lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1.0;

    const int lineCount = 10;
    for (int i = 1; i < lineCount; i++) {
      double x = (size.width / lineCount) * i;
      if (x < barWidth) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
      }
    }

    // 4. Moving Pulse Effect
    final double pulseX = (animationValue * size.width * 1.5) - (size.width * 0.25);
    if (pulseX > -50 && pulseX < barWidth + 50) {
      final pulsePaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.4),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(pulseX.clamp(0.0, barWidth), 0, 40, size.height));
      
      canvas.drawRect(
        Rect.fromLTWH(
          max(0, pulseX), 
          0, 
          min(40, barWidth - max(0, pulseX)), 
          size.height
        ), 
        pulsePaint
      );
    }

    // 5. Bright Edge (Cap)
    final edgePaint = Paint()
      ..color = isWinner ? Colors.amberAccent : Colors.white70
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawRect(Rect.fromLTWH(barWidth - 2, 0, 2, size.height), edgePaint);
  }

  @override
  bool shouldRepaint(covariant _NeonEnergyPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || 
           oldDelegate.fillPercentage != fillPercentage;
  }
}

class _RealisticLiquidPainter extends CustomPainter {
  final Color color;
  final double fillPercentage;
  final double animationValue;
  final double phaseOffset;
  final bool isHorizontal;

  _RealisticLiquidPainter({
    required this.color,
    required this.fillPercentage,
    required this.animationValue,
    required this.phaseOffset,
    this.isHorizontal = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fillPercentage <= 0) return;

    // 1. Back Wave (Darker/Slower)
    _drawWave(
       canvas, size, 
       opacity: 0.6, 
       waveHeight: 4.0, 
       speedMult: 0.8, 
       offset: phaseOffset + pi
    );

    // 2. Front Wave (Bright)
    _drawWave(
       canvas, size, 
       opacity: 0.9, 
       waveHeight: 6.0, 
       speedMult: 1.0, 
       offset: phaseOffset
    );
    
    _drawSurfaceHighlight(canvas, size);
  }
  
  void _drawWave(Canvas canvas, Size size, {
    required double opacity, 
    required double waveHeight, 
    required double speedMult, 
    required double offset
  }) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    final path = Path();
    
    final double frequency = 2 * pi;
    final double move = (animationValue * speedMult * 2 * pi) + offset;
    
    if (isHorizontal) {
      final double baseWidth = size.width * fillPercentage;
      path.moveTo(0, 0);
      path.lineTo(baseWidth, 0);
      
      for (double y = 0; y <= size.height; y++) {
        double x = baseWidth + sin((y / size.height * frequency) + move) * waveHeight;
        path.lineTo(x, y);
      }
      
      path.lineTo(0, size.height);
      path.close();
    } else {
      final double baseHeight = size.height * (1 - fillPercentage);
      path.moveTo(0, size.height);
      path.lineTo(0, baseHeight);
      
      for (double x = 0; x <= size.width; x++) {
        double y = baseHeight + sin((x / size.width * frequency) + move) * waveHeight;
        path.lineTo(x, y);
      }
      
      path.lineTo(size.width, size.height);
      path.close();
    }

    canvas.drawPath(path, paint);
  }
  
  void _drawSurfaceHighlight(Canvas canvas, Size size) {
     final paint = Paint()
       ..color = Colors.white.withOpacity(0.3)
       ..style = PaintingStyle.stroke
       ..strokeWidth = 2;
       
    final path = Path();
    final double waveHeight = 6.0; 
    final double frequency = 2 * pi;
    final double move = (animationValue * 2 * pi) + phaseOffset;
    
    if (isHorizontal) {
      final double baseWidth = size.width * fillPercentage;
      for (double y = 0; y <= size.height; y++) {
        double x = baseWidth + sin((y / size.height * frequency) + move) * waveHeight;
        if (y == 0) path.moveTo(x, y);
        else path.lineTo(x, y);
      }
    } else {
      final double baseHeight = size.height * (1 - fillPercentage);
      for (double x = 0; x <= size.width; x++) {
        double y = baseHeight + sin((x / size.width * frequency) + move) * waveHeight;
        if (x == 0) path.moveTo(x, y);
        else path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RealisticLiquidPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || 
           oldDelegate.fillPercentage != fillPercentage ||
           oldDelegate.isHorizontal != isHorizontal;
  }
}

class _TubeMarkingsPainter extends CustomPainter {
  final bool isHorizontal;
  _TubeMarkingsPainter({this.isHorizontal = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final markers = [0.25, 0.5, 0.75];
    
    if (isHorizontal) {
      final double centerY = size.height / 2;
      for (double relativeX in markers) {
        double x = size.width * relativeX;
        canvas.drawLine(Offset(x, centerY - 8), Offset(x, centerY + 8), paint);
      }
    } else {
      final double centerX = size.width / 2;
      for (double relativeHeight in markers) {
        double y = size.height * (1 - relativeHeight);
        canvas.drawLine(Offset(centerX - 8, y), Offset(centerX + 8, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CrackedGlassPainter extends CustomPainter {
  final bool isHorizontal;
  _CrackedGlassPainter({this.isHorizontal = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    
    // Crack 1: 
    path.moveTo(size.width * 0.1, size.height * 0.9);
    path.lineTo(size.width * 0.3, size.height * 0.8);
    path.lineTo(size.width * 0.2, size.height * 0.7);
    
    // Crack 2: 
    path.moveTo(size.width * 0.9, size.height * 0.5);
    path.lineTo(size.width * 0.7, size.height * 0.55);
    path.lineTo(size.width * 0.6, size.height * 0.45);
    path.lineTo(size.width * 0.8, size.height * 0.4);

    // Crack 3: 
    path.moveTo(size.width * 0.5, size.height * 0.2);
    path.lineTo(size.width * 0.45, size.height * 0.35);
    path.lineTo(size.width * 0.55, size.height * 0.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
