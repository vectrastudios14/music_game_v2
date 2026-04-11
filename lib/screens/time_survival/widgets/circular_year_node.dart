import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CircularYearNode extends StatelessWidget {
  final int year;
  final List<Color> playerColors;
  final Color baseColor;
  final double size;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback? onTap;
  
  const CircularYearNode({
    super.key,
    required this.year,
    required this.playerColors,
    required this.baseColor,
    this.size = 60.0,
    this.isCorrect = false,
    this.isWrong = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
       onLongPress: () {
        _showMagnifiedView(context);
      },
      child: CustomPaint(
        size: Size(size, size),
        painter: ConcentricRingPainter(
          playerColors: playerColors,
          baseColor: baseColor,
          isCorrect: isCorrect,
          isWrong: isWrong,
        ),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          child: Text(
            "$year",
            style: GoogleFonts.outfit(
              fontSize: size * 0.35, // Dynamic text size
              fontWeight: FontWeight.bold,
              color: isCorrect ? Colors.black : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  void _showMagnifiedView(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    
    entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => entry.remove(),
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black54),
            ),
          ),
          Center(
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle, // Important: Background matches
                      boxShadow: [
                        BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 30, spreadRadius: 5)
                      ]
                    ),
                    child: CircularYearNode(
                      year: year, 
                      playerColors: playerColors, 
                      baseColor: baseColor,
                      size: 200,
                      isCorrect: isCorrect,
                      isWrong: isWrong,
                      onTap: () => entry.remove(), // Tap to close
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text("Tap to Close", style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(entry);
  }
}

class ConcentricRingPainter extends CustomPainter {
  final List<Color> playerColors;
  final Color baseColor;
  final bool isCorrect;
  final bool isWrong;

  ConcentricRingPainter({
    required this.playerColors,
    required this.baseColor,
    required this.isCorrect,
    required this.isWrong,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    
    // 1. Draw Base Circle
    final basePaint = Paint()
      ..color = isCorrect 
          ? const Color(0xFF00E676) // Bright Green
          : isWrong 
             ? const Color(0xFFFF1744) // Red
             : baseColor.withOpacity(0.2);
    
    canvas.drawCircle(center, maxRadius, basePaint);

    if (isCorrect || isWrong) {
      // Glow effect?
       canvas.drawCircle(center, maxRadius, Paint()..color = basePaint.color.withOpacity(0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    }
    
    // 2. Draw Concentric Rings
    if (playerColors.isNotEmpty) {
      // Logic: 
      // Divide available annular space among players?
      // Inner radius for year text: approx 40% of maxRadius.
      // Available thickness = maxRadius - innerRadius.
      // Thickness per player = Available / count.
      
      final innerRadius = maxRadius * 0.5; // Space for text
      final availableSpace = maxRadius - innerRadius;
      final ringThickness = availableSpace / playerColors.length;

      for (int i = 0; i < playerColors.length; i++) {
        final color = playerColors[i];
        final radius = innerRadius + (i * ringThickness) + (ringThickness / 2);
        
        final ringPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = (ringThickness - 1.0).clamp(0.5, 50.0); // Ensure min width
        
        canvas.drawCircle(center, radius, ringPaint);
      }
    }
    
    // 3. Border (Optional)
    final borderPaint = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, maxRadius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant ConcentricRingPainter oldDelegate) {
    return oldDelegate.playerColors != playerColors || 
           oldDelegate.isCorrect != isCorrect ||
           oldDelegate.isWrong != isWrong;
  }
}
