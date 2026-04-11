import 'dart:convert';
import 'dart:io';

void main() async {
  final songsFile = File('assets/songs.json');
  final content = await songsFile.readAsString();
  final List<dynamic> songs = json.decode(content);
  
  int missingCount = 0;
  for (var s in songs) {
    if (s['facts'] == null || s['facts'].toString().isEmpty) {
      missingCount++;
      // Print first 5 missing to see what they are
      if (missingCount <= 5) {
        print('Missing fact: ${s['id']} - ${s['title']} by ${s['artist']}');
      }
    }
  }
  print('Total songs with missing facts: $missingCount out of ${songs.length}');
}
