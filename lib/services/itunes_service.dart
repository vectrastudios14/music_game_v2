import 'dart:convert';
import 'package:http/http.dart' as http;

class ITunesService {
  static const String _baseUrl = 'https://itunes.apple.com/search';

  /// Fetches the artwork URL for a given song.
  /// Returns a high-resolution URL (600x600) if found, otherwise null.
  static Future<String?> fetchArtwork(String artist, String title) async {
    final metadata = await fetchMetadata(artist, title);
    return metadata?['artworkUrl'];
  }

  /// Fetches metadata (artwork, year) for a given song.
  static Future<Map<String, dynamic>?> fetchMetadata(String artist, String title) async {
    try {
      final query = '$artist $title';
      final url = Uri.parse('$_baseUrl?term=${Uri.encodeComponent(query)}&media=music&limit=1');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['resultCount'] > 0) {
          final result = data['results'][0];
          String? artworkUrl = result['artworkUrl100'];
          String? releaseDate = result['releaseDate']; // Format: 1978-11-10T08:00:00Z
          String? year;
          
          if (releaseDate != null && releaseDate.length >= 4) {
            year = releaseDate.substring(0, 4);
          }

          // Upgrade to high-res (600x600)
          if (artworkUrl != null) {
            artworkUrl = artworkUrl.replaceAll('100x100', '600x600');
          }
          
          return {
            'artworkUrl': artworkUrl,
            'year': year,
          };
        }
      }
    } catch (e) {
      print('Error fetching metadata for $artist - $title: $e');
    }
    return null;
  }
}
