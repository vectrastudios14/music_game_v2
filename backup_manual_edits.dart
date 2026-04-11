import 'dart:io';
import 'dart:convert';

void main() {
  final files = ['assets/songs_arabic.json', 'assets/songs.json'];
  final Map<String, Map<String, dynamic>> manualEdits = {};

  for (final path in files) {
    print("Checking $path...");
    final file = File(path);
    if (!file.existsSync()) continue;

    final content = file.readAsStringSync();
    final List<dynamic> songs = json.decode(content);

    for (final song in songs) {
      final id = song['id'];
      final artwork = song['artworkUrl'] as String?;
      
      // We consider it a "manual edit" if it doesn't point to iTunes
      bool isManual = false;
      if (artwork != null && !artwork.contains('mzstatic.com') && artwork.isNotEmpty) {
        isManual = true;
      }

      // You can add more rules here (e.g. check for custom facts)

      if (isManual) {
        manualEdits[id] = {
          'id': id,
          'artworkUrl': artwork,
          'source_file': path,
        };
      }
    }
  }

  if (manualEdits.isEmpty) {
    print("No manual edits found to backup.");
    return;
  }

  final backupFile = File('manual_edits_safety_backup.json');
  backupFile.writeAsStringSync(JsonEncoder.withIndent('  ').convert(manualEdits.values.toList()));
  print("Saved ${manualEdits.length} manual edits to ${backupFile.path}");
}
