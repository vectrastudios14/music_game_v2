import 'dart:async';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:animate_do/animate_do.dart';

import 'package:lottie/lottie.dart';
import '../../models/song.dart';
import '../../services/song_repository.dart';
import '../../services/itunes_service.dart';
import '../../services/audio_cache_service.dart';
import '../gts/result_screen.dart'; 
import 'widgets/ts_round_result_modal.dart';
import 'widgets/scrolling_neon_ticker.dart';
import '../../services/background_music_service.dart';
import '../../services/firebase_service.dart';
// LiquidTube import removed

class TsGameScreen extends StatefulWidget {
  final List<String> playerNames;
  final Map<String, Color> playerColors;
  final int startingPoints;
  final String uiLanguage;
  final String? roomCode;

  const TsGameScreen({
    super.key,
    required this.playerNames,
    this.playerColors = const {},
    this.startingPoints = 100,
    this.uiLanguage = 'en',
    this.roomCode,
  });

  @override
  State<TsGameScreen> createState() => _TsGameScreenState();
}

class _TsGameScreenState extends State<TsGameScreen> {
  final Map<String, int> _playerScores = {};
  Map<String, int> _previousScores = {}; 
  List<Song> _deck = [];
  Song? _currentSong;
  
  final Map<String, int> _platformGuesses = {}; 
  int _currentGuesserIndex = 0;
  
  StreamSubscription? _firebaseSubscription;
  final Map<String, int> _submittedGuesses = {};
  bool _allPlayersGuessed = false;
  bool _isRevealMode = false;
  List<String> _revealedPlayers = [];
  int _revealIndex = 0;
  bool _isRoundActive = false;
  bool _isRoundResultShowing = false;
  bool _isGameOver = false;
  bool _isReadyOverlayVisible = false;
  String? _roundLoserName;
  String? _currentRoundFact; 

  int? _selectedYear; 
  int? _hoveredDetailedYear;
  int _focusYear = 1995; 
  final int _startYear = 1970;
  final int _endYear = 2026;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _showScoreOverlay = false;
  bool _showFacts = false; 
  bool _isLockHovered = false; 
  String? _hoveredPlayerName; 
  Timer? _popupCloseTimer; 
  int _showcasedPlayerIndex = -1;
  Timer? _showcaseTimer;

  late final SongRepository _repository;
  
  @override
  void initState() {
    super.initState();
    _initializeGame();
  }
  
  Future<void> _initializeGame() async {
    _repository = SongRepository();
    await MediaCacheService().init();
    for (var name in widget.playerNames) {
      _playerScores[name] = widget.startingPoints;
    }
    if (_repository.allSongs.isEmpty) await _repository.loadSongs();
    _deck = _repository.getValidSongs()..shuffle();
    
    if (widget.roomCode != null) {
      _firebaseSubscription = FirebaseService().listenToRoomCustom(widget.roomCode!).listen((data) {
        if (!mounted) return;
        if (data.isEmpty) return;

        if (data['nextRoundRequested'] == true && _isRoundResultShowing) {
          FirebaseService().resetNextRoundRequest(widget.roomCode!);
          _continueToNextRound();
        }

        if (data['tsGuesses'] != null) {
          final rawGuesses = Map<String, dynamic>.from(data['tsGuesses'] as Map);
          setState(() {
            _submittedGuesses.clear();
            rawGuesses.forEach((player, val) {
              final guessData = Map<String, dynamic>.from(val as Map);
              _submittedGuesses[player] = int.tryParse(guessData['year'].toString()) ?? _startYear;
            });
            _allPlayersGuessed = _submittedGuesses.length >= widget.playerNames.length;
          });
        } else {
          setState(() {
            _submittedGuesses.clear();
            _allPlayersGuessed = false;
          });
        }
      });
    }

    if (mounted) _startNewRound();
  }

  @override
  void dispose() {
    _firebaseSubscription?.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _showcaseTimer?.cancel();
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
      _isReadyOverlayVisible = widget.roomCode == null; // Skip sequential ready overlays in mobile mode
      _showScoreOverlay = false;
      _isPlaying = false;
      _roundLoserName = null;
      _selectedYear = null;
      _hoveredDetailedYear = null;
      _hoveredPlayerName = null;
      _focusYear = 1995;
      _showFacts = false;
      _showcasedPlayerIndex = -1;
      _showcaseTimer?.cancel();
      
      _submittedGuesses.clear();
      _allPlayersGuessed = false;
      _isRevealMode = false;
      _revealedPlayers.clear();
      _revealIndex = 0;

      // Select one random fact for the round safely
      if (_currentSong != null && _currentSong!.facts.isNotEmpty) {
        final random = Random();
        _currentRoundFact = _currentSong!.facts[random.nextInt(_currentSong!.facts.length)];
      } else {
        _currentRoundFact = null;
      }
    });

    if (widget.roomCode != null) {
      await FirebaseService().clearTsGuesses(widget.roomCode!);
      await FirebaseService().updateTsRoomState(
        widget.roomCode!,
        playerNames: widget.playerNames,
        scores: _playerScores,
        currentSong: {
          'title': _currentSong!.title,
          'artist': _currentSong!.artist,
          'artworkUrl': _currentSong!.artworkUrl ?? '',
        },
        status: 'guessing',
        isRoundResultShowing: false,
        isWaitingForReady: false,
        roundLoserName: null,
        actualYear: int.tryParse(_currentSong!.year) ?? _startYear,
      );
    }
    if (_currentSong!.artworkUrl == null) {
      ITunesService.fetchArtwork(_currentSong!.artist, _currentSong!.title).then((url) {
        if (url != null && mounted) setState(() => _currentSong!.artworkUrl = url);
      });
    }
    _playSong();
    _bufferNextSongs();
  }

  Future<void> _bufferNextSongs() async {
    for (int i = 0; i < 3 && i < _deck.length; i++) {
        final song = _deck[_deck.length - 1 - i]; 
        MediaCacheService().cacheFile(song.link);
        if (song.artworkUrl != null) MediaCacheService().cacheFile(song.artworkUrl!);
    }
  }

  Future<void> _playSong() async {
    if (_currentSong == null) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      Source source;
      final cachedPath = MediaCacheService().getCachedPath(_currentSong!.link);
      source = cachedPath != null ? DeviceFileSource(cachedPath) : UrlSource(_currentSong!.link);
      await _audioPlayer.play(source);
      setState(() => _isPlaying = true);
    } catch (_) {}
  }

  void _startRevealSequence() {
    setState(() {
      _isRevealMode = true;
      _revealedPlayers = List.from(widget.playerNames);
      _revealIndex = 0;
    });
    _revealNextPlayerGuess();
  }

  void _revealNextPlayerGuess() {
    if (_revealIndex < _revealedPlayers.length) {
      final playerName = _revealedPlayers[_revealIndex];
      final playerGuess = _submittedGuesses[playerName] ?? _startYear;
      
      setState(() {
        _platformGuesses[playerName] = playerGuess;
        _focusYear = playerGuess; // smooth scroll to their guess
      });
      
      BackgroundMusicService.instance.playSfx('tick.mp3');
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _revealIndex++;
          });
          _revealNextPlayerGuess();
        }
      });
    } else {
      _revealFinalResults();
    }
  }

  void _revealFinalResults() {
    _previousScores = Map.from(_playerScores);
    final actualYear = int.tryParse(_currentSong!.year) ?? _startYear;
    
    setState(() {
      _isRoundActive = false;
      _isRoundResultShowing = true;
      _focusYear = actualYear;
    });

    bool someoneDied = false;
    int maxLoss = -1;
    String? maxLoser;
    
    _platformGuesses.forEach((player, guess) {
      int diff = (guess - actualYear).abs();
      if (diff > maxLoss) { maxLoss = diff; maxLoser = player; }
      int newScore = _playerScores[player]! - diff;
      _playerScores[player] = newScore;
      if (newScore <= 0) someoneDied = true;
    });

    if (maxLoss > 0) setState(() => _roundLoserName = maxLoser);
    if (someoneDied) setState(() => _isGameOver = true);
    
    if (widget.roomCode != null) {
      FirebaseService().updateTsRoomState(
        widget.roomCode!,
        playerNames: widget.playerNames,
        scores: _playerScores,
        status: 'results',
        isRoundResultShowing: true,
        isWaitingForReady: false,
        roundLoserName: _roundLoserName,
        actualYear: actualYear,
      );
    }
  }

  void _submitGuess() {
    if (!_isRoundActive || _isRoundResultShowing || _selectedYear == null) return;
    final currentPlayerName = widget.playerNames[_currentGuesserIndex];
    setState(() { _platformGuesses[currentPlayerName] = _selectedYear!; _selectedYear = null; });
    if (_currentGuesserIndex < widget.playerNames.length - 1) { 
      setState(() {
        _currentGuesserIndex++; 
        _isReadyOverlayVisible = true; // Show next player ready
      });
    }
    else { _revealResults(); }
  }

  void _revealResults() {
    _previousScores = Map.from(_playerScores);
    setState(() { _isRoundActive = false; _isRoundResultShowing = true; _showScoreOverlay = false; });
    final actualYear = int.tryParse(_currentSong!.year) ?? _startYear;
    setState(() => _focusYear = actualYear);
    bool someoneDied = false;
    int maxLoss = -1;
    String? maxLoser;
    _platformGuesses.forEach((player, guess) {
      int diff = (guess - actualYear).abs();
      if (diff > maxLoss) { maxLoss = diff; maxLoser = player; }
      int newScore = _playerScores[player]! - diff;
      _playerScores[player] = newScore;
      if (newScore <= 0) someoneDied = true;
    });
    if (maxLoss > 0) setState(() => _roundLoserName = maxLoser);
    if (someoneDied) setState(() => _isGameOver = true);

    // Start Sequential Showcase
    _startShowcase();
  }

  void _startShowcase() {
    _showcaseTimer?.cancel();
    _showcasedPlayerIndex = 0;
    
    final players = widget.playerNames;
    if (players.isEmpty) return;

    // Focus on the first player immediately
    final firstPlayer = players[0];
    if (_platformGuesses.containsKey(firstPlayer)) {
      setState(() => _focusYear = _platformGuesses[firstPlayer]!);
    }

    _showcaseTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || !_isRoundResultShowing) {
        timer.cancel();
        return;
      }
      setState(() {
        _showcasedPlayerIndex = (_showcasedPlayerIndex + 1) % players.length;
        final currentPlayer = players[_showcasedPlayerIndex];
        if (_platformGuesses.containsKey(currentPlayer)) {
          _focusYear = _platformGuesses[currentPlayer]!;
        }
      });
      BackgroundMusicService.instance.playSfx('tick.mp3');
    });
  }


  void _continueToNextRound() {
     if (_isGameOver) {
       setState(() => _showScoreOverlay = false);
       if (widget.roomCode != null) {
         FirebaseService().updateTsRoomState(
           widget.roomCode!,
           playerNames: widget.playerNames,
           scores: _playerScores,
           status: 'gameover',
         );
       }
     } else {
       _startNewRound();
     }
  }

  String _t(String key) {
    final isAr = widget.uiLanguage == 'ar';
    final Map<String, Map<String, String>> strings = {
      'en': {
        'viewResults': 'VIEW RESULTS',
        'lockIn': 'LOCK IN',
        'selectYear': 'Select a year on the timeline',
        'songFacts': 'SONG FACTS',
        'noFacts': 'No facts available.',
        'roundComplete': 'ROUND COMPLETE!',
        'nextRound': 'START NEXT ROUND',
        'finishGame': 'FINISH GAME',
        'points': 'pts',
        'readyPrompt': 'It\'s your turn:',
        'startNow': 'START NOW',
        'actualYear': 'ACTUAL YEAR',
      },
      'ar': {
        'viewResults': 'عرض النتائج',
        'lockIn': 'تأكيد العام',
        'selectYear': 'اختر عاماً من الخط الزمني',
        'songFacts': 'حقائق عن الأغنية',
        'noFacts': 'لا توجد حقائق متاحة.',
        'roundComplete': 'اكتملت الجولة!',
        'nextRound': 'بداية الجولة القادمة',
        'finishGame': 'إنهاء اللعبة',
        'points': 'نقطة',
        'readyPrompt': 'دورك:',
        'startNow': 'ابدأ الآن',
        'actualYear': 'السنة الصحيحة',
      },
    };
    return strings[isAr ? 'ar' : 'en']![key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    Color currentPlayerColor = Colors.grey;
    if (widget.playerNames.isNotEmpty && _currentGuesserIndex < widget.playerNames.length) currentPlayerColor = widget.playerColors[widget.playerNames[_currentGuesserIndex]] ?? Colors.blueAccent;
    
    final isAr = widget.uiLanguage == 'ar';
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), 
      body: Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              setState(() { _focusYear = (_focusYear + (event.scrollDelta.dy > 0 ? 1 : -1)).clamp(_startYear, _endYear); });
            }
          },
          child: SafeArea(
            child: Stack(
              children: [
                // Premium Scrolling Ticker (Song Info) - Now moved below player names
                if ((_isRoundActive || _isRoundResultShowing) && _currentSong != null)
                  Positioned(
                    top: 105, 
                    left: 0, 
                    right: 0,
                    child: Center(
                      child: ScrollingNeonTicker(
                        title: isAr ? (_currentSong!.titleAr ?? _currentSong!.title) : _currentSong!.title,
                        artist: isAr ? (_currentSong!.artistAr ?? _currentSong!.artist) : _currentSong!.artist,
                        width: 380,
                      ),
                    ),
                  ),

                Column(
                  children: [
                    const SizedBox(height: 160), // Increased to clear both header and song ticker
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildOverviewTimeline(currentPlayerColor),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                    _buildControlsArea(currentPlayerColor),
                  ],
                ),
                if (_showFacts && !_isRoundResultShowing) 
                  IgnorePointer(child: _buildFactsPopup()),
                _buildHeader(),
                
                // Relocated Song Card
                _buildMysterySongCard(),

                if (_isRoundResultShowing && _showScoreOverlay) _buildResultModal(),
                if (_isReadyOverlayVisible) _buildReadyOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTimeline(Color color) {
    return LayoutBuilder(builder: (context, constraints) {
      final double width = constraints.maxWidth;
      final int totalYears = _endYear - _startYear + 1;
      final double yearWidth = width / totalYears;
      return MouseRegion(
        onHover: (event) {
          final int newFocus = (_startYear + (event.localPosition.dx / yearWidth).floor()).clamp(_startYear, _endYear);
          if (newFocus != _focusYear) {
            setState(() => _focusYear = newFocus);
            BackgroundMusicService.instance.playSfx('tick.mp3'); // Added tick sound
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            if (_isRoundActive && !_isRoundResultShowing) {
              final int clickedYear = (_startYear + (details.localPosition.dx / yearWidth).floor()).clamp(_startYear, _endYear);
              setState(() {
                _selectedYear = clickedYear;
                _focusYear = clickedYear; // Synchronize immediately
              });
              BackgroundMusicService.instance.playSfx('tick.mp3');
            }
          },
          child: Container(
            height: 150, width: width,
            color: Colors.transparent, // Ensure full hit area
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(child: Container(height: 2, color: Colors.white24)),
                for (int i=0; i<totalYears; i++) _buildTick(_startYear+i, yearWidth, color),
                
                // Locked-in Guesses from other players
                ...() {
                  final Map<int, List<MapEntry<String, int>>> groupedGuesses = {};
                  for (var entry in _platformGuesses.entries) {
                    groupedGuesses.putIfAbsent(entry.value, () => []).add(entry);
                  }
                  
                  List<Widget> flagWidgets = [];
                  groupedGuesses.forEach((year, entries) {
                    for (int j = 0; j < entries.length; j++) {
                      final playerName = entries[j].key;
                      final playerColor = widget.playerColors[playerName] ?? Colors.white;
                      final isHovered = _hoveredPlayerName == playerName;
                      
                      flagWidgets.add(
                        Positioned(
                          left: (year - _startYear) * yearWidth + (yearWidth / 2) - 4,
                          bottom: 75.0 + (j * 16), // Balanced on the 150px center
                          child: Tooltip(
                            message: playerName,
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 200),
                              scale: isHovered ? 1.5 : 1.0,
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                clipBehavior: Clip.none,
                                children: [
                                  if (isHovered)
                                    Positioned(
                                      bottom: 0,
                                      child: Container(
                                        width: 10, height: 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(color: playerColor.withOpacity(0.5), blurRadius: 15, spreadRadius: 5)
                                          ]
                                        ),
                                      ),
                                    ),
                                  WavingFlag(color: playerColor, size: 20),
                                ],
                              ),
                            ),
                          ),
                        )
                      );
                    }
                  });
                  return flagWidgets;
                }(),

                // Selected Year Marker (Glow line below the timeline instead of a flag)
                if (_selectedYear != null && !_isRoundResultShowing)
                  Positioned(
                    left: (_selectedYear! - _startYear) * yearWidth + (yearWidth / 2) - 3,
                    top: 75, // Starting from the center line (150/2)
                    child: Container(
                      width: 6,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [color, color.withOpacity(0)],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                        boxShadow: [
                          BoxShadow(color: color.withOpacity(0.5), blurRadius: 10, spreadRadius: 1)
                        ],
                      ),
                    ),
                  ),
                
                // 1. Precise Indicator Line (Always reflects exact year)
                if (!_isRoundResultShowing)
                  AnimatedPositioned(
                    duration: Duration(milliseconds: _isLockHovered ? 400 : 60),
                    curve: _isLockHovered ? Curves.elasticOut : Curves.linear,
                    left: (((_isLockHovered && _selectedYear != null) ? _selectedYear! : _focusYear) - _startYear) * yearWidth + (yearWidth / 2) - 1.5,
                    top: 75,
                    height: 40,
                    width: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        boxShadow: [
                          BoxShadow(color: color.withOpacity(0.5), blurRadius: 4, spreadRadius: 1)
                        ]
                      ),
                    ),
                  ),

                // 2. Year Banner (Clamped to edges for visibility, now sitting flush with the line)
                if (!_isRoundResultShowing)
                  AnimatedPositioned(
                    duration: Duration(milliseconds: _isLockHovered ? 400 : 60),
                    curve: _isLockHovered ? Curves.elasticOut : Curves.linear,
                    left: ((((_isLockHovered && _selectedYear != null) ? _selectedYear! : _focusYear) - _startYear) * yearWidth + (yearWidth / 2) - 50).clamp(20.0, width - 120.0),
                    top: 115, // Starts exactly where the line ends (75 + 40)
                    width: 100,
                    height: 40,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, spreadRadius: 2)
                          ],
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                        ),
                        child: Text(
                          "${(_isLockHovered && _selectedYear != null) ? _selectedYear! : _focusYear}", 
                          style: GoogleFonts.outfit(
                            color: Colors.white, 
                            fontSize: 22, 
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          )
                        ),
                      ),
                    ),
                  ),

                // 3. The "Moment of Truth" (Correct Year Reveal - Golden Highlight)
                if (_isRoundResultShowing && _currentSong != null)
                  ...[
                    // Vertical Gold Glow Line
                    Positioned(
                      left: (int.parse(_currentSong!.year) - _startYear) * yearWidth + (yearWidth / 2) - 2.5,
                      top: 75,
                      height: 48,
                      width: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(color: Colors.amber.withOpacity(0.8), blurRadius: 15, spreadRadius: 3),
                            BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 5),
                          ]
                        ),
                      ),
                    ),
                    
                    // "ACTUAL YEAR" Banner
                    Positioned(
                      left: ((int.parse(_currentSong!.year) - _startYear) * yearWidth + (yearWidth / 2) - 60).clamp(20.0, width - 140.0),
                      top: 115,
                      width: 120,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(color: Colors.amber.withOpacity(0.4), blurRadius: 12)
                              ],
                            ),
                            child: Text(
                              (_t('actualYear') ?? "ACTUAL").toUpperCase(), 
                              style: GoogleFonts.outfit(
                                color: Colors.black, 
                                fontSize: 10, 
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              )
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${_currentSong!.year}",
                            style: GoogleFonts.outfit(
                              color: Colors.amber, 
                              fontSize: 28, 
                              fontWeight: FontWeight.w900,
                              shadows: [
                                const Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 2))
                              ]
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                // 4. Sequential Showcase Banner (Individual Player Focus)
                if (_isRoundResultShowing && _showcasedPlayerIndex >= 0 && _currentSong != null)
                  () {
                    final playerName = widget.playerNames[_showcasedPlayerIndex];
                    final playerColor = widget.playerColors[playerName] ?? Colors.white;
                    final guessYear = _platformGuesses[playerName] ?? _startYear;
                    final actualYear = int.parse(_currentSong!.year);
                    final diff = guessYear - actualYear;
                    final diffSign = diff > 0 ? "+" : "";

                    return AnimatedPositioned(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeInOutBack,
                      left: ((guessYear - _startYear) * yearWidth + (yearWidth / 2) - 80).clamp(10.0, width - 170.0),
                      top: 15, // Showcase banner sits on TOP of the timeline
                      width: 160,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: playerColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: playerColor.withOpacity(0.5), width: 2),
                              boxShadow: [
                                BoxShadow(color: playerColor.withOpacity(0.3), blurRadius: 10)
                              ]
                            ),
                            child: Column(
                              children: [
                                Text(
                                  playerName.toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    color: playerColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "$guessYear",
                                      style: GoogleFonts.robotoMono(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: diff == 0 ? Colors.greenAccent : (diff.abs() <= 2 ? Colors.orangeAccent : Colors.redAccent),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "$diffSign$diff",
                                        style: GoogleFonts.robotoMono(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Connecting Arrow down to the tick
                          Icon(Icons.arrow_drop_down_rounded, color: playerColor, size: 24),
                        ],
                      ),
                    );
                  }(),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildReadyOverlay() {
    final playerName = widget.playerNames[_currentGuesserIndex];
    final playerColor = widget.playerColors[playerName] ?? const Color(0xFF6C63FF);

    return Positioned.fill(
      child: FadeIn(
        duration: const Duration(milliseconds: 400),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withOpacity(0.7),
            child: Center(
              child: ZoomIn(
                duration: const Duration(milliseconds: 500),
                child: Container(
                  width: 380,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2C),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: playerColor, width: 2),
                    boxShadow: [
                      BoxShadow(color: playerColor.withOpacity(0.3), blurRadius: 30, spreadRadius: 5)
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _t('readyPrompt').toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: Colors.white60,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        playerName,
                        style: GoogleFonts.outfit(
                          color: playerColor,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(color: playerColor.withOpacity(0.5), blurRadius: 15)
                          ]
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: 220,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () => setState(() => _isReadyOverlayVisible = false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: playerColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 10,
                          ),
                          child: Text(
                            _t('startNow'),
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTick(int year, double width, Color color) {
    bool isMilestone = year % 10 == 0;
    return Positioned(
      left: (year - _startYear) * width, 
      top: 0, 
      bottom: 0, 
      width: width, 
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The Tick Line (Always centered on the horizontal line)
          Center(
            child: Container(
              width: 2.0, 
              height: 12, 
              decoration: BoxDecoration(
                color: isMilestone ? Colors.white70 : Colors.white12,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          // The Year Label (Only for milestones)
          if (isMilestone) 
            Positioned(
              top: 81, // Center (75) + Half of tick height (6)
              left: -20, 
              right: -20,
              child: Center(
                child: Text(
                  "$year", 
                  style: GoogleFonts.outfit(
                    color: Colors.white60, 
                    fontSize: 13, 
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  )
                ),
              ),
            )
        ]
      )
    );
  }

  // _buildDetailedTimeline removed as per user request


  Widget _buildControlsArea(Color color) {
    return Container(
      height: 120,
      child: Center(
        child: _isRoundResultShowing 
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() => _showScoreOverlay = true);
                    _audioPlayer.stop(); // Stop song only when viewing final scores
                    _showcaseTimer?.cancel();
                    _showcasedPlayerIndex = -1;
                  }, 
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                  child: Text(_t('viewResults'))
                ),
              ],
            )
          : (widget.roomCode != null
              ? (_allPlayersGuessed
                  ? (!_isRevealMode
                      ? ElevatedButton(
                          onPressed: _startRevealSequence,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          ),
                          child: Text(
                            widget.uiLanguage == 'ar' ? 'كشف تخمينات اللاعبين' : 'REVEAL PLAYER GUESSES',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        )
                      : Text(
                          widget.uiLanguage == 'ar' 
                              ? 'جاري الكشف... (${_revealIndex}/${_revealedPlayers.length})'
                              : 'Revealing guesses... (${_revealIndex}/${_revealedPlayers.length})',
                          style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                        ))
                  : Text(
                      widget.uiLanguage == 'ar'
                          ? 'في انتظار تخمينات اللاعبين (${_submittedGuesses.length}/${widget.playerNames.length})...'
                          : 'Waiting for player guesses (${_submittedGuesses.length}/${widget.playerNames.length})...',
                      style: const TextStyle(color: Colors.white38, fontSize: 16),
                    ))
              : (_selectedYear != null 
                  ? MouseRegion(
                      onEnter: (_) => setState(() => _isLockHovered = true),
                      onExit: (_) => setState(() => _isLockHovered = false),
                      child: ElevatedButton(
                        onPressed: _submitGuess, 
                        style: ElevatedButton.styleFrom(backgroundColor: color), 
                        child: Text("${_t('lockIn')} $_selectedYear")
                      ),
                    ) 
                  : Text(_t('selectYear'), style: const TextStyle(color: Colors.white38)))),
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        height: 100, // Reduced height since the card is moved
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.8), Colors.transparent]
          )
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exit Button
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: () => Navigator.pop(context),
            ),
            
            const SizedBox(width: 10),
            
            // Player Status Chips (Now has full width to breathe)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: widget.playerNames.map((name) {
                      final isCurrent = widget.roomCode == null && widget.playerNames[_currentGuesserIndex] == name && !_isRoundResultShowing;
                      final isHovered = _hoveredPlayerName == name;
                      final hasGuessed = widget.roomCode != null ? _submittedGuesses.containsKey(name) : _platformGuesses.containsKey(name);
                      final color = widget.playerColors[name] ?? Colors.blueAccent;
                      
                      return MouseRegion(
                        onEnter: (_) => setState(() => _hoveredPlayerName = name),
                        onExit: (_) => setState(() => _hoveredPlayerName = null),
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 200),
                          scale: isHovered ? 1.15 : 1.0,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isHovered 
                                ? color.withOpacity(0.3) 
                                : (isCurrent ? color.withOpacity(0.1) : Colors.white.withOpacity(0.05)),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isHovered 
                                  ? color 
                                  : (isCurrent ? color.withOpacity(0.5) : (hasGuessed ? Colors.white38 : Colors.transparent)), 
                                width: isHovered ? 2 : 1.5
                              ),
                              boxShadow: (isCurrent || isHovered) 
                                ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: isHovered ? 12 : 8)] 
                                : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Visibility(
                                  visible: hasGuessed,
                                  maintainSize: true, 
                                  maintainAnimation: true, 
                                  maintainState: true,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Icon(Icons.check_circle, color: color, size: 12),
                                  ),
                                ),
                                Text(
                                  name.toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    color: (isCurrent || isHovered) ? Colors.white : (hasGuessed ? Colors.white70 : Colors.white54),
                                    fontWeight: (isCurrent || isHovered) ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 11.5,
                                    height: 1.0,
                                  )
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMysterySongCard() {
    if (_currentSong == null) return const SizedBox.shrink();
    final isAr = widget.uiLanguage == 'ar';
    
    return Positioned(
      left: 30,
      bottom: 30,
      child: MouseRegion(
        onEnter: (_) => setState(() => _showFacts = true),
        onExit: (_) => setState(() => _showFacts = false),
      child: Hero(
        tag: 'song_art',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _showFacts ? 130 : 110,
          height: _showFacts ? 130 : 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: (widget.playerColors[widget.playerNames[_currentGuesserIndex]] ?? Colors.blueAccent).withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 2
              )
            ],
            image: _currentSong!.artworkUrl != null
                ? DecorationImage(image: NetworkImage(_currentSong!.artworkUrl!), fit: BoxFit.cover)
                : null,
            color: Colors.black45,
          ),
          child: Stack(
            children: [
              if (_currentSong!.artworkUrl == null)
                const Center(child: Icon(Icons.music_note, color: Colors.white24, size: 40)),
              
              // Glass Overlay
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
              ),
              
              // Reveal Title/Artist on hover or result
              if (_showFacts || _isRoundResultShowing)
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15))
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isAr ? (_currentSong!.titleAr ?? _currentSong!.title) : _currentSong!.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isAr ? (_currentSong!.artistAr ?? _currentSong!.artist) : _currentSong!.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildFactsPopup() {
    final color = widget.playerColors[widget.playerNames[_currentGuesserIndex]] ?? Colors.blueAccent;
    return Center(
      child: FadeIn(
        duration: const Duration(milliseconds: 500),
        child: Container(
          width: 550,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glass Pedestal Panel
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF1E293B).withOpacity(0.85),
                          const Color(0xFF0F172A).withOpacity(0.95),
                        ]
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: color.withOpacity(0.4), 
                        width: 2
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.15), 
                          blurRadius: 30, 
                          spreadRadius: 5
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4), 
                          blurRadius: 10, 
                          offset: const Offset(0, 10)
                        )
                      ]
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome, color: color, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              _t('songFacts').toUpperCase(),
                              style: GoogleFonts.outfit(
                                color: color,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 4
                              )
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.auto_awesome, color: color, size: 20),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 24),
                        
                        // The Random Fact Label
                        Text(
                          _currentRoundFact ?? _t('noFacts'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 24,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: color.withOpacity(0.5), 
                                blurRadius: 15
                              )
                            ]
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultModal() {
    return TsRoundResultModal(
      scores: _playerScores, previousScores: _previousScores, playerColors: widget.playerColors, maxScore: widget.startingPoints,
      loserName: _roundLoserName ?? "", onContinue: _continueToNextRound, onHide: () => setState(() => _showScoreOverlay = false),
      platformGuesses: _platformGuesses, isGameOver: _isGameOver, actualYear: int.tryParse(_currentSong?.year ?? "") ?? 0,
      uiLanguage: widget.uiLanguage,
    );
  }
}

class WavingFlag extends StatelessWidget {
  final Color color; final double size;
  const WavingFlag({super.key, required this.color, required this.size});
  @override
  Widget build(BuildContext context) { return Icon(Icons.flag, color: color, size: size); }
}
