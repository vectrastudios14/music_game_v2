import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:animate_do/animate_do.dart';

class BoaGameOverModal extends StatelessWidget {
  final String winnerName;
  final int winnerScore;
  final VoidCallback onViewResults;
  final VoidCallback onContinue;

  const BoaGameOverModal({
    super.key,
    required this.winnerName,
    required this.winnerScore,
    required this.onViewResults,
    required this.onContinue,
    this.uiLanguage = 'en',
  });

  final String uiLanguage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: FadeInUp(
          duration: const Duration(milliseconds: 600),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Directionality(
              textDirection: uiLanguage == 'ar' ? TextDirection.rtl : TextDirection.ltr,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Celebration Animation
                  SizedBox(
                    height: 200,
                    child: Lottie.asset(
                      'assets/animations/Congratulations.json',
                      repeat: true,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Text(
                    uiLanguage == 'ar' ? "لدينا فائز!" : "WE HAVE A WINNER!",
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 10),
                  
                  Text(
                    winnerName.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 10),
                  
                  Text(
                    uiLanguage == 'ar' ? "وصل لهدف $winnerScore نقطة!" : "Achieved the target of $winnerScore points!",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onContinue,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            side: BorderSide(color: Colors.grey[300]!, width: 2),
                          ),
                          child: Text(
                            uiLanguage == 'ar' ? "بقاء" : "STAY",
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onViewResults,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 5,
                          ),
                          child: Text(
                            uiLanguage == 'ar' ? "نتائج" : "RESULTS",
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
