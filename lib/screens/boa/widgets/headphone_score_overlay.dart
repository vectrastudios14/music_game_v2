import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/song.dart'; // Adjust path as needed

class HeadphoneScoreOverlay extends StatelessWidget {
  final Map<String, List<Song>> timelines;
  final List<String> playerNames;
  final int targetScore;
  final VoidCallback onNextTurn;

  const HeadphoneScoreOverlay({
    super.key,
    required this.timelines,
    required this.playerNames,
    required this.targetScore,
    required this.onNextTurn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // Solid White overlay
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Headphone Graphic + Equalizer
            SizedBox(
              width: 500, // Fixed width container for graphic
              height: 400,
              child: Stack(
                alignment: Alignment.center,
                children: [
                   // 1. Headphone Graphic (Approximated with Shapes for now)
                   // Band
                   Positioned(
                     top: 0,
                     child: Container(
                       width: 400,
                       height: 150,
                       decoration: BoxDecoration(
                         borderRadius: const BorderRadius.vertical(top: Radius.circular(200)),
                         border: Border.all(color: Colors.grey.shade300, width: 20), // Light grey band
                       ),
                     ),
                   ),
                   // Ear Cups
                   Positioned(
                     left: 0,
                     bottom: 40,
                     child: _buildEarCup(context, true),
                   ),
                   Positioned(
                     right: 0,
                     bottom: 40,
                     child: _buildEarCup(context, false),
                   ),

                   // 2. Equalizer Bars (Inside the Headspace)
                   Positioned(
                     bottom: 40,
                     child: Container(
                       padding: const EdgeInsets.symmetric(horizontal: 20),
                       child: Row(
                         crossAxisAlignment: CrossAxisAlignment.end,
                         mainAxisSize: MainAxisSize.min,
                         children: playerNames.map((player) {
                           return _buildPlayerEqualizer(context, player);
                         }).toList(),
                       ),
                     ),
                   ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Next Turn Button
            ElevatedButton.icon(
              onPressed: onNextTurn,
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              label: Text("NEXT TURN", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20)),
              style: ElevatedButton.styleFrom(
                 backgroundColor: Colors.black, // Stark contrast for button
                 foregroundColor: Colors.white,
                 padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                 elevation: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarCup(BuildContext context, bool isLeft) {
    return Container(
      width: 80,
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), // Off-white/Light grey ear cup
        borderRadius: BorderRadius.only(
           topLeft: Radius.circular(isLeft ? 40 : 10),
           topRight: Radius.circular(!isLeft ? 40 : 10),
           bottomLeft: Radius.circular(isLeft ? 40 : 10),
           bottomRight: Radius.circular(!isLeft ? 40 : 10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Softer shadow
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
    );
  }

  Widget _buildPlayerEqualizer(BuildContext context, String player) {
    final score = timelines[player]?.length ?? 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bars
          Column(
             mainAxisAlignment: MainAxisAlignment.end,
             children: List.generate(targetScore, (index) {
                final pointIndex = targetScore - 1 - index; 
                final isFilled = score > pointIndex;
                
                final double fraction = pointIndex / (targetScore > 1 ? targetScore - 1 : 1);
                final Color barColor = _getGradientColor(fraction);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Container(
                    width: 30,
                    height: 15,
                    decoration: BoxDecoration(
                      color: isFilled ? barColor : Colors.grey.shade200, 
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: isFilled ? [
                         BoxShadow(
                           color: barColor.withOpacity(0.4), 
                           blurRadius: 8, 
                           spreadRadius: 1
                         )
                      ] : null,
                    ),
                  ),
                );
             }),
          ),
          const SizedBox(height: 10),
          // Player Name
          Text(
            player,
            style: GoogleFonts.outfit(
              color: Colors.black87, 
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
             "$score/$targetScore",
             style: const TextStyle(color: Colors.black54, fontSize: 10), 
          ),
        ],
      ),
    );
  }
  
  Color _getGradientColor(double fraction) {
    // Green -> Yellow -> Red
    if (fraction < 0.5) {
      // Green to Yellow
      return Color.lerp(Colors.greenAccent, Colors.amber, fraction * 2)!;
    } else {
      // Yellow to Red
      return Color.lerp(Colors.amber, Colors.redAccent, (fraction - 0.5) * 2)!;
    }
  }
}
