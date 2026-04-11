import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart update_facts.dart <facts_json_file>');
    return;
  }

  final factsPath = args[0];
  final factsFile = File(factsPath);

  if (!await factsFile.exists()) {
    print('Facts file not found: $factsPath');
    return;
  }

  final factsContent = await factsFile.readAsString();
  final Map<String, dynamic> factsMap = json.decode(factsContent);

  final songsPath = 'assets/songs.json';
  final songsFile = File(songsPath);

  if (!await songsFile.exists()) {
    print('Songs file not found: $songsPath');
    return;
  }

  final songsContent = await songsFile.readAsString();
  final List<dynamic> songsJson = json.decode(songsContent);
  
  int updatedCount = 0;

  final List<Map<String, dynamic>> updatedSongs = songsJson.map((s) {
    final Map<String, dynamic> song = s as Map<String, dynamic>;
    if (factsMap.containsKey(song['id'])) {
      song['facts'] = factsMap[song['id']];
      updatedCount++;
    }
    return song;
  }).toList();

  await songsFile.writeAsString(json.encode(updatedSongs));
  print('Successfully updated facts for $updatedCount songs.');
}
