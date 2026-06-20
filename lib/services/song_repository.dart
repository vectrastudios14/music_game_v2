import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/song.dart';
import 'dart:math';
import 'dart:math';
import 'itunes_service.dart'; // DETOX
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
  String _currentLibrary = 'assets/songs.json';

  // Caching for Pre-loading
  Question? cachedNextQuestion;
  List<Song>? cachedDeck;

  List<Song> get allSongs => List.unmodifiable(_songs);

  Future<void> loadSongs({String? libraryPath}) async {
    final targetLibrary = libraryPath ?? _currentLibrary;
    
    // If we're already loaded with this library, skip (unless forced)
    if (_songs.isNotEmpty && _currentLibrary == targetLibrary && libraryPath == null) return;

    if (targetLibrary == 'mix') {
       await _loadMixedLibrary();
       return;
    }

    try {
      print('Repo: Loading songs from $targetLibrary...');
      final String response = await rootBundle.loadString(targetLibrary);
      final List<dynamic> data = json.decode(response);
      
      _songs = data.map((json) => Song.fromJson(json)).toList();
      _authCheck(); // Filter valid songs

      print('Repo: Loaded ${_songs.length} songs from $targetLibrary.');
    } catch (e) {
      print('Repo: Error loading songs from $targetLibrary: $e');
      if (_songs.isEmpty) _songs = [];
    }
  }

  Future<void> _loadMixedLibrary() async {
    try {
      print('Repo: Loading MIXED library...');
      
      // Load English
      final String resEng = await rootBundle.loadString('assets/songs.json');
      final List<dynamic> dataEng = json.decode(resEng);
      final songsEng = dataEng.map((json) => Song.fromJson(json)).toList();

      // Load Arabic
      final String resAra = await rootBundle.loadString('assets/songs_arabic.json');
      final List<dynamic> dataAra = json.decode(resAra);
      final songsAra = dataAra.map((json) => Song.fromJson(json)).toList();

      // Combine
      _songs = [...songsEng, ...songsAra];
      _currentLibrary = 'mix';
      _authCheck();

      print('Repo: Loaded MIXED library with ${_songs.length} songs.');
    } catch (e) {
      print('Repo: Error loading mixed library: $e');
      _songs = [];
    }
  }

  void _authCheck() {
     _songs = _songs.where((s) => s.link.isNotEmpty && s.link.startsWith('http')).toList();
  }

  void setLibrary(String type) {
    if (type == 'arabic') {
      _currentLibrary = 'assets/songs_arabic.json';
    } else if (type == 'mix') {
      _currentLibrary = 'mix'; // Special flag
    } else {
      _currentLibrary = 'assets/songs.json';
    }
    _songs = []; // Clear current songs to force reload
  }

  String get currentLibraryType {
    if (_currentLibrary == 'mix') return 'mix';
    return _currentLibrary.contains('arabic') ? 'arabic' : 'english';
  }

  // Filter helpers
  List<Song> getSongsByYear(String year) {
    return _songs.where((s) => s.year == year).toList();
  }
  
  List<Song> getValidSongs() {
    // Only return songs with valid iTunes links if needed
    return _songs.where((s) => s.link.contains('http')).toList();
  }

  Future<Question> getNextQuestion(List<Song> history, {bool forceUniqueArtists = false, int distractorCount = 3}) async {
    final availableSongs = _songs.where((s) => !history.contains(s) && s.link.contains('http')).toList();
    if (availableSongs.isEmpty) {
      throw Exception('No more songs available');
    }

    final random = Random();
    final correctSong = availableSongs[random.nextInt(availableSongs.length)];

    // --- NEW SMART DISTRACTOR LOGIC ---
    
    double calculateSimilarity(Song a, Song b) {
      double score = 0;
      
      // 1. Year Similarity (Higher is better)
      int yearA = int.tryParse(a.year) ?? 1980;
      int yearB = int.tryParse(b.year) ?? 1980;
      int yearDiff = (yearA - yearB).abs();
      
      if (yearDiff == 0) score += 4.0;
      else if (yearDiff <= 1) score += 3.0;
      else if (yearDiff <= 3) score += 2.0;
      else if (yearDiff <= 5) score += 1.0;
      else if (yearDiff <= 10) score += 0.5;

      // 2. Style/Genre Match
      int overlap = a.styles.where((s) => b.styles.contains(s)).length;
      score += overlap * 2.5; 

      // 3. Same Artist (Extra difficulty)
      if (a.artist == b.artist) score += 5.0;

      // 4. Gender Match (Highest difficulty factor)
      if (a.gender != null) {
        if (b.gender == null) {
          score -= 10.0; // Penalty for unknown distractor gender when correct is known
        } else if (a.gender == b.gender) {
          score += 15.0; // Boost for matching gender
        } else {
          score -= 30.0; // Massive penalty for mismatch
        }
      } else if (b.gender != null) {
         score -= 5.0; // Slight penalty for known distractor if correct is unknown
      }

      // 5. Same Decade
      if (yearA ~/ 10 == yearB ~/ 10) score += 1.0;

      return score;
    }

    // Filter potential distractors
    var potentialDistractors = _songs.where((s) => s.id != correctSong.id).toList();

    // Map all distractors to their scores
    var scoredDistractors = potentialDistractors.map((s) => {
      'song': s,
      'score': calculateSimilarity(correctSong, s)
    }).toList();

    // Sort by score descending
    scoredDistractors.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    // Select distractors:
    final int poolSize = min(15, scoredDistractors.length);
    var difficultPool = scoredDistractors.take(poolSize).toList();
    difficultPool.shuffle();

    String normalizeArtistName(String name) {
      String text = name.trim().toLowerCase();
      text = text
          .replaceAll(RegExp(r'[أإآ]'), 'ا')
          .replaceAll('ة', 'ه')
          .replaceAll('ى', 'ي')
          .replaceAll(RegExp(r'[\u064B-\u0652]'), '');
      return text;
    }

    List<Song> selectedDistractors = [];
    final String resolvedCorrectArtist = normalizeArtistName(currentLibraryType == 'arabic'
        ? (correctSong.artistAr ?? correctSong.artist)
        : correctSong.artist);

    final Set<String> selectedTitles = {correctSong.title.trim().toLowerCase()};
    final Set<String> usedArtists = {
      normalizeArtistName(correctSong.artist),
      resolvedCorrectArtist,
      if (correctSong.artistAr != null) normalizeArtistName(correctSong.artistAr!)
    };

    for (var entry in difficultPool) {
       final s = entry['song'] as Song;
       final normTitle = s.title.trim().toLowerCase();
       final normArtist = normalizeArtistName(s.artist);
       final resolvedArtist = normalizeArtistName(currentLibraryType == 'arabic'
           ? (s.artistAr ?? s.artist)
           : s.artist);
       final normArtistAr = s.artistAr != null ? normalizeArtistName(s.artistAr!) : null;
       
       if (selectedTitles.contains(normTitle)) continue; 
       if (forceUniqueArtists && 
           (usedArtists.contains(normArtist) || 
            usedArtists.contains(resolvedArtist) || 
            (normArtistAr != null && usedArtists.contains(normArtistAr)))) {
         continue;
       }
       
       selectedDistractors.add(s);
       selectedTitles.add(normTitle);
       usedArtists.add(normArtist);
       usedArtists.add(resolvedArtist);
       if (normArtistAr != null) {
         usedArtists.add(normArtistAr);
       }
       
       if (selectedDistractors.length >= distractorCount) break;
    }

    // Panic Fallback
    if (selectedDistractors.length < distractorCount) {
       var backupPool = scoredDistractors.take(min(50, scoredDistractors.length)).toList()..shuffle();
       for (var entry in backupPool) {
          final s = entry['song'] as Song;
          final normTitle = s.title.trim().toLowerCase();
          final normArtist = normalizeArtistName(s.artist);
          final resolvedArtist = normalizeArtistName(currentLibraryType == 'arabic'
              ? (s.artistAr ?? s.artist)
              : s.artist);
          final normArtistAr = s.artistAr != null ? normalizeArtistName(s.artistAr!) : null;
          
          if (selectedTitles.contains(normTitle)) continue;
          if (forceUniqueArtists && 
              (usedArtists.contains(normArtist) || 
               usedArtists.contains(resolvedArtist) || 
               (normArtistAr != null && usedArtists.contains(normArtistAr)))) {
            continue;
          }
          
          selectedDistractors.add(s);
          selectedTitles.add(normTitle);
          usedArtists.add(normArtist);
          usedArtists.add(resolvedArtist);
          if (normArtistAr != null) {
            usedArtists.add(normArtistAr);
          }
          if (selectedDistractors.length >= distractorCount) break;
       }
    }

    // Combine and Shuffle Options
    final options = [correctSong, ...selectedDistractors]..shuffle();

    // Fetch Artwork for ALL options in parallel
    await Future.wait(options.map((song) async {
      if (song.artworkUrl == null) {
        final url = await ITunesService.fetchArtwork(song.artist, song.title);
        if (url != null) {
          song.artworkUrl = url;
        }
      }
    }));

    return Question(correctSong: correctSong, options: options);
  }

  // --- PRE-LOADING HELPERS ---

  // NATIVE METHODS STUBBED FOR DETOX
  Future<void> prepareFirstRoundGTS({bool isHardMode = false, int distractorCount = 3}) async {
     print("Repo: prepareFirstRoundGTS (Pre-loading started) HardMode: $isHardMode, Distractors: $distractorCount");
     if (_songs.isEmpty) await loadSongs();
     
     try {
       // Pre-fetch the first question which triggers artwork download
       cachedNextQuestion = await getNextQuestion([], forceUniqueArtists: isHardMode, distractorCount: distractorCount);
       print("Repo: GTS First Question Ready: ${cachedNextQuestion?.correctSong.title}");
     } catch (e) {
       print("Repo: Error pre-loading GTS: $e");
     }
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
