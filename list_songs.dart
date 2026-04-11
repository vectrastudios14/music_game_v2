import 'dart:convert';
import 'dart:io';

void main() async {
  try {
    final file = File('assets/songs.json');
    if (!await file.exists()) {
      print('File not found');
      return;
    }
    final content = await file.readAsString();
    final List<dynamic> songs = json.decode(content);
    final outFile = File('songs_plain.txt');
    final sb = StringBuffer();
    sb.writeln('Total songs: ${songs.length}');
    for (var song in songs) {
      sb.writeln('${song['id']}|${song['title']}|${song['artist']}');
    }
    await outFile.writeAsString(sb.toString(), encoding: utf8);
    print('Done writing to songs_plain.txt');
  } catch (e) {
    print('Error: $e');
  }
}
