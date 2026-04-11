import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GtsHelpScreen extends StatefulWidget {
  final bool initialIsArabic;
  const GtsHelpScreen({super.key, this.initialIsArabic = false});

  @override
  State<GtsHelpScreen> createState() => _GtsHelpScreenState();
}

class _GtsHelpScreenState extends State<GtsHelpScreen> {
  late bool _isArabic;

  @override
  void initState() {
    super.initState();
    _isArabic = widget.initialIsArabic;
  }

  static const Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'howToPlay': 'How to Play',
      'objective': 'Objective',
      'objectiveDesc': 'Listen to the song snippet and identify the correct artist or track from the four options.',
      'gameModes': 'Game Modes',
      'easyMode': 'Easy Mode',
      'easyModeDesc': 'Artist + Song Title',
      'hardMode': 'Hard Mode',
      'hardModeDesc': 'Artist Name Only',
      'scoring': 'Scoring',
      'baseScore': 'Base Score',
      'timeBonus': 'Time Bonus',
      'hintPenalty': 'Hint Penalty',
      'hints': 'Hints',
      'hintsDesc': 'Use up to 2 hints per turn. Each hint removes one wrong answer (-100 pts).',
      'teamMode': 'Team Mode (Buzzer)',
      'teamModeDesc': 'Teams race to buzz in. Listening speed and selection accuracy are both rewarded!',
      'teamScoring': 'Team Mode Scoring',
      'listeningPhase': 'Listening Phase',
      'selectionPhase': 'Selection Phase',
      'listeningDesc': 'Earn 500-1000 pts based on buzz speed.',
      'selectionDesc': 'Points decay (-50/sec) while thinking.',
      'toggleLanguage': 'العربية',
    },
    'ar': {
      'howToPlay': 'طريقة اللعب',
      'objective': 'الهدف',
      'objectiveDesc': 'استمع إلى مقطع من الأغنية وحدد الفنان أو اسم الأغنية الصحيح من بين أربعة خيارات.',
      'gameModes': 'أنماط اللعبة',
      'easyMode': 'النمط السهل',
      'easyModeDesc': 'اسم الفنان + عنوان الأغنية',
      'hardMode': 'النمط الصعب',
      'hardModeDesc': 'اسم الفنان فقط',
      'scoring': 'النقاط',
      'baseScore': 'النقاط الأساسية',
      'timeBonus': 'مكافأة الوقت',
      'hintPenalty': 'خصم التلميحات',
      'hints': 'التلميحات',
      'hintsDesc': 'استخدم تلميحتين كحد أقصى في كل دور. كل تلميحة تحذف خياراً خاطئاً (-100 نقطة).',
      'teamMode': 'وضع الفرق',
      'teamModeDesc': 'تتنافس الفرق للضغط أولاً. سرعة الاستماع ودقة الاختيار كلاهما يكافئان!',
      'teamScoring': 'نقاط وضع الفرق',
      'listeningPhase': 'مرحلة الاستماع',
      'selectionPhase': 'مرحلة الاختيار',
      'listeningDesc': 'احصل على 500-1000 نقطة بناءً على سرعة الضغط.',
      'selectionDesc': 'تناقص النقاط (-50/ثانية) أثناء التفكير.',
      'toggleLanguage': 'English',
    },
  };

  String _t(String key) {
    return _localizedStrings[_isArabic ? 'ar' : 'en']![key]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: null,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _isArabic = !_isArabic;
                });
              },
              icon: const Icon(Icons.language_rounded, color: Colors.white70, size: 20),
              label: Text(
                _t('toggleLanguage'),
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
      body: Directionality(
        textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // HEADER
                            Column(
                              children: [
                                Image.asset(
                                  'assets/Guess_that_song_logo.png',
                                  height: 100,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  _t('howToPlay'),
                                  style: GoogleFonts.outfit(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),

                            // CONTENT FRAME
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                                boxShadow: [
                                  BoxShadow(color: Colors.black26, blurRadius: 40, spreadRadius: 10),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildHelpSection(context, _t('objective'), _t('objectiveDesc')),
                                  const Divider(color: Colors.white10, height: 40),
                                  _buildHelpSection(context, _t('gameModes'), null, customContent: Column(
                                    children: [
                                      _buildAbilityRow(context, _t('easyMode'), _t('easyModeDesc')),
                                      const SizedBox(height: 12),
                                      _buildAbilityRow(context, _t('hardMode'), _t('hardModeDesc')),
                                      const SizedBox(height: 12),
                                      _buildAbilityRow(context, _t('teamMode'), _t('teamModeDesc')),
                                    ],
                                  )),
                                  const Divider(color: Colors.white10, height: 40),
                                  _buildHelpSection(context, _t('scoring'), null, customContent: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(widget.initialIsArabic ? "الوضع الفردي:" : "Individual Mode:", style: GoogleFonts.outfit(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      _buildScoreRow(context, _t('baseScore'), "+500", Colors.greenAccent),
                                      const SizedBox(height: 8),
                                      _buildScoreRow(context, _t('timeBonus'), _isArabic ? "حتى +500" : "Up to +500", Colors.cyan),
                                      const SizedBox(height: 8),
                                      _buildScoreRow(context, _t('hintPenalty'), "-100", Colors.redAccent),
                                      
                                      const Divider(color: Colors.white10, height: 30),
                                      Text(_t('teamScoring') + ":", style: GoogleFonts.outfit(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      _buildScoreRow(context, _t('listeningPhase'), "500 - 1000", Colors.cyan),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 10, top: 4, bottom: 8),
                                        child: Text(_t('listeningDesc'), style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54)),
                                      ),
                                      _buildScoreRow(context, _t('selectionPhase'), "-50 / sec", Colors.redAccent),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 10, top: 4),
                                        child: Text(_t('selectionDesc'), style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54)),
                                      ),
                                    ],
                                  )),
                                  const Divider(color: Colors.white10, height: 40),
                                  _buildHelpSection(context, _t('hints'), _t('hintsDesc')),
                                ],
                              ),
                            ),
                            const SizedBox(height: 100), // EXTRA BOTTOM SPACE for scrolling safety
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHelpSection(BuildContext context, String title, String? text, {Widget? customContent}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        if (text != null)
          Text(
            text,
            style: GoogleFonts.outfit(fontSize: 14, height: 1.3, color: Colors.white70),
          ),
        if (customContent != null) customContent,
      ],
    );
  }

  Widget _buildAbilityRow(BuildContext context, String label, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_outline, color: Theme.of(context).primaryColor, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.outfit(fontSize: 16, height: 1.4, color: Colors.white70),
              children: [
                TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreRow(BuildContext context, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 140, // Increased for Arabic alignment
            child: Text(label, style: GoogleFonts.outfit(fontSize: 16, color: Colors.white)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Text(
              value,
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
