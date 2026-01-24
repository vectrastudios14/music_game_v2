import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GtsResultScreen extends StatelessWidget {
  final Map<String, int> scores;
  final int totalRounds;

  const GtsResultScreen({
    super.key,
    required this.scores,
    required this.totalRounds,
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
      backgroundColor: theme.scaffoldBackgroundColor, 
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header
              Center(
                child: Text(
                  'WINNER',
                  style: GoogleFonts.outfit(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2.0,
                    shadows: [
                      Shadow(color: primaryColor.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 0)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 2. Winner Showcase
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.surface,
                        theme.colorScheme.surface.withOpacity(0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: primaryColor.withOpacity(0.3), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // REMOVED TROPHY ICON AS REQUESTED
                        
                        // Winner Name
                        // Text(isTie ? "It's a Tie!" : 'CHAMPION', ... ) REMOVED
                        const SizedBox(height: 10),
                        Text(
                          winner?.key ?? 'No One',
                          style: GoogleFonts.outfit(
                            fontSize: 80, // Enlarged from 40
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${winner?.value ?? 0}',
                          style: GoogleFonts.outfit(
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            color: primaryColor,
                          ),
                        ),
                        Text(
                          'POINTS',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white54,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 3. Leaderboard Label
              Text(
                'LEADERBOARD',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 15),

              // 4. List
              Expanded(
                flex: 3,
                child: ListView.separated(
                  itemCount: sortedEntries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final entry = sortedEntries[index];
                    final rank = index + 1;
                    final isTop = rank == 1;

                    return Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isTop ? primaryColor.withOpacity(0.5) : Colors.white10,
                          width: isTop ? 2 : 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          // Rank
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getRankColor(rank, primaryColor),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '#$rank',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black, // Dark text on bright badge
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Name
                          Text(
                            entry.key,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          // Score
                          Text(
                            '${entry.value}',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isTop ? primaryColor : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),

              // 5. Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('MENU'),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); 
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('PLAY AGAIN'),
                    ),
                  ),
                ],
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
