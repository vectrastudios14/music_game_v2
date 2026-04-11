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

ترا حقي
داليا
ترا حقي
6:04

Wallah Ma Yermesh
Ayed
Wallah Ma Yermesh
4:42

خلص حنانك
عبدالمجيد عبدالله
عبد المجيد عبد الله 2011
5:54

Ma Arda Aaleh
Jaber Al Kaser
Beda Yetghayar
5:01

Al Hob Al Awal (feat. Abdul Majeed Abdullah)
Rashed Al Majed
Honey Rashed
6:29
أبشر من عيوني
راشد الماجد
حفلة دبي 2016
6:12

La Tekhaf
Assala
Sawaha Qalbi
5:15

Ketha Momken
Dalia
Ketha Momken
4:44

Walhan
Rashed Al Majed
Walhan
5:33

مكانك مبين
نوال الكويتية
الحنين
3:50

Ya Bad Haldinya Leh
Rashed AlMajid
Ala Meen Telabha
4:15

حضرة الموقف
Assala Nasri
4:41

Btewsefni Bteksefni
Angham
Hala Khasa Gedan
4:28

نوال - انت طيب  (جلسات  وناسه) | 2017
 Tunes Arabia l تيونز أرابيا
5:13

نوال - خذاني الشوق (جلسات  وناسه) | 2017
 Tunes Arabia l تيونز أرابيا
5:19
عشيري
راشد الماجد
حفلة دبي 2016
6:05
يوجعونك
انغام
راح تذكرني
4:49
محتاجك
ماجد المهندس
إنسى
4:58

Talabtk
Assala
Sawaha Qalbi
6:17

الحب الكبير
Majed Al Mohandes 
 & 
Dalia Mubarak
الحب الكبير
8:21

الظروف
اصيل هميم
الظروف
6:08

Sehyswy
Rashed Al Majed
شيسوي
4:13

Yhizak Al Shooq
Majid al Muhandis
Yhizak Al Shooq
4:12

Enta Kolshay
Aseel Hameem
Enta Kolshay
4:49

كان ودي
داليا
كان ودي
5:17

نحن هنا
شمه حمدان
نحن هنا
5:10

Hanet Aliek
Abdul Majeed Abdullah
Hanet Aliek
4:58

بيني وبينك
داليا و اسماعيل مبارك
بيني وبينك
5:34

درب المضيع
داليا
درب المضيع
3:29
طيبة
شيما هلالي
بتقوم
4:22
""";

class SongInfo {
  final String title;
  final String artist;
  SongInfo(this.title, this.artist);
}

Future<void> main() async {
  print("BATCH IMPORT (First 30)...");

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

  print("Parsed ${songs.length} songs. Starting searches with 1s delay...");

  List<Map<String, dynamic>> results = [];
  var httpClient = http.Client();
  final headers = {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.1 Safari/605.1.15'
  };

  for (var song in songs) {
    print("\n[${results.length + 1}] Searching: ${song.title}...");
    final query = "${song.artist} ${song.title}";
    final uri = Uri.https('itunes.apple.com', '/search', {
      'term': query,
      'limit': '1',
      'media': 'music',
      'entity': 'song'
    });
    
    try {
      final response = await httpClient.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['resultCount'] > 0) {
          final m = data['results'][0];
          print("  Found: ${m['trackName']}");
          results.add({
            "id": "new_${m['trackId']}",
            "title": song.title,
            "artist": song.artist,
            "year": m['releaseDate'].toString().substring(0, 4),
            "link": m['previewUrl'],
            "artworkUrl": m['artworkUrl100'].replaceAll('100x100bb', '600x600bb'),
            "styles": ["Arabic Pop"]
          });
        } else {
          print("  No match found.");
        }
      } else {
        print("  Error: ${response.statusCode}");
      }
    } catch (e) {
      print("  Exception: $e");
    }
    await Future.delayed(Duration(seconds: 1));
  }

  httpClient.close();
  print("\nBatch Complete. Found ${results.length} songs.");
  final file = File('found_batch_1.json');
  await file.writeAsString(JsonEncoder.withIndent('  ').convert(results));
  print("Saved to found_batch_1.json");
}
