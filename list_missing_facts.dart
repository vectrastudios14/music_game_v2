import 'dart:convert';
import 'dart:io';

void main() async {
  final songsFile = File('assets/songs.json');
  final content = await songsFile.readAsString();
  final List<dynamic> songs = json.decode(content);
  
  final outFile = File('missing_facts_list.txt');
  final sb = StringBuffer();
  
  int missingCount = 0;
  for (var s in songs) {
    if (s['facts'] == null || s['facts'].toString().isEmpty) {
      sb.writeln('${s['id']}|${s['title']}|${s['artist']}');
      missingCount++;
    }
  }
  await outFile.writeAsString(sb.toString());
  print('Wrote $missingCount songs to missing_facts_list.txt');
}
