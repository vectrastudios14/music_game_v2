import 'dart:convert';
import 'dart:io';

void main() async {
  final path = 'assets/songs_arabic.json';
  final file = File(path);
  final content = await file.readAsString(encoding: utf8);
  final List<dynamic> json = jsonDecode(content);

  final List<Map<String, String>> deepReplacements = [
    {'سنة': 'فترة'},
    {'عام': 'فترة'},
    {'عقد': 'حقبة'},
    {'قرن': 'زمن'},
    {'التسعينات': 'تلك الفترة'},
    {'الثمانينات': 'تلك الفترة'},
    {'السبعينات': 'تلك الفترة'},
  ];

  for (var song in json) {
    if (song['facts'] != null && song['facts'] is List) {
      List<String> facts = List<String>.from(song['facts']);
      List<String> newFacts = [];

      for (var f in facts) {
        String sanitized = f;
        for (var map in deepReplacements) {
          map.forEach((key, value) {
            sanitized = sanitized.replaceAll(key, value);
          });
        }
        newFacts.add(sanitized);
      }
      song['facts'] = newFacts.toSet().toList();
    }
  }

  final encoder = JsonEncoder.withIndent('  ');
  await file.writeAsString(encoder.convert(json), encoding: utf8);
  print('Arabic Deep Desat Complete.');
}
