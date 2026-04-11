import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const String rawText = r"""
خاينه
راشد الماجد
جلسات وناسة 2009
8:40
لا خبر (Live)
راشد الماجد
جلسات وناسة 2010 (Live)
8:28

محلا اللقى
ماجد المهندس
محلا اللقى
4:29
خلاص
رابح صقر
رابح 2017, Vol. 1 & 2
4:10
""";
// I'll put the FULL TEXT back in the real script later.

class SongInfo {
  final String title;
  final String artist;
  SongInfo(this.title, this.artist);
}

Future<void> main() async {
  print("DEBUG SEARCH WITH USER-AGENT...");

  final rawLines = rawText.split('\n').map((l) => l.trim()).toList();
  List<SongInfo> songs = [];
  int i = 0;
  while (i < rawLines.length) {
    if (rawLines[i].isEmpty) { i++; continue; }
    String title = rawLines[i];
    String artist = (i + 1 < rawLines.length) ? rawLines[i+1] : "";
    if (title.isNotEmpty && artist.isNotEmpty) {
      songs.add(SongInfo(title, artist));
    }
    i += 4;
  }

  var httpClient = http.Client();
  final headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
  };

  for (var song in songs) {
    print("\nSearching for: ${song.artist} - ${song.title}");
    final query = "${song.artist} ${song.title}";
    final uri = Uri.parse("https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&limit=1&media=music&entity=song");
    
    try {
      final response = await httpClient.get(uri, headers: headers);
      print("Status: ${response.statusCode}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Result Count: ${data['resultCount']}");
        if (data['resultCount'] > 0) {
          print("Found Match: ${data['results'][0]['trackName']}");
        }
      }
    } catch (e) {
      print("Error: $e");
    }
  }
  httpClient.close();
}
