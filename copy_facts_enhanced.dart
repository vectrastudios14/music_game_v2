import 'dart:convert';
import 'dart:io';

void main() async {
  final songsFile = File('assets/songs.json');
  final songsContent = await songsFile.readAsString();
  final List<dynamic> songsJson = json.decode(songsContent);
  
  // Store source facts. keys: artist -> list of {title, fact}
  final Map<String, List<Map<String, String>>> artistSongs = {};
  int sourceCount = 0;

  for (var s in songsJson) {
    if (s['facts'] != null && s['facts'].toString().isNotEmpty) {
      final artist = s['artist'].toString().toLowerCase().trim();
      final title = s['title'].toString().toLowerCase().trim();
      
      artistSongs.putIfAbsent(artist, () => []);
      artistSongs[artist]!.add({
        'title': title,
        'fact': s['facts'],
        'originalTitle': s['title'] // for debugging
      });
      sourceCount++;
    }
  }

  print('Source facts available: $sourceCount');

  int updatedCount = 0;
  final List<Map<String, dynamic>> updatedSongs = songsJson.map((s) {
    final Map<String, dynamic> song = s as Map<String, dynamic>;
    
    if (song['facts'] == null || song['facts'].toString().isEmpty) {
      final artist = song['artist'].toString().toLowerCase().trim();
      final title = song['title'].toString().toLowerCase().trim();
      
      if (artistSongs.containsKey(artist)) {
        // Look for a matching title in the source list for this artist
        for (var source in artistSongs[artist]!) {
          final sourceTitle = source['title']!;
          
          // Match if one contains the other
          // e.g. "Piano Man" matches "Piano Man (Live)"
          // e.g. "I'm Like A Bird" matches "I'm Like A Bird"
          
          // Avoid matching short generic words if possible, but song titles are usually distinctive.
          // Also check similarity? Contains is usually safe for "Remaster" "Radio Edit" suffixes.
          
          if (title == sourceTitle || 
              title.contains(sourceTitle) || 
              sourceTitle.contains(title)) {
            
             // Verification: Make sure it's not a false positive like "Love" matching "Love Me Do"
             // Ensure the match length is significant relative to the shorter string
             int shorterLen = title.length < sourceTitle.length ? title.length : sourceTitle.length;
             if (shorterLen > 3) {
                 song['facts'] = source['fact'];
                 updatedCount++;
                 break; // Found a match, stop looking for this song
             }
          }
        }
      }
    }
    return song;
  }).toList();

  await songsFile.writeAsString(json.encode(updatedSongs));
  print('Enhanced copy: Updated $updatedCount songs.');
}
