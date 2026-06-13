import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:animate_do/animate_do.dart';

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

    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    // Dark Mode background gradient or Light Mode soft background
    final bgDecoration = isLightMode
        ? const BoxDecoration(
            color: Color(0xFFF8F9FA),
          )
        : const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F0C1B), Color(0xFF150E28), Color(0xFF0A0515)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          );

    return Scaffold(
      body: Container(
        decoration: bgDecoration,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header with title
                _buildHeader(context, isLightMode),

                const SizedBox(height: 20),

                // Main Content
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // LEFT SIDE: Podium & Congratulations
                      Expanded(
                        flex: 6,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Trophy / Confetti animation
                            FadeInDown(
                              duration: const Duration(milliseconds: 800),
                              child: SizedBox(
                                height: 160,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Lottie.asset(
                                      'assets/animations/Congratulations.json',
                                      fit: BoxFit.contain,
                                    ),
                                    Lottie.asset(
                                      'assets/animations/Trophy.json',
                                      height: 120,
                                      repeat: true,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            Text(
                              isLightMode ? "CONGRATULATIONS!" : "👑 VICTORY CEREMONY",
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isLightMode ? Colors.purple[800] : const Color(0xFFFFD700),
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              winner != null ? "${winner.key} Wins!".toUpperCase() : "GAME COMPLETED",
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: isLightMode ? Colors.black87 : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 30),

                            // The 3D Podium
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: _buildPodium(sortedEntries, isLightMode, primaryColor),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 40),

                      // RIGHT SIDE: Leaderboard list & Actions
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              "FINAL STANDINGS",
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isLightMode ? Colors.black54 : Colors.white54,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Leaderboard entries list
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isLightMode
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isLightMode
                                        ? Colors.black.withOpacity(0.05)
                                        : Colors.white.withOpacity(0.08),
                                    width: 1.5,
                                  ),
                                  boxShadow: isLightMode
                                      ? [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
                                      : [],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: ListView.separated(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    itemCount: sortedEntries.length,
                                    separatorBuilder: (_, __) => Divider(
                                      height: 1,
                                      color: isLightMode
                                          ? Colors.black.withOpacity(0.05)
                                          : Colors.white.withOpacity(0.05),
                                    ),
                                    itemBuilder: (context, index) {
                                      final entry = sortedEntries[index];
                                      final rank = index + 1;
                                      return FadeInLeft(
                                        delay: Duration(milliseconds: index * 100),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                          leading: CircleAvatar(
                                            radius: 14,
                                            backgroundColor: _getMedalColor(rank, primaryColor),
                                            child: Text(
                                              rank.toString(),
                                              style: GoogleFonts.outfit(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: rank <= 3 ? Colors.black87 : (isLightMode ? Colors.black54 : Colors.white70),
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            entry.key,
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: isLightMode ? Colors.black87 : Colors.white,
                                            ),
                                          ),
                                          trailing: Text(
                                            "${entry.value} pts",
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: rank == 1 ? primaryColor : (isLightMode ? Colors.black54 : Colors.white70),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Actions
                            Row(
                              children: [
                                Expanded(
                                  child: _ResultActionButton(
                                    label: 'MENU',
                                    isOutlined: true,
                                    isLightMode: isLightMode,
                                    primaryColor: primaryColor,
                                    onPressed: () {
                                      Navigator.popUntil(context, (route) => route.isFirst);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _ResultActionButton(
                                    label: 'PLAY AGAIN',
                                    isOutlined: false,
                                    isLightMode: isLightMode,
                                    primaryColor: primaryColor,
                                    autofocus: true,
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isLightMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "CEREMONY",
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isLightMode ? Colors.black87 : Colors.white,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPodium(List<MapEntry<String, int>> sortedEntries, bool isLightMode, Color primaryColor) {
    final hasSecond = sortedEntries.length > 1;
    final hasThird = sortedEntries.length > 2;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd Place Podium
        if (hasSecond)
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 200),
            child: _buildPodiumStep(
              entry: sortedEntries[1],
              rank: 2,
              height: 120,
              glowColor: const Color(0xFFC0C0C0), // Silver
              isLightMode: isLightMode,
            ),
          ),
        const SizedBox(width: 12),

        // 1st Place Podium
        if (sortedEntries.isNotEmpty)
          FadeInUp(
            duration: const Duration(milliseconds: 700),
            child: _buildPodiumStep(
              entry: sortedEntries[0],
              rank: 1,
              height: 160,
              glowColor: const Color(0xFFFFD700), // Gold
              isLightMode: isLightMode,
            ),
          ),
        const SizedBox(width: 12),

        // 3rd Place Podium
        if (hasThird)
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 400),
            child: _buildPodiumStep(
              entry: sortedEntries[2],
              rank: 3,
              height: 90,
              glowColor: const Color(0xFFCD7F32), // Bronze
              isLightMode: isLightMode,
            ),
          ),
      ],
    );
  }

  Widget _buildPodiumStep({
    required MapEntry<String, int> entry,
    required int rank,
    required double height,
    required Color glowColor,
    required bool isLightMode,
  }) {
    final medalIcon = rank == 1 ? "🥇" : (rank == 2 ? "🥈" : "🥉");

    return SizedBox(
      width: 130,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Medal/Crown Floating Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: glowColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: glowColor, width: 1.5),
            ),
            child: Text(
              medalIcon,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(height: 8),

          // Player Name
          Text(
            entry.key.toUpperCase(),
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isLightMode ? Colors.black87 : Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),

          // Player Score
          Text(
            "${entry.value} pts",
            style: GoogleFonts.robotoMono(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: glowColor,
            ),
          ),
          const SizedBox(height: 12),

          // The Podium block itself (Glassmorphic look)
          Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLightMode
                    ? [Colors.white, Colors.grey[200]!]
                    : [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.02)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border.all(
                color: glowColor.withOpacity(0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withOpacity(0.15),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              "#$rank",
              style: GoogleFonts.outfit(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: glowColor.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getMedalColor(int rank, Color primary) {
    if (rank == 1) return const Color(0xFFFFD700); // Gold
    if (rank == 2) return const Color(0xFFC0C0C0); // Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    return Colors.white12;
  }
}

class _ResultActionButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isOutlined;
  final bool isLightMode;
  final Color? primaryColor;
  final bool autofocus;

  const _ResultActionButton({
    required this.label,
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: (widget.primaryColor ?? Colors.blue).withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    )
                  ]
                : [],
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
                  child: Text(
                    widget.label,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
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
                  child: Text(
                    widget.label,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ),
        ),
      ),
    );
  }
}
