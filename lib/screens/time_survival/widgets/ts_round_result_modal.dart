import 'dart:async';
import 'dart:math';

import 'package:animate_do/animate_do.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'liquid_tube.dart';

class TsRoundResultModal extends StatefulWidget {
  final Map<String, int> scores;
  final Map<String, int> previousScores;
  final Map<String, Color> playerColors;
  final int maxScore;
  final VoidCallback onContinue;
  final VoidCallback onHide; // New callback
  final String loserName;
  final int turnNumber;

  // New props for commentary
  final Map<String, int> platformGuesses;
  final int actualYear;
  final bool isGameOver; // New prop

  const TsRoundResultModal({
    super.key,
    required this.scores,
    this.previousScores = const {},
    required this.playerColors,
    required this.maxScore,
    required this.onContinue,
    required this.onHide, // Required
    this.loserName = "",
    this.turnNumber = 0,
    required this.platformGuesses,
    required this.actualYear,
    this.isGameOver = false,
    this.uiLanguage = 'en',
  });

  final String uiLanguage;

  @override
  State<TsRoundResultModal> createState() => _TsRoundResultModalState();
}

class _TsRoundResultModalState extends State<TsRoundResultModal> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Commentary State
  List<String> _commentaryLines = [];
  int _currentCommentIndex = 0;
  Timer? _commentaryTimer;
  bool _showFinalScores = false; // New state for morphing
  bool _isMainButtonFocused = false;
  bool _isHideButtonFocused = false;

  @override
  void initState() {
    super.initState();
    _playDropSound();
    _generateCommentary();
    _startCommentaryRotation();
  }

  String _t(String key) {
    final isAr = widget.uiLanguage == 'ar';
    final Map<String, Map<String, String>> strings = {
      'en': {
        'finalScores': 'FINAL SCORES',
        'gameOver': 'GAME OVER',
        'roundComplete': 'ROUND COMPLETE',
        'showBoard': 'SHOW BOARD',
        'finalScoreBtn': 'FINAL SCORE',
        'continueBtn': 'CONTINUE',
        'hideScores': 'Hide Scores',
        'tookDamage': 'took the most damage',
        'everyoneSurvived': 'Everyone survived this round!',
        'exactlyRight': 'got it EXACTLY right!',
        'wereClosest': 'were closest',
        'yearsOff': 'years off',
        'riskTaker': 'took a big risk against the crowd!',
      },
      'ar': {
        'finalScores': 'النتائج النهائية',
        'gameOver': 'انتهت اللعبة',
        'roundComplete': 'اكتملت الجولة',
        'showBoard': 'عرض اللوحة',
        'finalScoreBtn': 'النتيجة النهائية',
        'continueBtn': 'استمرار',
        'hideScores': 'إخفاء النتائج',
        'tookDamage': 'تلقى أكبر قدر من الضرر',
        'everyoneSurvived': 'نجا الجميع في هذه الجولة!',
        'exactlyRight': 'أصاب الهدف تماماً!',
        'wereClosest': 'كانوا الأقرب',
        'yearsOff': 'سنوات فرق',
        'riskTaker': 'خاطر بشكل كبير ضد الجميع!',
      },
    };
    return strings[isAr ? 'ar' : 'en']![key] ?? key;
  }

  void _generateCommentary() {
    _commentaryLines.clear();

    // 1. Basic Result
    if (widget.loserName.isNotEmpty) {
      int damage = (widget.previousScores[widget.loserName] ?? 0) - (widget.scores[widget.loserName] ?? 0);
      _commentaryLines.add("${widget.loserName} ${_t('tookDamage')} (-$damage)!");
    } else {
      _commentaryLines.add(_t('everyoneSurvived'));
    }

    // 2. Closest Player(s)
    int minDiff = 9999;
    List<String> closestPlayers = [];

    widget.platformGuesses.forEach((name, guess) {
      int diff = (guess - widget.actualYear).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestPlayers = [name];
      } else if (diff == minDiff) {
        closestPlayers.add(name);
      }
    });

    if (closestPlayers.isNotEmpty) {
      if (minDiff == 0) {
        _commentaryLines.add("${closestPlayers.join(" & ")} ${_t('exactlyRight')}");
      } else {
        _commentaryLines.add("${closestPlayers.join(" & ")} ${_t('wereClosest')} ($minDiff ${_t('yearsOff')}).");
      }
    }

    // 3. Risk Taker
    if (widget.platformGuesses.length > 2) {
      double avg = 0;
      widget.platformGuesses.values.forEach((v) => avg += v);
      avg /= widget.platformGuesses.length;

      double maxDev = -1;
      String riskTaker = "";

      widget.platformGuesses.forEach((name, guess) {
        double dev = (guess - avg).abs();
        if (dev > maxDev) {
          maxDev = dev;
          riskTaker = name;
        }
      });

      if (maxDev > 5) {
        _commentaryLines.add("$riskTaker ${_t('riskTaker')}");
      }
    }
  }

  void _startCommentaryRotation() {
    if (_commentaryLines.length <= 1) return;

    _commentaryTimer = Timer.periodic(const Duration(seconds: 6), (timer) { // Increased to 6s
      if (mounted) {
        setState(() {
          _currentCommentIndex = (_currentCommentIndex + 1) % _commentaryLines.length;
        });
      }
    });
  }

  Future<void> _playDropSound() async {
    try {
      await _audioPlayer.setSource(AssetSource('water_drop.mp3'));
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint("Error playing drop sound: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _commentaryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Directionality(
        textDirection: widget.uiLanguage == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: Material(
          color: Colors.transparent,
          child: FadeInUp(
            duration: const Duration(milliseconds: 500),
            child: Container(
              constraints: BoxConstraints(
                  minWidth: 660.0.clamp(0.0, MediaQuery.of(context).size.width * 0.95),
                  maxWidth: MediaQuery.of(context).size.width * 0.95,
                  maxHeight: 600),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white24, width: 1),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 5),
                  ]),
              child: Stack( 
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.isGameOver 
                          ? (_showFinalScores ? _t('finalScores') : _t('gameOver')) 
                          : _t('roundComplete'),
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                      const SizedBox(height: 10),

                      // Smart Commentary with Animation (Hide if showing final scores)
                      if (!_showFinalScores && _commentaryLines.isNotEmpty)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          child: Text(
                            _commentaryLines[_currentCommentIndex],
                            key: ValueKey<int>(_currentCommentIndex),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                                color: _commentaryLines[_currentCommentIndex].contains(_t('tookDamage'))
                                    ? Colors.redAccent
                                    : Colors.greenAccent,
                                fontSize: 18,
                                fontWeight: FontWeight.w500),
                          ),
                        ),

                      const SizedBox(height: 30),
                      
                      // Tubes List
                      AnimatedSize(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOutBack,
                        child: _showFinalScores 
                          ? _buildFinalScoreRankings() 
                          : _buildRoundResultVertical(),
                      ),

                      const SizedBox(height: 30),

                      // Main Button
                      Focus(
                        autofocus: true,
                        onFocusChange: (focused) => setState(() => _isMainButtonFocused = focused),
                        onKeyEvent: (node, event) {
                          if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.select) {
                            if (widget.isGameOver && !_showFinalScores) {
                              setState(() => _showFinalScores = true);
                            } else {
                              widget.onContinue();
                            }
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: AnimatedScale(
                          scale: _isMainButtonFocused ? 1.05 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            width: 200,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: _isMainButtonFocused ? [
                                BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.5), blurRadius: 15, spreadRadius: 2)
                              ] : [],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                if (widget.isGameOver && !_showFinalScores) {
                                  setState(() => _showFinalScores = true);
                                } else {
                                  widget.onContinue();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6C63FF),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  side: _isMainButtonFocused ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
                                ),
                                elevation: _isMainButtonFocused ? 10 : 5,
                              ),
                              child: Text(
                                _showFinalScores ? _t('showBoard') : (widget.isGameOver ? _t('finalScoreBtn') : _t('continueBtn')), 
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Hide Button
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Focus(
                      onFocusChange: (focused) => setState(() => _isHideButtonFocused = focused),
                      onKeyEvent: (node, event) {
                        if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.select) {
                          widget.onHide();
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: TextButton.icon(
                        onPressed: widget.onHide,
                        icon: Icon(Icons.visibility_off, size: 16, color: _isHideButtonFocused ? Colors.white : Colors.white54),
                        label: Text(_t('hideScores'), style: TextStyle(color: _isHideButtonFocused ? Colors.white : Colors.white54, fontSize: 12)),
                        style: TextButton.styleFrom(
                          overlayColor: Colors.white10,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: _isHideButtonFocused ? const BorderSide(color: Colors.white24) : BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoundResultVertical() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: widget.scores.entries.map((entry) {
          final name = entry.key;
          final score = entry.value;
          final prevScore = widget.previousScores[name] ?? score; 
          final color = widget.playerColors[name] ?? Colors.grey;
          
          final isDead = score <= 0;
          final int highestScore = widget.scores.values.fold(0, max);
          final isWinner = score == highestScore && score > 0;

          return Container(
            width: 70, 
            margin: const EdgeInsets.symmetric(horizontal: 5), 
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: prevScore, end: score),
                  duration: const Duration(milliseconds: 3000),
                  curve: Curves.easeInOutQuart,
                  builder: (context, value, child) {
                    return Text(
                      "$value",
                      style: GoogleFonts.robotoMono(
                        color: isDead ? Colors.redAccent : (isWinner ? Colors.amberAccent : Colors.white), 
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      )
                    );
                  }
                ),
                const SizedBox(height: 8),
                LiquidTube(
                  score: score.toDouble(),
                  startScore: prevScore.toDouble(),
                  maxScore: widget.maxScore.toDouble(),
                  color: color,
                  height: 150, 
                  width: 40,
                  isBroken: isDead,
                  isWinner: isWinner,
                  isHorizontal: false,
                ),
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isWinner ? Colors.amberAccent : color.withOpacity(0.5), 
                          width: isWinner ? 2.5 : 1
                        ),
                    ),
                    child: Row(
                      children: [
                        if (isWinner) ...[
                          const Icon(Icons.star, color: Colors.amber, size: 10),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          name,
                          style: GoogleFonts.outfit(
                            color: isWinner ? Colors.amberAccent : Colors.white, 
                            fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFinalScoreRankings() {
    final sortedEntries = widget.scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: sortedEntries.map((entry) {
        final name = entry.key;
        final score = entry.value;
        final color = widget.playerColors[name] ?? Colors.grey;
        final int highestScore = widget.scores.values.fold(0, max);
        final isWinner = score == highestScore && score > 0;
        final isDead = score <= 0;

        return FadeInLeft(
          duration: const Duration(milliseconds: 500),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    name,
                    style: GoogleFonts.outfit(
                      color: isWinner ? Colors.amberAccent : Colors.white,
                      fontSize: 16,
                      fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: LiquidTube(
                    score: score.toDouble(),
                    maxScore: widget.maxScore.toDouble(),
                    color: color,
                    height: 35, 
                    width: double.infinity,
                    isBroken: isDead,
                    isWinner: isWinner,
                    isHorizontal: true,
                  ),
                ),
                const SizedBox(width: 15),
                Text(
                  "$score",
                  style: GoogleFonts.robotoMono(
                    color: isDead ? Colors.redAccent : (isWinner ? Colors.amberAccent : Colors.white),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
