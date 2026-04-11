import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BoaHelpScreen extends StatefulWidget {
  final bool initialIsArabic;
  const BoaHelpScreen({super.key, this.initialIsArabic = false});

  @override
  State<BoaHelpScreen> createState() => _BoaHelpScreenState();
}

class _BoaHelpScreenState extends State<BoaHelpScreen> {
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
      'objectiveDesc': 'Build your timeline by placing songs in the correct chronological order based on their release year.',
      'gameRules': 'Game Rules',
      'dragDrop': 'Drag & Drop',
      'dragDropDesc': 'Drag the card to the correct position on the timeline.',
      'left': 'Left',
      'leftDesc': 'Older (Released Earlier)',
      'right': 'Right',
      'rightDesc': 'Newer (Released Later)',
      'winning': 'Winning',
      'winningDesc': 'The first player to reach the target score wins accurately placing songs on their timeline!',
      'toggleLanguage': 'العربية',
    },
    'ar': {
      'howToPlay': 'طريقة اللعب',
      'objective': 'الهدف',
      'objectiveDesc': 'ابنِ خطك الزمني من خلال وضع الأغاني بترتيبها الزمني الصحيح بناءً على سنة إصدارها.',
      'gameRules': 'قواعد اللعبة',
      'dragDrop': 'السحب والإفلات',
      'dragDropDesc': 'اسحب البطاقة إلى الموضع الصحيح على الخط الزمني.',
      'left': 'اليسار',
      'leftDesc': 'أقدم (تم إصدارها مبكراً)',
      'right': 'اليمين',
      'rightDesc': 'أحدث (تم إصدارها لاحقاً)',
      'winning': 'الفوز',
      'winningDesc': 'أول لاعب يصل إلى النتيجة المستهدفة يفوز من خلال وضع الأغاني بدقة على خطه الزمني!',
      'toggleLanguage': 'English',
    },
  };

  String _t(String key) {
    return _localizedStrings[_isArabic ? 'ar' : 'en']! [key]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: null,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
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
              icon: const Icon(Icons.language_rounded, color: Colors.black54, size: 20),
              label: Text(
                _t('toggleLanguage'),
                style: GoogleFonts.outfit(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true, 
      body: Directionality(
        textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
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
                        'assets/Before_or_after_logo.png',
                        height: 100, 
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _t('howToPlay'),
                        style: GoogleFonts.outfit(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
          
                  // CONTENT FRAME
                  Expanded(
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 600),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHelpSection(context, _t('objective'), _t('objectiveDesc')),
                              
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(color: Colors.black12),
                              ),
          
                              _buildHelpSection(context, _t('gameRules'), null, customContent: Column(
                                children: [
                                  _buildRuleRow(context, Icons.drag_indicator, _t('dragDrop'), _t('dragDropDesc')),
                                  const SizedBox(height: 8),
                                  _buildRuleRow(context, Icons.west, _t('left'), _t('leftDesc')),
                                  const SizedBox(height: 8),
                                  _buildRuleRow(context, Icons.east, _t('right'), _t('rightDesc')),
                                ],
                              )),
          
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(color: Colors.black12),
                              ),
          
                              _buildHelpSection(context, _t('winning'), _t('winningDesc')),
                            ],
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
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        if (text != null)
           Text(
            text,
            style: GoogleFonts.outfit(fontSize: 16, height: 1.4, color: Colors.black54),
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
        Icon(icon, color: Colors.black87, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.outfit(fontSize: 16, height: 1.4, color: Colors.black54),
              children: [
                TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
