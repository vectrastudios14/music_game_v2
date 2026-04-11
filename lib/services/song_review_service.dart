import 'dart:convert';
import 'dart:io';
import '../models/song.dart';

class SongReviewService {
  // USING ABSOLUTE PATHS ensures we write to the Source File, not the Build/Asset copy
  final String _englishPath = r'C:\Users\kishi\OneDrive\Documents\music_game_v2\assets\songs.json';
  final String _arabicPath = r'C:\Users\kishi\OneDrive\Documents\music_game_v2\assets\songs_arabic.json';

  Future<List<Song>> loadSongs(String libraryType) async {
    final path = libraryType == 'arabic' ? _arabicPath : _englishPath;
    final file = File(path);

    if (!await file.exists()) {
      return [];
    }

    final content = await file.readAsString();
    final List<dynamic> jsonList = json.decode(content);
    return jsonList.map((json) => Song.fromJson(json)).toList();
  }

  Future<bool> saveSong(String libraryType, Song updatedSong, {int? index}) async {
    final path = libraryType == 'arabic' ? _arabicPath : _englishPath;
    final file = File(path);
    
    if (!await file.exists()) return false;

    final content = await file.readAsString();
    final List<dynamic> jsonList = json.decode(content);
    
    // Convert to List<Map> to preserve ALL fields, even those not in the Song model
    final List<Map<String, dynamic>> rawSongs = List<Map<String, dynamic>>.from(jsonList);

    int targetIndex = -1;

    // 1. Try find by index first (if valid)
    if (index != null && index >= 0 && index < rawSongs.length) {
      if (rawSongs[index]['id'] == updatedSong.id) {
        targetIndex = index;
      }
    }

    // 2. Fallback to searching by ID
    if (targetIndex == -1) {
      targetIndex = rawSongs.indexWhere((s) => s['id'] == updatedSong.id);
    }

    if (targetIndex != -1) {
      final existingMap = rawSongs[targetIndex];
      final updateData = updatedSong.toJson();
      
      // Update fields from the tool while preserving everything else
      updateData.forEach((key, value) {
        existingMap[key] = value;
      });
      
      return _safeWrite(path, rawSongs);
    }
    
    return false;
  }

  Future<bool> deleteSong(String libraryType, String link) async {
    final path = libraryType == 'arabic' ? _arabicPath : _englishPath;
    final file = File(path);
    if (!await file.exists()) return false;

    final content = await file.readAsString();
    final List<dynamic> jsonList = json.decode(content);
    final songs = jsonList.map((json) => Song.fromJson(json)).toList();

    songs.removeWhere((s) => s.link == link);
    return _safeWrite(path, songs);
  }

  Future<bool> addSong(String libraryType, Song newSong) async {
    return batchAddSongs(libraryType, [newSong]);
  }

  Future<bool> batchAddSongs(String libraryType, List<Song> newSongs) async {
    final path = libraryType == 'arabic' ? _arabicPath : _englishPath;
    final file = File(path);
    
    List<Song> songs = [];
    if (await file.exists()) {
      final content = await file.readAsString();
      final List<dynamic> jsonList = json.decode(content);
      songs = jsonList.map((json) => Song.fromJson(json)).toList();
    }

    songs.addAll(newSongs);
    return _safeWrite(path, songs);
  }

  /// Implements a robust write pattern:
  /// 1. Serialize to String
  /// 2. Create backup (.bak)
  /// 3. Write to Temp (.tmp)
  /// 4. Rename Temp to Target
  /// 5. Retry logic for file locks
  Future<bool> _safeWrite(String path, List<dynamic> data) async {
    final file = File(path);
    final backup = File('$path.bak');
    final tmp = File('$path.tmp');
    
    try {
      final jsonList = data.map((item) {
        if (item is Song) return item.toJson();
        return item; // Assume it's a Map already
      }).toList();

      final jsonString = JsonEncoder.withIndent('  ').convert(jsonList);
      
      int retries = 3;
      while (retries > 0) {
        try {
          // 1. Backup existing
          if (await file.exists()) {
            if (await backup.exists()) await backup.delete();
            await file.copy(backup.path);
          }

          // 2. Write temp
          await tmp.writeAsString(jsonString, flush: true);

          // 3. Move temp to target
          if (await file.exists()) await file.delete();
          await tmp.rename(path);

          // 4. Verification Check
          final verifyContent = await file.readAsString();
          final List<dynamic> verifyJson = json.decode(verifyContent);
          if (verifyJson.length == data.length) {
            return true;
          } else {
             throw Exception("Verification failed: Count mismatch (Disk: ${verifyJson.length}, Expected: ${data.length})");
          }
        } catch (e) {
          retries--;
          if (retries == 0) rethrow;
          await Future.delayed(Duration(milliseconds: 500 * (3 - retries)));
        }
      }
    } catch (e) {
      print("SafeWrite Fatal Error: $e");
      // If we failed and backup exists, try to restore? No, better let user know.
    }
    return false;
  }
}
