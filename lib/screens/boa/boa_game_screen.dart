import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../models/song.dart';
import '../../services/song_repository.dart';
import '../../services/itunes_service.dart'; // ENABLED
import '../../services/audio_cache_service.dart'; // ENABLED
import '../gts/result_screen.dart'; 
import 'widgets/headphone_score_overlay.dart';

// RECONSTRUCTION STEP 3: ARTWORK FETCHING


class BoaGameScreen extends StatefulWidget {
  final int targetScore;
  final List<String> playerNames;

  const BoaGameScreen({
    super.key,
    required this.targetScore,
    required this.playerNames,
  });

  @override
  State<BoaGameScreen> createState() => _BoaGameScreenState();
}

class _BoaGameScreenState extends State<BoaGameScreen> {
  // Game State
  final Map<String, List<Song>> _timelines = {};
  int _currentPlayerIndex = 0;
  List<Song> _deck = [];
  Song? _currentMysteryCard;
  
  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isLoading = true;
  bool _isRoundResultShowing = false;
  String? _roundFeedbackText;
  bool _lastPlacementCorrect = false;
  bool _isWaitingForTurnStart = true;
  String? _errorMessage;
  late final SongRepository _repository;

  @override
  void initState() {
    super.initState();
    try {
      _repository = SongRepository();
      MediaCacheService().init(); // Initialize Cache

      // Initialize players
      for (var name in widget.playerNames) {
        _timelines[name] = [];
      }
      _startGame();
    } catch (e, stack) {
       setState(() => _errorMessage = "INIT ERROR: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.stop(); // FORCE STOP
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startGame() async {
    try {
      if (!mounted) return;
      
      // Load Songs
      if (_repository.allSongs.isEmpty) {
        await _repository.loadSongs();
      }

      // Create Deck
      _deck = _repository.getValidSongs()..shuffle();

      if (_deck.isEmpty) {
         setState(() => _errorMessage = "DECK EMPTY after loading!");
         return;
      }

      // Deal 1 card to each player
      for (var name in widget.playerNames) {
        if (_deck.isNotEmpty) {
           final song = _deck.removeLast();
           _timelines[name]!.add(song);
           
           // Fetch initial artwork
           if (song.artworkUrl == null) {
              ITunesService.fetchArtwork(song.artist, song.title).then((url) {
                  if (url != null && mounted) {
                     setState(() {
                        song.artworkUrl = url;
                     });
                  }
              });
           }
        }
      }

      if (mounted) {
         setState(() {
            _isLoading = false;
            _isWaitingForTurnStart = true; 
         });
      }
    } catch (e) {
       setState(() => _errorMessage = "START DATA ERROR: $e");
    }
  }

  void _startTurn() async {
    if (_deck.isEmpty) {
       // Handle deck empty / game over?
       return; 
    }
    
    final nextSong = _deck.removeLast();
    setState(() {
       _isWaitingForTurnStart = false;
       _isRoundResultShowing = false;
       _currentMysteryCard = nextSong;
       _roundFeedbackText = null;
    });

    // Play Audio with Cache
    try {
      await _audioPlayer.stop(); // Stop potential previous
      
      String playUrl = nextSong.link;
      final cachedPath = MediaCacheService().getCachedPath(nextSong.link);
      if (cachedPath != null) {
        playUrl = cachedPath;
        debugPrint("Playing from CACHE: $playUrl");
        await _audioPlayer.play(DeviceFileSource(playUrl));
      } else {
        debugPrint("Playing from NET: $playUrl");
        await _audioPlayer.play(UrlSource(playUrl));
        // Cache for next time?
        MediaCacheService().cacheFile(nextSong.link);
      }
      
      // PRELOAD NEXT 3 SONGS
      if (_deck.isNotEmpty) {
        for (var i = 0; i < 3 && i < _deck.length; i++) {
           MediaCacheService().cacheFile(_deck[_deck.length - 1 - i].link);
        }
      }

      // Fetch Artwork if missing
      if (nextSong.artworkUrl == null) {
         ITunesService.fetchArtwork(nextSong.artist, nextSong.title).then((url) {
            if (url != null && mounted) {
               setState(() {
                  nextSong.artworkUrl = url;
               });
            }
         });
      }
      
    } catch (e) {
      debugPrint("Audio Playback Error: $e");
    }
  }

  void _handleCardDrop(int dropIndex) async {
    if (_currentMysteryCard == null) return;
    
    // Stop Audio on drop
    await _audioPlayer.stop();

    final currentPlayerName = widget.playerNames[_currentPlayerIndex];
    final timeline = _timelines[currentPlayerName]!;
    final mysteryYear = int.tryParse(_currentMysteryCard!.year) ?? 0;
    
    bool isValid = true;
    if (dropIndex > 0) {
       final prevYear = int.tryParse(timeline[dropIndex-1].year) ?? 0;
       if (mysteryYear < prevYear) isValid = false;
    }
    if (dropIndex < timeline.length) {
       final nextYear = int.tryParse(timeline[dropIndex].year) ?? 0;
       if (mysteryYear > nextYear) isValid = false;
    }

    if (mounted) {
       setState(() {
          _lastPlacementCorrect = isValid;
          _roundFeedbackText = isValid ? "CORRECT!" : "WRONG!";
          
          if (isValid) {
            timeline.insert(dropIndex, _currentMysteryCard!);
            // Check Win Condition
            if (timeline.length >= widget.targetScore) {
               _handleGameOver(currentPlayerName); // Pass winner
               return; // Don't show round result, go to game over
            }
          }
          
          _isRoundResultShowing = true;
       });
    }
  }

  void _handleGameOver(String winnerName) {
    // Navigate to Results
    _audioPlayer.stop(); // Stop music before leaving
    
    // Convert timelines to scores
    final Map<String, int> scores = {};
    _timelines.forEach((key, value) {
      scores[key] = value.length;
    });

    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (_) => GtsResultScreen(
        scores: scores, 
        totalRounds: widget.targetScore // Just passing target as rounds logic
      ))
    );
  }

  void _nextPlayer() {
     setState(() {
        _currentPlayerIndex = (_currentPlayerIndex + 1) % widget.playerNames.length;
        _isWaitingForTurnStart = true;
        _isRoundResultShowing = false;
        _currentMysteryCard = null;
     });
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) return Scaffold(backgroundColor: Colors.red, body: Center(child: Text(_errorMessage!, style: const TextStyle(color:Colors.white))));
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final currentPlayer = widget.playerNames[_currentPlayerIndex];
    final timeline = _timelines[currentPlayer];

    return Scaffold(
      backgroundColor: Colors.white, // WHITE BACKGROUND
      appBar: AppBar(
        backgroundColor: Colors.white, // WHITE APPBAR
        title: Text("Turn: $currentPlayer", style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)), 
        iconTheme: const IconThemeData(color: Colors.black),
        automaticallyImplyLeading: false, 
        actions: [
          IconButton(
            icon: const Icon(Icons.close), 
            onPressed: () => Navigator.pop(context)
          )
        ]
      ),
      body: Column(
        children: [
           // TIMELINE
           Expanded(
             flex: 2,
             child: SingleChildScrollView(
               scrollDirection: Axis.horizontal,
               padding: const EdgeInsets.symmetric(horizontal: 20),
               child: Row(
                  children: [
                     for (int i = 0; i <= timeline!.length; i++) ...[
                        _buildDropZone(i),
                        if (i < timeline.length)
                           _buildTimelineCard(timeline[i])
                     ]
                  ],
               ),
             ),
           ),
           // MYSTERY / CONTROLS
           Expanded(
              flex: 3,
              child: Center(
                  child: _isWaitingForTurnStart 
                    ? _buildStartTurnButton()
                    : _isRoundResultShowing
                        ? _buildResultFeedback()
                        : _buildMysteryDraggable()
              ),
           )
        ],
      ),
    );
  }

  // --- RENDERING METHODS ---

  Widget _buildDropZone(int index) {
      return DragTarget<Song>(
      onWillAccept: (data) => !_isRoundResultShowing,
      onAccept: (data) => _handleCardDrop(index),
      builder: (context, candidateData, rejectedData) {
        bool isHovered = candidateData.isNotEmpty;
        return FittedBox( // ADDED FITTEDBOX
          fit: BoxFit.scaleDown,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isHovered ? 160.0 : 40.0, 
            height: 280, 
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: isHovered
               ? Center(child: Container(
                   width: 60, height: 60,
                   decoration: BoxDecoration(
                     color: Theme.of(context).primaryColor.withOpacity(0.2), 
                     shape: BoxShape.circle, 
                     border: Border.all(color: Theme.of(context).primaryColor, width: 2)
                   ),
                   child: Icon(Icons.add, color: Theme.of(context).primaryColor, size: 30)
                 ))
               : null,
          ),
        );
      },
    );
  }

  Widget _buildTimelineCard(Song song) {
    return FittedBox( // ADDED FITTEDBOX
      fit: BoxFit.scaleDown,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 140, height: 200,
              decoration: BoxDecoration(
                 borderRadius: BorderRadius.circular(12),
                 color: Colors.white, // WHITE CARD
                 boxShadow: [
                   BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(4, 4)), // 3D Shadow
                   BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2, offset: const Offset(-1, -1))
                 ]
              ),
              child: Column(
                 children: [
                   // SQUARE IMAGE
                   Container(
                     width: 140, height: 140,
                     decoration: BoxDecoration(
                       borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                       color: Colors.grey[300],
                       image: song.artworkUrl != null ? DecorationImage(image: NetworkImage(song.artworkUrl!), fit: BoxFit.cover) : null,
                     ),
                   ),
                   // TEXT INFO
                   Expanded(
                     child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                           Text(song.artist, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w900, height: 1.1)), // BLACK Name
                           const SizedBox(height: 2),
                           Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(color: Colors.grey[700], fontSize: 11)), // GREY Title
                        ])
                     ),
                   )
                 ],
              ),
            ),
            SizedBox(
              height: 40, width: 140, 
              child: Center(child: Container(width: 4, height: 40, color: Colors.black)) // BLACK connector line
            ),
            Text(song.year, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)), // BLACK Year
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildMysteryDraggable() {
    if (_currentMysteryCard == null) return const SizedBox.shrink();
    
    final cardContent = Container(
      width: 160, height: 240,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C3E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))],
        border: Border.all(color: Colors.white24)
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.question_mark_rounded, size: 60, color: Theme.of(context).primaryColor),
          const SizedBox(height: 10),
          Text("MYSTERY", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        ],
      ),
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Draggable<Song>(
        data: _currentMysteryCard,
        feedback: Material(color: Colors.transparent, child: Transform.scale(scale: 1.1, child: cardContent)),
        childWhenDragging: Opacity(opacity: 0.5, child: cardContent),
        child: cardContent,
      ),
    );
  }

  Widget _buildStartTurnButton() {
    final currentPlayer = widget.playerNames[_currentPlayerIndex];
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
      width: 300,
      
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.4), blurRadius: 30, spreadRadius: 5)
        ]
      ),
      child: ElevatedButton(
        onPressed: _startTurn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow_rounded, size: 40, color: Colors.black),
             Text("START TURN", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
             Text(currentPlayer.toUpperCase(), style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black)),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildResultFeedback() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Added min size
        children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _roundFeedbackText ?? "",
            key: ValueKey(_roundFeedbackText),
            style: GoogleFonts.outfit(
              fontSize: 48, 
              fontWeight: FontWeight.w900, 
              color: _lastPlacementCorrect ? Colors.greenAccent : Colors.redAccent,
              shadows: [
                Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))
              ]
            )
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _nextPlayer, 
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            backgroundColor: Colors.white24
          ),
          child: const Text("NEXT PLAYER")
        )
      ],
    ), // Close Column
    ); // Close FittedBox
  }
}
