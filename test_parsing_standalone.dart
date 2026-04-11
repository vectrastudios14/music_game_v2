
import 'dart:convert';
import 'dart:io';

// COPY OF Song Model
class Song {
  final String id;
  final String title;
  final String artist;
  final String? titleAr;
  final String? artistAr;
  final String link;
  final String year;
  final List<String> styles;
  final List<String> facts;

  String? artworkUrl;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    this.titleAr,
    this.artistAr,
    required this.link,
    required this.year,
    required this.styles,
    this.artworkUrl,
    this.facts = const [],
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    try {
      return Song(
        id: json['id'] as String,
        title: json['title'] as String,
        artist: json['artist'] as String,
        titleAr: json['titleAr'] as String?,
        artistAr: json['artistAr'] as String?,
        link: json['link'] as String,
        year: json['year'] as String,
        styles: (json['styles'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        artworkUrl: json['artworkUrl'] as String?,
        facts: (json['facts'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ?? [],
      );
    } catch (e) {
      print("Error parsing song ${json['id']}: $e");
      rethrow;
    }
  }
}

void main() {
  testFile('assets/songs.json');
  testFile('assets/songs_arabic.json');
}

void testFile(String path) {
  print('Testing $path...');
  try {
    final file = File(path);
    if (!file.existsSync()) {
      print('File not found: $path');
      return;
    }
    final content = file.readAsStringSync();
    final List<dynamic> data = json.decode(content);
    print('JSON decode success. Items: ${data.length}');

    final songs = data.map((j) => Song.fromJson(j)).toList();
    print('Parsing success. Songs: ${songs.length}');
    
    // Test Auth Check
    final valid = songs.where((s) => s.link.isNotEmpty && s.link.startsWith('http')).toList();
    print('After AuthCheck: ${valid.length}');

  } catch (e) {
    print('FAILED: $e');
  }
}
