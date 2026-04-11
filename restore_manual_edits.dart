import 'dart:io';
import 'dart:convert';

void main() {
  final backupFile = File('manual_edits_safety_backup.json');
  if (!backupFile.existsSync()) {
    print("Backup file not found.");
    return;
  }

  final List<dynamic> backupData = json.decode(backupFile.readAsStringSync());
  final Map<String, List<Map<String, dynamic>>> byFile = {};

  for (final edit in backupData) {
    final file = edit['source_file'] as String;
    byFile.putIfAbsent(file, () => []).add(edit as Map<String, dynamic>);
  }

  byFile.forEach((filePath, edits) {
    print("Restoring ${edits.length} edits to $filePath...");
    final file = File(filePath);
    if (!file.existsSync()) {
      print("  Warning: Target file $filePath not found. Skipping.");
      return;
    }

    final List<dynamic> currentSongs = json.decode(file.readAsStringSync());
    int restoredCount = 0;

    for (final edit in edits) {
      final id = edit['id'];
      final targetIndex = currentSongs.indexWhere((s) => s['id'] == id);
      
      if (targetIndex != -1) {
        // Restore artworkUrl
        currentSongs[targetIndex]['artworkUrl'] = edit['artworkUrl'];
        restoredCount++;
      }
    }

    file.writeAsStringSync(JsonEncoder.withIndent('  ').convert(currentSongs), flush: true);
    print("  Successfully restored $restoredCount edits to $filePath.");
  });
}
