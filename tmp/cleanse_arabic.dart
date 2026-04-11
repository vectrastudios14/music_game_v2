import 'dart:convert';
import 'dart:io';

void main() async {
  final path = 'assets/songs_arabic.json';
  final file = File(path);
  
  if (!await file.exists()) {
    print('File not found: $path');
    return;
  }

  final content = await file.readAsString(encoding: utf8);
  final List<dynamic> json = jsonDecode(content);

  final yearRegex = RegExp(r'\b(19|20)\d{2}\b');
  
  // Arabic Decade Maps
  final Map<String, String> replacements = {
    'الثمانينات': 'تلك الفترة',
    'التسعينات': 'تلك الفترة',
    'السبعينات': 'تلك الفترة',
    'الستينات': 'تلك الفترة',
    'الخمسينات': 'تلك الفترة',
    'ثمانينات': 'تلك الفترة',
    'تسعينات': 'تلك الفترة',
    'سبعينات': 'تلك الفترة',
    'ستينات': 'تلك الفترة',
    'خمسينات': 'تلك الفترة',
    'منذ': 'بعد',
    'الألفية': 'الفترة الحديثة',
  };

  for (var song in json) {
    if (song['facts'] != null && song['facts'] is List) {
      List<String> facts = List<String>.from(song['facts']);
      List<String> newFacts = [];

      for (var f in facts) {
        String sanitized = f;
        
        // 1. Decades
        replacements.forEach((key, value) {
          sanitized = sanitized.replaceAll(key, value);
        });

        // 2. Years
        sanitized = sanitized.replaceAll(yearRegex, 'وقت صدورها');
        
        newFacts.add(sanitized);
      }
      
      song['facts'] = newFacts.toSet().toList(); // Deduplicate
    }
  }

  final encoder = JsonEncoder.withIndent('  ');
  await file.writeAsString(encoder.convert(json), encoding: utf8);
  print('Arabic Cleansing Complete.');
}
