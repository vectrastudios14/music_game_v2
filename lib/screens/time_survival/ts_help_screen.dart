import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TsHelpScreen extends StatefulWidget {
  final bool initialIsArabic;
  const TsHelpScreen({super.key, this.initialIsArabic = false});

  @override
  State<TsHelpScreen> createState() => _TsHelpScreenState();
}

class _TsHelpScreenState extends State<TsHelpScreen> {
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
      'objectiveDesc': 'Survive as long as you can! If any player reaches 0 points, the game ends immediately.',
      'controls': 'Controls',
      'browse': 'Browse (Top Bar)',
      'browseDesc': 'Use the timeline to navigate through different years (1970–2026).',
      'select': 'Select Year',
      'selectDesc': 'Tap on any year to pick your guess.',
      'lockIn': 'Lock In',
      'lockInDesc': 'Press the button to confirm your choice and pass the turn to the next player.',
      'revealFacts': 'Reveal Facts',
      'revealFactsDesc': 'Hover over/tap the album artwork (bottom left) to see interesting trivia about the current song.',
      'scoring': 'Scoring',
      'penalty': 'Year Distance',
      'penaltyDesc': 'You lose points equal to the difference between your guess and the real answer.',
      'example': 'Example: If the song is from 1985 and you guess 1980, you lose 5 points.',
      'result': 'Result',
      'resultDesc': 'When the game ends, the player with the most remaining points is declared the winner!',
      'toggleLanguage': 'العربية',
    },
    'ar': {
      'howToPlay': 'طريقة اللعب',
      'objective': 'الهدف',
      'objectiveDesc': 'ابقَ على قيد الحياة لأطول فترة ممكنة! إذا وصل أي لاعب إلى 0 نقطة، تنتهي اللعبة فوراً.',
      'controls': 'التحكم',
      'browse': 'التصفح',
      'browseDesc': 'استخدم الجدول الزمني للتنقل بين السنوات المختلفة (1970–2026).',
      'select': 'اختيار السنة',
      'selectDesc': 'اضغط على السنة لتحديد تخمينك.',
      'lockIn': 'التأكيد',
      'lockInDesc': 'اضغط على زر التأكيد لتثبيت اختيارك ونقل الدور للاعب التالي.',
      'revealFacts': 'كشف الحقائق',
      'revealFactsDesc': 'اضغط على غلاف الألبوم (أسفل اليسار) لرؤية معلومات وحقائق ممتعة عن الأغنية الحالية.',
      'scoring': 'الحساب',
      'penalty': 'فرق السنوات',
      'penaltyDesc': 'تخسر نقاطاً مساوية للفرق بين السنة التي اخترتها والسنة الحقيقية للأغنية.',
      'example': 'مثال: إذا كانت الأغنية من عام 1985 وتخمينك كان 1980، ستخسر 5 نقاط.',
      'result': 'النتيجة',
      'resultDesc': 'عند انتهاء اللعبة، يتم إعلان اللاعب صاحب أكبر عدد من النقاط المتبقية هو الفائز!',
      'toggleLanguage': 'English',
    },
  };

  String _t(String key) {
    return _localizedStrings[_isArabic ? 'ar' : 'en']![key]!;
  }

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: null,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HEADER
                Column(
                  children: [
                    Image.asset(
                      'assets/TimeSurvival_logo.png',
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _t('howToPlay'),
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // CONTENT FRAME
                Expanded(
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      padding: const EdgeInsets.all(4), // Reduced padding to allow scrollbar at edge
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          scrollbarTheme: ScrollbarThemeData(
                            thumbColor: WidgetStateProperty.all(const Color(0xFF6C63FF).withOpacity(0.5)),
                            trackColor: WidgetStateProperty.all(Colors.white.withOpacity(0.05)),
                            thickness: WidgetStateProperty.all(6),
                            radius: const Radius.circular(10),
                          ),
                        ),
                        child: Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            _buildHelpSection(context, _t('objective'), _t('objectiveDesc')),
                            
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Divider(color: Colors.white12),
                            ),

                            _buildHelpSection(context, _t('controls'), null, customContent: Column(
                              children: [
                                _buildRuleRow(context, Icons.mouse_rounded, _t('browse'), _t('browseDesc')),
                                const SizedBox(height: 12),
                                _buildRuleRow(context, Icons.touch_app_rounded, _t('select'), _t('selectDesc')),
                                const SizedBox(height: 12),
                                _buildRuleRow(context, Icons.check_circle_outline_rounded, _t('lockIn'), _t('lockInDesc')),
                                const SizedBox(height: 12),
                                _buildRuleRow(context, Icons.info_outline_rounded, _t('revealFacts'), _t('revealFactsDesc')),
                              ],
                            )),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Divider(color: Colors.white12),
                            ),

                            _buildHelpSection(context, _t('scoring'), null, customContent: Column(
                              children: [
                                _buildRuleRow(context, Icons.trending_down, _t('penalty'), _t('penaltyDesc')),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: EdgeInsets.only(left: _isArabic ? 0 : 34.0, right: _isArabic ? 34.0 : 0),
                                  child: Text(
                                    _t('example'),
                                    style: GoogleFonts.outfit(fontSize: 14, color: Colors.white38, fontStyle: FontStyle.italic),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildRuleRow(context, Icons.emoji_events_rounded, _t('result'), _t('resultDesc')),
                              ],
                            )),
                            ],
                          ),
                        ),
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF6C63FF),
          ),
        ),
        const SizedBox(height: 10),
        if (text != null)
          Text(
            text,
            style: GoogleFonts.outfit(fontSize: 16, height: 1.4, color: Colors.white70),
          ),
        if (customContent != null) ...[
          const SizedBox(height: 12),
          customContent,
        ],
      ],
    );
  }

  Widget _buildRuleRow(BuildContext context, IconData icon, String label, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF6C63FF), size: 22),
        const SizedBox(width: 12),
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
}
