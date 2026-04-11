import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:math';

import '../../models/song.dart';
import '../../services/song_repository.dart';
import '../../services/itunes_service.dart';
import '../../services/audio_cache_service.dart';
import '../gts/result_screen.dart'; 

class TsGameScreen extends StatefulWidget {
  final List<String> playerNames;
  final Map<String, Color> playerColors;
  final int startingPoints;

  const TsGameScreen({
    super.key,
    required this.playerNames,
    this.playerColors = const {},
    this.startingPoints = 100,
  });

  @override
  State<TsGameScreen> createState() => _TsGameScreenState();
}

class _TsGameScreenState extends State<TsGameScreen> with TickerProviderStateMixin {
  // Game State
  final Map<String, int> _playerScores = {};
  List<Song> _deck = [];
  Song? _currentSong;
  
  // Turn Management
  final Map<String, int> _platformGuesses = {}; 
  int _currentGuesserIndex = 0;
  bool _isRoundActive = false;
  bool _isRoundResultShowing = false;
  bool _isGameOver = false;
  String? _roundLoserName;

  // Timeline State
  int? _selectedYear; // Current player's transient selection
  int? _hoveredYear;  // For magnifying effect
  final int _startYear = 1970;
  final int _endYear = 2026;
  late FixedExtentScrollController _timelineController;

  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isSongCardHovered = false;
  
  // Services
  late final SongRepository _repository;
  
  // Animations
  late AnimationController _borderController;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    
    // Initialize safely
    _timelineController = FixedExtentScrollController(initialItem: 1995 - _startYear);
    
    _borderController = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 4),
    )..repeat();
  }
  
  Future<void> _initializeGame() async {
    _repository = SongRepository();
    await MediaCacheService().init();
    
    // Init scores
    for (var name in widget.playerNames) {
      _playerScores[name] = widget.startingPoints;
    }

    if (_repository.allSongs.isEmpty) {
      await _repository.loadSongs();
    }
    _deck = _repository.getValidSongs()..shuffle();

    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _startNewRound();
    }
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _borderController.dispose();
    _timelineController.dispose();
    super.dispose();
  }

  void _startNewRound() async {
    if (_deck.isEmpty) return;

    setState(() {
      _currentSong = _deck.removeLast();
      _platformGuesses.clear();
      _currentGuesserIndex = 0;
      _isRoundActive = true;
      _isRoundResultShowing = false;
      _isPlaying = false;
      _roundLoserName = null;
      _selectedYear = null;
      _hoveredYear = null;
    });
    
    // Center timeline roughly on 1995 (middle)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_timelineController.hasClients) {
         // Approx width calculation: 25 years * avg width (12) + padding
         _timelineController.jumpTo(300); 
      }
    });

    if (_currentSong!.artworkUrl == null) {
      ITunesService.fetchArtwork(_currentSong!.artist, _currentSong!.title).then((url) {
        if (url != null && mounted) {
           setState(() {
              _currentSong!.artworkUrl = url;
           });
        }
      });
    }

    _playSong();
  }

  Future<void> _playSong() async {
    if (_currentSong == null) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      
      Source source;
      final cachedPath = MediaCacheService().getCachedPath(_currentSong!.link);
      
      if (cachedPath != null) {
        source = DeviceFileSource(cachedPath);
      } else {
        source = UrlSource(_currentSong!.link);
      }
      
      await _audioPlayer.play(source);
      setState(() => _isPlaying = true);
    } catch (e) {
      debugPrint("Error playing song: $e");
    }
  }

  void _submitGuess() {
    if (!_isRoundActive || _isRoundResultShowing || _selectedYear == null) return;

    final currentPlayerName = widget.playerNames[_currentGuesserIndex];
    
    setState(() {
      _platformGuesses[currentPlayerName] = _selectedYear!;
      _selectedYear = null; // Clear transient
    });

    // Move to next player
    if (_currentGuesserIndex < widget.playerNames.length - 1) {
      setState(() {
        _currentGuesserIndex++;
      });
    } else {
      // All players guessed
      _revealResults();
    }
  }

  void _revealResults() {
    _audioPlayer.stop();
    
    setState(() {
      _isRoundActive = false;
      _isRoundResultShowing = true;
    });

    // Animate to answer?
    final actualYear = int.tryParse(_currentSong!.year) ?? _startYear;
    // Calculate scroll offset is tricky with dynamic widths, so we might skip auto-scroll for now
    // or implement a "Scroll to Year" helper if needed.
    
    bool someoneDied = false;
    int maxLoss = -1;
    String? maxLoser;

    _platformGuesses.forEach((player, guess) {
      int diff = (guess - actualYear).abs();
      if (diff > maxLoss) {
        maxLoss = diff;
        maxLoser = player;
      }
      
      int newScore = _playerScores[player]! - diff;
      _playerScores[player] = max(0, newScore); 
      
      if (_playerScores[player] == 0) {
        someoneDied = true;
      }
    });

    if (maxLoss > 0) {
      setState(() => _roundLoserName = maxLoser);
    }

    if (someoneDied) {
      setState(() => _isGameOver = true);
    }
  }

  void _finishGame() {
     Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (_) => GtsResultScreen(
        scores: _playerScores, 
        totalRounds: widget.startingPoints, 
        isLightMode: false,
      ))
    );
  }

  @override
  Widget build(BuildContext context) {
    Color currentPlayerColor = Colors.grey;
    if (widget.playerNames.isNotEmpty && _currentGuesserIndex < widget.playerNames.length) {
       currentPlayerColor = widget.playerColors[widget.playerNames[_currentGuesserIndex]] ?? Colors.blueAccent;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), 
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 140), // Header Space

                // --- TIMELINE AREA ---
                Expanded(
                  child: Container(
                    height: 200, 
                    // Horizontal Wheel Trick: Rotate wheel -90 deg, rotate children +90 deg
                    child: RotatedBox(
                      quarterTurns: -1, 
                      child: ListWheelScrollView.useDelegate(
                        controller: _timelineController,
                        itemExtent: 18, 
                        perspective: 0.003,
                        diameterRatio: 1.5, 
                        magnification: 4.0, 
                        useMagnifier: true,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                          // Allow "hover" effect by dragging
                          setState(() {
                             _hoveredYear = _startYear + index;
                             // Auto-select center item? User asked for "Magnifying glass", 
                             // usually implies center is the 'active' one.
                             // We'll treat center as hover, tap to lock.
                          });
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: _endYear - _startYear + 1,
                          builder: (context, index) {
                            final int year = _startYear + index;
                            return RotatedBox(
                               quarterTurns: 1,
                               child: _buildTimelineNode(year, currentPlayerColor)
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Instructions / Status
                 Padding(
                   padding: const EdgeInsets.only(bottom: 20),
                   child: Text(
                     _isRoundResultShowing 
                       ? "ROUND OVER" 
                       : "${widget.playerNames[_currentGuesserIndex]}'s Turn: Select a Year",
                     style: GoogleFonts.outfit(
                       color: Colors.white54,
                       fontSize: 16,
                       letterSpacing: 2
                     ),
                   ),
                 ),

                // Lock In Button (Center Item is always the "Selected" candidate in this view)
                if (!_isRoundResultShowing)
                   Padding(
                     padding: const EdgeInsets.only(bottom: 40),
                     child: FadeInUp(
                       duration: const Duration(milliseconds: 300),
                       // We use _hoveredYear as the "Current Center" in this mode
                       key: ValueKey(_hoveredYear), 
                       child: ElevatedButton.icon(
                         onPressed: () {
                           if (_hoveredYear != null) {
                             setState(() => _selectedYear = _hoveredYear);
                             _submitGuess();
                           }
                         },
                         icon: const Icon(Icons.check_circle),
                         label: Text("LOCK IN ${_hoveredYear ?? '...'}"),
                         style: ElevatedButton.styleFrom(
                           backgroundColor: currentPlayerColor,
                           foregroundColor: Colors.white,
                           textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                           padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                         ),
                       ),
                     ),
                   ),
                 
                 // Result Info
                 if (_isRoundResultShowing)
                   Padding(
                     padding: const EdgeInsets.only(bottom: 40),
                     child: FadeInUp(
                       child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                         decoration: BoxDecoration(
                           color: Colors.black54,
                           borderRadius: BorderRadius.circular(20),
                           border: Border.all(color: Colors.greenAccent),
                         ),
                         child: Column(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             Text("ACTUAL YEAR", style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                             Text(
                               _currentSong?.year ?? "???",
                               style: const TextStyle(color: Colors.greenAccent, fontSize: 32, fontWeight: FontWeight.w900),
                             ),
                           ],
                         ),
                       ),
                     ),
                   ),

              ],
            ),
            
            // --- HEADER ---
            _buildHeaderUI(context, currentPlayerColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineNode(int year, Color currentPlayerColor) {
    bool isCenter = _hoveredYear == year; // In wheel view, hover is essentially center
    bool isSelected = _selectedYear == year; // Flag placed
    bool isMilestone = year % 5 == 0;
    
    // Who picked this year?
    List<Color> markers = [];
    _platformGuesses.forEach((p, y) {
       if (y == year) markers.add(widget.playerColors[p] ?? Colors.grey);
    });

    // In Fisheye/Magnifier view, the "magnified" item naturally gets more space.
    // We visually style it to look "Detailed" or "Compressed".
    
    // Dimensions managed by ListView ItemExtent generally, but visual weight here:
    double height = 40.0;
    Color color = Colors.white12;
    double fontSize = 8.0;

    if (isCenter) {
      // Let Magnifier handle scaling, just set color
      color = Colors.white;
    } else if (isMilestone) {
       color = Colors.white54;
       height = 80.0;
       fontSize = 14.0;
    }

     // Determine correctness for result
    if (_isRoundResultShowing) {
       final actual = int.tryParse(_currentSong!.year) ?? 0;
       if (year == actual) {
         color = Colors.greenAccent;
         fontSize = 24.0;
       }
    }

    return Container(
      alignment: Alignment.center,
      child: Stack(
         alignment: Alignment.center,
         clipBehavior: Clip.none,
         children: [
            // The Bar/Tick
            Container(
              width: 2,
              height: height,
              color: color,
            ),
            
            // Text Label
            if (isCenter || isMilestone || (_isRoundResultShowing && year == (int.tryParse(_currentSong?.year ?? "") ?? 0)))
              Positioned(
                 bottom: -30,
                 child: Text(
                   "$year", 
                   style: GoogleFonts.robotoMono(
                     color: color, 
                     fontWeight: isCenter ? FontWeight.bold : FontWeight.normal,
                     fontSize: fontSize
                   )
                 )
              ),
              
             // Player Flags
             ...List.generate(markers.length, (index) {
                return Positioned(
                  top: -30.0 - (index * 25), 
                  child: Icon(Icons.flag, color: markers[index], size: 24),
                );
             }),

            // If selected (just placed)
            if (isSelected) 
               Positioned(top: -30, child: Icon(Icons.flag, color: currentPlayerColor, size: 24)),
         ],
      ),
    );
  }

  Widget _buildHeaderUI(BuildContext context, Color currentPlayerColor) {
    return Positioned(
      top: 0, left: 0, right: 0,
      height: 140,
      child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.8), Colors.transparent]
        )
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Text("Time Survival", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      if (_isRoundResultShowing) ...[
                         const Spacer(),
                         ElevatedButton.icon(
                            onPressed: _isGameOver ? _finishGame : _startNewRound,
                            style: ElevatedButton.styleFrom(
                               backgroundColor: const Color(0xFF6C63FF),
                               foregroundColor: Colors.white,
                            ),
                            icon: Icon(_isGameOver ? Icons.emoji_events : Icons.next_plan),
                            label: Text(_isGameOver ? "FINISH" : "NEXT"),
                         )
                      ]
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                     height: 70,
                     child: ListView.builder(
                       scrollDirection: Axis.horizontal,
                       itemCount: widget.playerNames.length,
                       itemBuilder: (context, index) {
                         final name = widget.playerNames[index];
                         final isCurrentTurn = !_isRoundResultShowing && widget.playerNames[_currentGuesserIndex] == name;
                         final score = _playerScores[name] ?? 100;
                         final color = widget.playerColors[name] ?? Colors.grey;
                         final hasGuessed = _platformGuesses.containsKey(name);

                         return Padding(
                           padding: const EdgeInsets.only(right: 12),
                           child: AnimatedContainer(
                               duration: const Duration(milliseconds: 300),
                               padding: const EdgeInsets.all(8),
                               decoration: BoxDecoration(
                                 color: isCurrentTurn ? color.withOpacity(0.2) : Colors.transparent,
                                 border: Border.all(
                                   color: isCurrentTurn ? color : (hasGuessed ? Colors.white30 : Colors.white10),
                                   width: isCurrentTurn ? 2 : 1
                                  ),
                                 borderRadius: BorderRadius.circular(12),
                               ),
                               child: Column(
                                 mainAxisAlignment: MainAxisAlignment.center,
                                 children: [
                                   Text(name, style: TextStyle(color: isCurrentTurn ? Colors.white : Colors.white70, fontSize: 10)),
                                   Text("$score", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                   if (hasGuessed) 
                                      Icon(Icons.check_circle, size: 12, color: color)
                                   else if (isCurrentTurn)
                                      const Icon(Icons.mode_edit, size: 12, color: Colors.white54)
                                 ],
                               ),
                           ),
                         );
                       },
                     ),
                   ),
               ],
             ),
           ),

           const SizedBox(width: 12),

           _buildSongDisplay(),
        ],
      ),
      ),
    );
  }

  Widget _buildSongDisplay() {
    if (_currentSong == null) {
      return Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[900],
        ),
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF), strokeWidth: 2)),
      );
    }
    
    return Container(
      width: 100, 
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[900],
        image: _currentSong!.artworkUrl != null 
            ? DecorationImage(image: NetworkImage(_currentSong!.artworkUrl!), fit: BoxFit.cover)
            : null,
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)]
      ),
      child: _currentSong!.artworkUrl == null 
         ? const Center(child: Icon(Icons.music_note, color: Colors.white24)) 
         : null,
    );
  }
}
