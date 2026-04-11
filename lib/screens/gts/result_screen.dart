import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class GtsResultScreen extends StatelessWidget {
  final Map<String, int> scores;
  final int totalRounds;
  final bool isLightMode;

  const GtsResultScreen({
    super.key,
    required this.scores,
    required this.totalRounds,
    this.isLightMode = false,
  });

  @override
  Widget build(BuildContext context) {
    // Sort scores descending
    final sortedEntries = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final winner = sortedEntries.isNotEmpty ? sortedEntries.first : null;
    final isTie = sortedEntries.length > 1 && sortedEntries[0].value == sortedEntries[1].value;

    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final secondaryColor = theme.colorScheme.secondary;

    return Scaffold(
      // Background taken from AppTheme (automatically applied by Scaffold, but explicit here for clarity)
      backgroundColor: isLightMode ? Colors.white : theme.scaffoldBackgroundColor, 
      body: SafeArea(


        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // LEFT: LEADERBOARD LIST
              Expanded(
                flex: 4, // 40% width
                child: Container(
                  decoration: BoxDecoration(
                    color: isLightMode ? Colors.grey[100] : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isLightMode ? Colors.black12 : Colors.white10,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: sortedEntries.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1, 
                        color: isLightMode ? Colors.black12 : Colors.white12
                      ),
                      itemBuilder: (context, index) {
                        final entry = sortedEntries[index];
                        final rank = index + 1;
                        final isTop = rank == 1;
            
                        return Container(
                          color: isTop ? primaryColor.withOpacity(0.1) : null,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            children: [
                              // Rank
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: _getRankColor(rank, primaryColor),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                  child: Text(
                                    '#$rank',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.black, 
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Name
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isLightMode ? Colors.black : Colors.white,
                                    ),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Score
                                Text(
                                  '${entry.value}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isTop ? primaryColor : (isLightMode ? Colors.black54 : Colors.white70),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ),

              const SizedBox(width: 40),

              // RIGHT: TROPHY, WINNER, ACTIONS
              Expanded(
                flex: 6, // 60% width
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                      const Spacer(),
                      // Trophy Icon
                      Lottie.asset(
                        'assets/animations/Trophy.json', 
                        height: 250,
                        repeat: true,
                      ),
                      const SizedBox(height: 20),
                      
                      Text("WINNER", style: GoogleFonts.outfit(letterSpacing: 2, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),

                      // Animated Winner Name
                      TypewriterAnimatedText(
                        text: winner?.key ?? 'No One',
                        style: GoogleFonts.indieFlower( // Handwritten font
                          fontSize: 80, 
                          fontWeight: FontWeight.bold,
                          color: isLightMode ? Colors.black : Colors.white,
                          height: 1.0,
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ResultActionButton(
                            label: 'MENU',
                            width: 140,
                            isOutlined: true,
                            isLightMode: isLightMode,
                            onPressed: () {
                              Navigator.popUntil(context, (route) => route.isFirst);
                            },
                          ),
                          const SizedBox(width: 20),
                          _ResultActionButton(
                            label: 'PLAY AGAIN',
                            width: 200,
                            isOutlined: false,
                            isLightMode: isLightMode,
                            primaryColor: primaryColor,
                            autofocus: true,
                            onPressed: () {
                              Navigator.pop(context); 
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRankColor(int rank, Color primary) {
    if (rank == 1) return primary;
    if (rank == 2) return Colors.grey[400]!;
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    return Colors.white24;
  }
}

class _ResultActionButton extends StatefulWidget {
  final String label;
  final double width;
  final VoidCallback onPressed;
  final bool isOutlined;
  final bool isLightMode;
  final Color? primaryColor;
  final bool autofocus;

  const _ResultActionButton({
    required this.label,
    required this.width,
    required this.onPressed,
    this.isOutlined = false,
    this.isLightMode = false,
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
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
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
                    foregroundColor: widget.isLightMode ? Colors.black : Colors.white,
                    side: BorderSide(
                      color: _isFocused 
                        ? (widget.primaryColor ?? Colors.blue) 
                        : (widget.isLightMode ? Colors.black12 : Colors.white24),
                      width: _isFocused ? 2 : 1,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(widget.label),
                )
              : ElevatedButton(
                  onPressed: widget.onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    elevation: _isFocused ? 8 : 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(widget.label),
                ),
        ),
      ),
    );
  }
}

class TypewriterAnimatedText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration? duration; // Optional, if null calculates based on length

  const TypewriterAnimatedText({
    super.key, 
    required this.text, 
    required this.style, 
    this.duration,
  });

  @override
  State<TypewriterAnimatedText> createState() => _TypewriterAnimatedTextState();
}

class _TypewriterAnimatedTextState extends State<TypewriterAnimatedText> with TickerProviderStateMixin {
  late AnimationController _typingController;
  late Animation<int> _charCount;
  
  late AnimationController _cursorController;

  @override
  void initState() {
    super.initState();
    
    // Calculate duration based on text length if not provided (e.g. 200ms per char)
    final typingDuration = widget.duration ?? Duration(milliseconds: widget.text.length * 200);

    _typingController = AnimationController(vsync: this, duration: typingDuration);
    _charCount = IntTween(begin: 0, end: widget.text.length).animate(
      CurvedAnimation(parent: _typingController, curve: Curves.linear),
    );

    _cursorController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))
      ..repeat(reverse: true);

    _typingController.forward();
  }

  @override
  void dispose() {
    _typingController.dispose();
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_typingController, _cursorController]),
      builder: (context, child) {
        String visibleString = widget.text.substring(0, _charCount.value);
        
        // Cursor logic: Blink. 
        // Only show cursor while typing is in progress.
        bool isTypingFinished = _charCount.value == widget.text.length;
        bool showCursor = !isTypingFinished && _cursorController.value > 0.5;

        // Use a RichText to style the cursor differently if needed, or just append
        return Text.rich(
          TextSpan(
            text: visibleString,
            style: widget.style,
            children: [
              TextSpan(
                text: showCursor ? '|' : ' ', 
                style: widget.style.copyWith(color: widget.style.color?.withOpacity(0.5) ?? Colors.grey),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        );
      },
    );
  }
}
