import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  print("TITLE ONLY + SAFARI AGENT...");
  
  // Try searching for just the Arabic title "خاينه" (Khayna)
  final queries = ["خاينه", "محلا اللقى", "ترا حقي"];
  
  final headers = {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.1 Safari/605.1.15'
  };

  for (var query in queries) {
    print("\nQuery: $query");
    final uri = Uri.https('itunes.apple.com', '/search', {
      'term': query,
      'limit': '5',
      'media': 'music'
    });
    
    try {
      final response = await http.get(uri, headers: headers);
      print("Status: ${response.statusCode}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Result Count: ${data['resultCount']}");
        for (var r in data['results']) {
          print("- ${r['trackName']} by ${r['artistName']} (${r['releaseDate']})");
        }
      }
    } catch (e) {
      print("Error: $e");
    }
  }
}
