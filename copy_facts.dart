import 'dart:convert';
import 'dart:io';

void main() async {
  final songsFile = File('assets/songs.json');

  if (!await songsFile.exists()) {
    print('Songs file not found');
    return;
  }

  final songsContent = await songsFile.readAsString();
  final List<dynamic> songsJson = json.decode(songsContent);
  
  // Create a dictionary of facts from songs that have them
  // Key: "Title|Artist" (lowercase for better matching)
  final Map<String, String> factsMap = {};
  int sourceCount = 0;

  for (var s in songsJson) {
    if (s['facts'] != null && s['facts'].toString().isNotEmpty) {
      final key = "${s['title'].toString().toLowerCase().trim()}|${s['artist'].toString().toLowerCase().trim()}";
      factsMap[key] = s['facts'];
      sourceCount++;
    }
  }

  print('Found $sourceCount songs with facts to use as source.');

  int updatedCount = 0;
  final List<Map<String, dynamic>> updatedSongs = songsJson.map((s) {
    final Map<String, dynamic> song = s as Map<String, dynamic>;
    
    // If song has no facts, try to find a match
    if (song['facts'] == null || song['facts'].toString().isEmpty) {
      final key = "${song['title'].toString().toLowerCase().trim()}|${song['artist'].toString().toLowerCase().trim()}";
      
      if (factsMap.containsKey(key)) {
        song['facts'] = factsMap[key];
        updatedCount++;
      }
    }
    return song;
  }).toList();

  await songsFile.writeAsString(json.encode(updatedSongs));
  print('Successfully copied facts to $updatedCount matching songs in extended library.');
}
