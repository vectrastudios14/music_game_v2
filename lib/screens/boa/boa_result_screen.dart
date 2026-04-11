import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';

import '../../models/song.dart';

class BoaResultScreen extends StatelessWidget {
  final Map<String, List<Song>> timelines;
  final int targetScore;
  final String uiLanguage;

  const BoaResultScreen({
    super.key,
    required this.timelines,
    required this.targetScore,
    this.uiLanguage = 'en',
  });

  String _t(String key) {
    final isAr = uiLanguage == 'ar';
    final Map<String, Map<String, String>> strings = {
      'en': {
        'gameOver': 'GAME OVER',
        'tie': "IT'S A TIE!",
        'finalResults': 'FINAL RESULTS',
        'cards': 'cards',
        'menu': 'MENU',
        'close': 'CLOSE',
      },
      'ar': {
        'gameOver': 'انتهت اللعبة',
        'tie': "تعادل!",
        'finalResults': 'النتائج النهائية',
        'cards': 'بطاقات',
        'menu': 'القائمة',
        'close': 'إغلاق',
      },
    };
    return strings[isAr ? 'ar' : 'en']![key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final isAr = uiLanguage == 'ar';
    final sortedEntries = timelines.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    final maxScore = sortedEntries.isNotEmpty ? sortedEntries.first.value.length : 0;
    final winners = sortedEntries
        .where((e) => e.value.length == maxScore && e.value.length >= targetScore)
        .map((e) => e.key)
        .toSet();

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Image.asset('assets/Before_or_after_logo.png', height: 80),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: isAr ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                      children: [
                        Text(
                          _t('gameOver'),
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                            letterSpacing: isAr ? 0 : 2,
                          ),
                        ),
                        Text(
                          winners.length > 1 ? _t('tie') : _t('finalResults'),
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Timelines List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: sortedEntries.length,
                  itemBuilder: (context, index) {
                    final entry = sortedEntries[index];
                    final name = entry.key;
                    final timeline = entry.value;
                    final isWinner = winners.contains(name);

                    return FadeInLeft(
                      delay: Duration(milliseconds: index * 100),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  name.toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: isWinner ? Theme.of(context).primaryColor : Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "(${timeline.length} ${_t('cards')})",
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (isWinner) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                                ]
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 100,
                              child: Directionality(
                                textDirection: TextDirection.ltr, // Force LTR for the timeline
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: timeline.length,
                                  itemBuilder: (context, cardIndex) {
                                    final song = timeline[cardIndex];
                                    return Container(
                                      width: 70,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: song.artworkUrl != null
                                            ? DecorationImage(
                                                image: NetworkImage(song.artworkUrl!),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                        color: Colors.grey[300],
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.7),
                                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                                          ),
                                          child: Text(
                                            song.year,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Footer Actions
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _ResultActionButton(
                        label: _t('menu'),
                        onPressed: () {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        isOutlined: true,
                        primaryColor: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ResultActionButton(
                        label: _t('close'),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        autofocus: true,
                        primaryColor: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultActionButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isOutlined;
  final Color? primaryColor;
  final bool autofocus;

  const _ResultActionButton({
    required this.label,
    required this.onPressed,
    this.isOutlined = false,
    this.primaryColor,
    this.autofocus = false,
  });

  @override
  State<_ResultActionButton> createState() => _ResultActionButtonState();
}

class _ResultActionButtonState extends State<_ResultActionButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      onKeyEvent: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.select) {
          widget.onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedScale(
        scale: _isFocused ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20), // Matched BOA style
            boxShadow: _isFocused ? [
              BoxShadow(
                color: (widget.primaryColor ?? Colors.blue).withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ] : [],
          ),
          child: widget.isOutlined
              ? OutlinedButton(
                  onPressed: widget.onPressed,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: BorderSide(
                      color: _isFocused ? (widget.primaryColor ?? Colors.blue) : Colors.black12,
                      width: _isFocused ? 3 : 2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(widget.label, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                )
              : ElevatedButton(
                  onPressed: widget.onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    elevation: _isFocused ? 8 : 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(widget.label, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
        ),
      ),
    );
  }
}
