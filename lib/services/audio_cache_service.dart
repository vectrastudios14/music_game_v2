import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class MediaCacheService {
  // Singleton instance
  static final MediaCacheService _instance = MediaCacheService._internal();
  factory MediaCacheService() => _instance;
  MediaCacheService._internal();

  Directory? _cacheDir;

  /// Initialize the cache directory
  Future<void> init() async {
    if (_cacheDir != null) return;
    final tempDir = await getTemporaryDirectory();
    _cacheDir = Directory('${tempDir.path}/game_media_cache'); // Renamed folder
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
  }

  /// Returns the local file path if cached, otherwise returns null
  String? getCachedPath(String url) {
    if (_cacheDir == null) return null;
    final fileName = _getFileNameFromUrl(url);
    final file = File('${_cacheDir!.path}/$fileName');
    if (file.existsSync()) {
      return file.path;
    }
    return null;
  }

  /// Downloads and caches a file (Audio or Image). Returns the local path.
  Future<String?> cacheFile(String url) async {
    try {
      if (_cacheDir == null) await init();

      final fileName = _getFileNameFromUrl(url);
      final file = File('${_cacheDir!.path}/$fileName');

      // If already exists, return path
      if (await file.exists()) {
        return file.path;
      }

      // Download
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        debugPrint('MEDIA CACHE: Cached $fileName');
        return file.path;
      } else {
        debugPrint('MEDIA CACHE: Failed to download $url - ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('MEDIA CACHE: Error caching file: $e');
      return null;
    }
  }

  /// Clears all cached files
  Future<void> clearCache() async {
    try {
      if (_cacheDir != null && await _cacheDir!.exists()) {
        await _cacheDir!.delete(recursive: true);
        debugPrint('MEDIA CACHE: Cache cleared');
        _cacheDir = null; 
        // Re-initialize immediately or on next needed call?
        // Better to just null it. Next `init()` call will recreate.
      }
    } catch (e) {
      debugPrint('MEDIA CACHE: Error clearing cache: $e');
    }
  }



  String _getFileNameFromUrl(String url) {
    // secure filename from url using MD5 hash to prevent collisions
    // (iTunes URLs often same filename but different paths)
    final bytes = utf8.encode(url);
    final digest = md5.convert(bytes);
    final ext = url.split('.').last.split('?').first; // simple extension extraction
    // default to .jpg or .mp3 if extension is weird or long? 
    // actually, just keeping the extension is safer for Image widgets.
    
    // Clean extension
    String extension = 'tmp';
    if (ext.length <= 4 && RegExp(r'^[a-zA-Z0-9]+$').hasMatch(ext)) {
       extension = ext;
    }
    
    return '${digest.toString()}.$extension';
  }
}
