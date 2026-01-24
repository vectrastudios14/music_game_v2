import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/song.dart';
import 'dart:math';
import 'dart:math';
// import 'itunes_service.dart'; // DETOX
// import 'audio_cache_service.dart'; // DETOX

class Question {
  final Song correctSong;
  final List<Song> options;

  Question({required this.correctSong, required this.options});
}

class SongRepository {
  static final SongRepository _instance = SongRepository._internal();
  factory SongRepository() => _instance;
  SongRepository._internal();

  List<Song> _songs = [];

  // Caching for Pre-loading
  Question? cachedNextQuestion;
  List<Song>? cachedDeck;

  List<Song> get allSongs => List.unmodifiable(_songs);

  Future<void> loadSongs() async {
    if (_songs.isNotEmpty) return;

    try {
      final String response = await rootBundle.loadString('assets/songs.json');
      final List<dynamic> data = json.decode(response);
      
      _songs = data.map((json) => Song.fromJson(json)).toList();
      
      // Filter out songs with broken links if any
      _songs = _songs.where((s) => s.link.isNotEmpty && s.link.startsWith('http')).toList();

      print('Loaded ${_songs.length} songs from JSON.');
    } catch (e) {
      print('Error loading songs from JSON: $e');
      // Fallback to empty or simple debug if JSON fails entirely
      _songs = [];
    }
  }

  // Filter helpers
  List<Song> getSongsByYear(String year) {
    return _songs.where((s) => s.year == year).toList();
  }
  
  List<Song> getValidSongs() {
    // Only return songs with valid iTunes links if needed
    return _songs.where((s) => s.link.contains('http')).toList();
  }

  Future<Question> getNextQuestion(List<Song> history) async {
    final availableSongs = _songs.where((s) => !history.contains(s) && s.link.contains('http')).toList();
    if (availableSongs.isEmpty) {
      throw Exception('No more songs available');
    }

    final random = Random();
    final correctSong = availableSongs[random.nextInt(availableSongs.length)];

    // Smart Distractors Logic
    // 1. Same Era (+/- 5 years)
    // 2. Same Genre (Style overlap)
    final correctYear = int.tryParse(correctSong.year) ?? 1980;
    
    // Filter potential distractors (exclude correct song)
    // Prioritize same decade and genre
    var distractors = _songs.where((s) => s.id != correctSong.id).toList();
    
    // Attempt strict filtering
    var strictDistractors = distractors.where((s) {
      final year = int.tryParse(s.year) ?? 0;
      final yearMatch = (year - correctYear).abs() <= 5;
      final styleMatch = s.styles.any((style) => correctSong.styles.contains(style));
      return yearMatch && styleMatch;
    }).toList();

    List<Song> selectedDistractors = [];

    if (strictDistractors.length >= 3) {
      strictDistractors.shuffle();
      selectedDistractors = strictDistractors.take(3).toList();
    } else {
      // Relax: Just Era match
      var eraDistractors = distractors.where((s) {
        final year = int.tryParse(s.year) ?? 0;
        return (year - correctYear).abs() <= 5;
      }).toList();
      
      if (eraDistractors.length >= 3) {
        eraDistractors.shuffle();
        selectedDistractors = eraDistractors.take(3).toList();
      } else {
        // Fallback: Random
        distractors.shuffle();
        selectedDistractors = distractors.take(3).toList();
      }
    }

    // Combine and Shuffle Options
    final options = [correctSong, ...selectedDistractors]..shuffle();

    // Fetch Artwork for ALL options in parallel
    // await Future.wait(options.map((song) async {
    //   if (song.artworkUrl == null) {
    //     final url = await ITunesService.fetchArtwork(song.artist, song.title);
    //     if (url != null) {
    //       song.artworkUrl = url;
    //     }
    //   }
    // }));

    return Question(correctSong: correctSong, options: options);
  }

  // --- PRE-LOADING HELPERS ---

  // NATIVE METHODS STUBBED FOR DETOX
  Future<void> prepareFirstRoundGTS() async {
     print("Repo: prepareFirstRoundGTS (STUBBED)");
  }

  Future<void> prepareDeck({int playerCount = 2}) async {
     print("Repo: prepareDeck (STUBBED)");
     // Should we load songs at least?
     if (_songs.isEmpty) await loadSongs();
     
     // Create a fresh deck for the game to grab later
     // In the real version, we cached it. Here we just ensure songs exist.
     // cacheDeck is used by BoaGameScreen to get the same shuffled deck.
     
     final deck = getValidSongs()..shuffle();
     cachedDeck = deck; 
  }
}
