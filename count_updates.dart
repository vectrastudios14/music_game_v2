import 'dart:io';
import 'dart:convert';

void main() {
  final f1 = File('assets/songs_arabic.json');
  final f2 = File('assets/songs_arabic.json.bak');
  
  if (!f1.existsSync()) {
    print("f1 missing");
    return;
  }
  
  final s1 = f1.readAsStringSync();
  final c1 = "Discogs".allMatches(s1).length;
  
  int c2 = -1;
  if (f2.existsSync()) {
    final s2 = f2.readAsStringSync();
    c2 = "Discogs".allMatches(s2).length;
  }
  
  print("COUNTS: Current=$c1, Backup=$c2");
  
  // Also check for null artworkUrl
  final list1 = json.decode(s1) as List;
  int missingArt = 0;
  for (var song in list1) {
    if (song['artworkUrl'] == null || song['artworkUrl'] == "") {
      missingArt++;
    }
  }
  print("MISSING ART: $missingArt");
}
