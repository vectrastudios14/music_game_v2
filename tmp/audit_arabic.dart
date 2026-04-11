import 'dart:convert';
import 'dart:io';

void main() async {
  final path = 'assets/songs_arabic.json';
  final file = File(path);
  final content = await file.readAsString(encoding: utf8);
  final List<dynamic> json = jsonDecode(content);

  final yearRegex = RegExp(r'\b(19|20)\d{2}\b');
  final eraKeywords = [
    'سنة', 'عام', 'عقد', 'قرن', 'الألفية', 
    'الثمانينات', 'التسعينات', 'السبعينات', 'الستينات', 'الخمسينات', 
    'ثمانينات', 'تسعينات', 'سبعينات', 'ستينات', 'خمسينات',
  ];

  int cluesFound = 0;
  for (var song in json) {
    bool hasClue = false;
    for (var fact in (song['facts'] ?? [])) {
      if (yearRegex.hasMatch(fact)) { hasClue = true; break; }
      if (eraKeywords.any((k) => fact.toString().contains(k))) { hasClue = true; break; }
    }
    if (hasClue) cluesFound++;
  }

  print('Total Arabic Songs: ${json.length}');
  print('Songs with Time References: $cluesFound');
}
