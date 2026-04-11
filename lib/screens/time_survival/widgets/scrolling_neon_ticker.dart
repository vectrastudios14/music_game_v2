import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScrollingNeonTicker extends StatefulWidget {
  final String title;
  final String artist;
  final double width;

  const ScrollingNeonTicker({
    super.key,
    required this.title,
    required this.artist,
    required this.width,
  });

  @override
  State<ScrollingNeonTicker> createState() => _ScrollingNeonTickerState();
}

class _ScrollingNeonTickerState extends State<ScrollingNeonTicker> {
  late ScrollController _scrollController;
  late Timer _timer;
  bool _scrollDirection = true; // true = forward

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Wait for build to finish then start scrolling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  void _startScrolling() {
    if (!mounted) return;
    
    // Calculate duration based on text length roughly, or fixed speed
    // But since content is dynamic, we'll strive for a constant speed
    // Speed = pixels / second. Let's say 30 pixels per second.
    // However, exact width isn't easily known without layout.
    // Simplifying: Animate to maxExtent then jump back or reverse.
    // "Street Board" usually loops:  TEXT  TEXT  TEXT
    
    // For a simple looping marquee without complex width calculations:
    // We can just animate continually.
    
    const double speed = 30.0; // pixels per second
    const double dt = 0.05; // 50ms steps
    
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      if (!_scrollController.hasClients) return;

      double maxScroll = _scrollController.position.maxScrollExtent;
      double currentScroll = _scrollController.position.pixels;
      
      // Infinite scroll logic:
      // If we are at the end, jump to start? 
      // Or if we use ListView.builder with infinite items?
      // Let's use the animateTo approach.
      
      double delta = speed * dt;
      double nextScroll = currentScroll + delta;
      
      if (nextScroll >= maxScroll) {
         // Reset seamlessly if possible, but standard ListView requires jump
         // To make it seamless, we render the text multiple times.
         _scrollController.jumpTo(0);
      } else {
         _scrollController.jumpTo(nextScroll);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Street Board Look
    return Container(
      width: widget.width,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.cyanAccent.withOpacity(0.8),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.pinkAccent.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: -2,
            offset: const Offset(2, 2)
          )
        ]
      ),
      child: ClipRect(
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(), // Controlled by timer
          itemBuilder: (context, index) {
            // Infinite repeated items
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center( // Vertically center
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       Text(
                         widget.title.toUpperCase(),
                         style: GoogleFonts.vt323(
                           color: Colors.cyanAccent,
                           fontSize: 20,
                           fontWeight: FontWeight.bold,
                           shadows: [
                             const Shadow(color: Colors.blue, blurRadius: 4),
                           ]
                         ),
                       ),
                       const SizedBox(width: 8),
                       Text(
                         "//", // Separator
                         style: GoogleFonts.vt323(
                           color: Colors.pinkAccent,
                           fontSize: 14,
                         ),
                       ),
                       const SizedBox(width: 8),
                       Text(
                         widget.artist.toUpperCase(),
                         style: GoogleFonts.vt323(
                           color: Colors.white,
                           fontSize: 16,
                         ),
                       ),
                       const SizedBox(width: 20),
                       // Dot separator
                       Container(
                         width: 6, height: 6,
                         decoration: const BoxDecoration(
                           color: Colors.pinkAccent,
                           shape: BoxShape.circle,
                           boxShadow: [BoxShadow(color: Colors.pink, blurRadius: 5)]
                         ),
                       )
                    ],
                  ),
              ),
            );
          },
        ),
      ),
    );
  }
}
