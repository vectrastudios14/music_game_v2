import 'dart:io';
import 'dart:convert';

void main() {
  final files = ['assets/songs_arabic.json', 'assets/songs.json'];
  
  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    
    print("Processing $path");
    final content = file.readAsStringSync();
    
    final dynamic data = json.decode(content);
    int fixedCount = 0;
    int skippedCleanCount = 0;
    int untouchedCount = 0;

    String repairString(String s) {
      if (s.isEmpty) return s;
      
      bool hasCleanArabic = false;
      bool hasCorruptionMarkers = false;
      
      for (var i = 0; i < s.length; i++) {
        final code = s.codeUnitAt(i);
        if (code >= 0x0600 && code <= 0x06FF) {
          hasCleanArabic = true;
          break; // ALREADY HAS CLEAN ARABIC
        }
        // Corruption often manifests as these characters in UTF-8 mismatch
        if ((code >= 0xC2 && code <= 0xC3) || code == 0x2020 || code == 0x201A) {
           hasCorruptionMarkers = true;
        }
      }

      if (hasCleanArabic) {
        skippedCleanCount++;
        return s;
      }

      if (!hasCorruptionMarkers) {
        untouchedCount++;
        return s;
      }

      try {
        final bytes = latin1.encode(s);
        final repaired = utf8.decode(bytes);
        fixedCount++;
        return repaired;
      } catch (e) {
        return s;
      }
    }

    void processValue(dynamic val) {
      if (val is List) {
        for (var i = 0; i < val.length; i++) {
          final item = val[i];
          if (item is String) {
             val[i] = repairString(item);
          } else {
             processValue(item);
          }
        }
      } else if (val is Map) {
        val.forEach((k, v) {
          if (v is String) {
            val[k] = repairString(v);
          } else {
            processValue(v);
          }
        });
      }
    }

    processValue(data);

    file.writeAsStringSync(JsonEncoder.withIndent('  ').convert(data), flush: true);
    print("  Done. Fixed: $fixedCount, Skipped Clean: $skippedCleanCount, Untouched: $untouchedCount");
  }
}
