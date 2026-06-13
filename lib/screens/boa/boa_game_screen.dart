import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart';
import 'package:animate_do/animate_do.dart';

import '../../models/song.dart';
import '../../services/song_repository.dart';
import '../../services/itunes_service.dart';
import '../../services/audio_cache_service.dart';
import 'widgets/headphone_score_overlay.dart';
import 'widgets/boa_game_over_modal.dart';
import 'boa_result_screen.dart';
import '../../services/background_music_service.dart';
import '../../services/firebase_service.dart';

class BoaGameScreen extends StatefulWidget {
  final int targetScore;
  final List<String> playerNames;
  final String? roomCode;

  const BoaGameScreen({
    super.key,
    required this.targetScore,
    required this.playerNames,
    this.uiLanguage = 'en',
    this.roomCode,
  });

  final String uiLanguage;

  @override
  State<BoaGameScreen> createState() => _BoaGameScreenState();
}

class _BoaGameScreenState extends State<BoaGameScreen> with SingleTickerProviderStateMixin {
  final GlobalKey _timelineViewportKey = GlobalKey();
  final ValueNotifier<int?> _hoveredDropZoneIndex = ValueNotifier<int?>(null);
  int? _correctInsertionIndex;
  int? _wrongPlacementIndex;
  int? _lastPlacedCorrectIndex;
  late AnimationController _celebrationController;
  final Map<String, List<Song>> _timelines = {};
  int _currentPlayerIndex = 0;
  List<Song> _deck = [];
  Song? _currentMysteryCard;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isLoading = true;
  bool _isRoundResultShowing = false;
  String? _roundFeedbackText;
  bool _lastPlacementCorrect = false;
  bool _isWaitingForTurnStart = true;
  bool _isDragging = false; 
  bool _isGameOver = false; 
  bool _isTargetReached = false; 
  
  bool _canScrollLeft = false;
  bool _canScrollRight = false;
  bool _isResultCardHovered = false; 
  Offset? _lastGlobalPosition;
  bool _isDiskSpaceError = false;

  String? _errorMessage;
  late final SongRepository _repository;
  StreamSubscription? _firebaseSubscription;
  
  String get formattedName => widget.playerNames[_currentPlayerIndex];
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    try {
      _repository = SongRepository();
      MediaCacheService().init();
      for (var name in widget.playerNames) {
        _timelines[name] = [];
      }
    _scrollController.addListener(_updateScrollIndicators);
    _celebrationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollIndicators());
    
    if (widget.roomCode != null) {
      _firebaseSubscription = FirebaseService().listenToRoomCustom(widget.roomCode!).listen((data) {
        if (!mounted) return;
        if (data.isEmpty) return;

        if (data['boaChoice'] != null) {
          final choice = Map<String, dynamic>.from(data['boaChoice'] as Map);
          final slotIndex = choice['selectedSlot'] as int?;
          final playerName = choice['playerName'] as String?;

          // If the player is the active player and selected a slot, and we are not already showing results
          if (slotIndex != null && 
              playerName == formattedName && 
              !_isRoundResultShowing && 
              !_isWaitingForTurnStart && 
              _currentMysteryCard != null) {
            _handleCardDrop(slotIndex);
            _hoveredDropZoneIndex.value = null;
          }
        }

        if (data['nextRoundRequested'] == true && _isRoundResultShowing) {
          FirebaseService().resetNextRoundRequest(widget.roomCode!);
          _nextPlayer();
        }

        if (data['startTurnRequested'] == true && _isWaitingForTurnStart) {
          _startTurn();
        }

        // Live scroll synchronization from active player's phone
        final int? currentSlotIndex = data['currentSlotIndex'] != null 
            ? int.tryParse(data['currentSlotIndex'].toString()) 
            : null;
        _logToFile("Host listener: currentSlotIndex = $currentSlotIndex, _isWaitingForTurnStart = $_isWaitingForTurnStart, _currentMysteryCard = ${_currentMysteryCard != null}");
        if (currentSlotIndex != null && 
            !_isWaitingForTurnStart && 
            _currentMysteryCard != null) {
          
          _hoveredDropZoneIndex.value = currentSlotIndex;

          if (_scrollController.hasClients && !_isDragging) {
            double targetOffset = _getScrollOffsetForSlot(currentSlotIndex);
            double slotWidth = 40.0;
            if (_isRoundResultShowing && !_lastPlacementCorrect) {
              if (_correctInsertionIndex == currentSlotIndex || _wrongPlacementIndex == currentSlotIndex) {
                slotWidth = 120.0;
              }
            }
            double scrollTarget = targetOffset + (slotWidth / 2) - 60.0;
            _logToFile("Animate to scrollTarget: $scrollTarget, maxScrollExtent: ${_scrollController.position.maxScrollExtent}");
            _scrollController.animateTo(
              scrollTarget.clamp(0.0, _scrollController.position.maxScrollExtent),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            );
          } else {
            _logToFile("Cannot animate: hasClients = ${_scrollController.hasClients}, isDragging = $_isDragging");
          }
        }
      });
    }

    _startGame();
    } catch (e) {
       setState(() => _errorMessage = "INIT ERROR: $e");
    }
  }

  @override
  void dispose() {
    _firebaseSubscription?.cancel();
    _scrollController.removeListener(_updateScrollIndicators);
    _stopAutoScroll();
    _scrollController.dispose();
    _celebrationController.dispose();
    _hoveredDropZoneIndex.dispose();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _updateScrollIndicators() {
    if (!_scrollController.hasClients) return;
    setState(() {
      _canScrollLeft = _scrollController.position.pixels > 10;
      _canScrollRight = _scrollController.position.maxScrollExtent > 20 && 
                        _scrollController.position.pixels < _scrollController.position.maxScrollExtent - 10;
    });
  }

  Future<void> _startGame() async {
    try {
      if (!mounted) return;
      if (_repository.allSongs.isEmpty) await _repository.loadSongs();
      _deck = _repository.getValidSongs()..shuffle();
      if (_deck.isEmpty) { setState(() => _errorMessage = "DECK EMPTY!"); return; }

      for (var name in widget.playerNames) {
        if (_deck.isNotEmpty) {
           final song = _deck.removeLast();
           _timelines[name]!.add(song);
           if (song.artworkUrl == null) {
              ITunesService.fetchArtwork(song.artist, song.title).then((url) {
                  if (url != null && mounted) setState(() => song.artworkUrl = url);
              });
           }
        }
      }
      
      if (widget.roomCode != null) {
        await FirebaseService().updateBoaState(
          widget.roomCode!,
          activePlayer: widget.playerNames[_currentPlayerIndex],
          mysterySong: {},
          timelineSongs: [],
          status: 'playing',
          placementResult: null,
          currentSlotIndex: 0,
        );
        await FirebaseService().setWaitingForReady(widget.roomCode!, true);
      }

      if (mounted) setState(() { _isLoading = false; _isWaitingForTurnStart = true; });
    } catch (e) { setState(() => _errorMessage = "START ERROR: $e"); }
  }

  void _startTurn() async {
    if (_deck.isEmpty) return;

    final timeline = _timelines[formattedName]!;
    final yearsInTimeline = timeline.map((s) => s.year).toSet();
    
    Song? nextSong;
    int index = _deck.length - 1;
    while (index >= 0) {
      if (!yearsInTimeline.contains(_deck[index].year)) {
        nextSong = _deck.removeAt(index);
        break;
      }
      index--;
    }

    final nextSongNonNull = nextSong ?? _deck.removeLast();

    setState(() {
       _isWaitingForTurnStart = false;
       _isRoundResultShowing = false;
       _currentMysteryCard = nextSongNonNull;
       _roundFeedbackText = null;
    });

    if (widget.roomCode != null) {
      await FirebaseService().clearBoaChoice(widget.roomCode!);
      final timeline = _timelines[formattedName]!;
      final List<Map<String, dynamic>> timelineMaps = timeline.map((s) => {
        'title': s.title,
        'artist': s.artist,
        'year': s.year,
        'artworkUrl': s.artworkUrl ?? '',
      }).toList();

      final Map<String, dynamic> mysteryMap = {
        'title': nextSongNonNull.title,
        'artist': nextSongNonNull.artist,
        'artworkUrl': nextSongNonNull.artworkUrl ?? '',
      };

      await FirebaseService().updateBoaState(
        widget.roomCode!,
        activePlayer: formattedName,
        mysterySong: mysteryMap,
        timelineSongs: timelineMaps,
        placementResult: null,
        currentSlotIndex: 0,
      );
      await FirebaseService().setWaitingForReady(widget.roomCode!, false);
    }

    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      String playUrl = nextSongNonNull.link;
      final cachedPath = MediaCacheService().getCachedPath(nextSongNonNull.link);
      if (cachedPath != null) {
        playUrl = cachedPath;
        await _audioPlayer.play(DeviceFileSource(playUrl));
      } else {
        await _audioPlayer.play(UrlSource(playUrl));
        MediaCacheService().cacheFile(nextSongNonNull.link);
      }
      if (nextSongNonNull.artworkUrl == null) {
         ITunesService.fetchArtwork(nextSongNonNull.artist, nextSongNonNull.title).then((url) {
            if (url != null && mounted) setState(() => nextSongNonNull.artworkUrl = url);
         });
      }
    } catch (e) { 
      debugPrint("Audio Error: $e");
      if (e.toString().contains("enough space on the disk") || e.toString().contains("80070070")) {
        if (mounted) setState(() => _isDiskSpaceError = true);
      }
    }
  }

  String _t(String key) {
    final isAr = widget.uiLanguage == 'ar';
    final Map<String, Map<String, String>> strings = {
      'en': {
        'finalRound': 'FINAL ROUND',
        'startTurn': 'START TURN',
        'correct': 'IN TUNE!',
        'wrong': 'OUT OF SYNC!',
        'continue': 'CONTINUE',
        'gameOver': 'GAME OVER',
        'player': 'PLAYER',
        'targetReached': 'TARGET REACHED!',
        'finishGame': 'FINISH GAME',
        'setup': 'BACK',
        'readyPrompt': 'It\'s your turn:',
        'startNow': 'START NOW',
      },
      'ar': {
        'finalRound': 'الجولة النهائية',
        'startTurn': 'بدء الدور',
        'correct': 'إيقاع مثالي!',
        'wrong': 'ترتيب خاطئ!',
        'continue': 'استمرار',
        'gameOver': 'انتهت اللعبة',
        'player': 'لاعب',
        'targetReached': 'تم الوصول للهدف!',
        'finishGame': 'إنهاء اللعبة',
        'setup': 'عودة',
        'readyPrompt': 'دورك:',
        'startNow': 'ابدأ الآن',
      },
    };
    return strings[isAr ? 'ar' : 'en']![key] ?? key;
  }

  void _logToFile(String message) {
    try {
      final file = File('c:/Projects/music_game_v2/debug_scroll_logs.txt');
      file.writeAsStringSync("${DateTime.now().toIso8601String()}: $message\n", mode: FileMode.append);
    } catch (e) {}
  }

  double _getScrollOffsetForSlot(int index) {
    double offset = 0.0;
    final timelineLen = _timelines[widget.playerNames[_currentPlayerIndex]]?.length ?? 0;
    for (int i = 0; i < index; i++) {
      double dzWidth = 40.0;
      if (_isRoundResultShowing && !_lastPlacementCorrect) {
        if (_correctInsertionIndex == i || _wrongPlacementIndex == i) {
          dzWidth = 120.0;
        }
      }
      offset += dzWidth;
      if (i < timelineLen) {
        offset += 136.0; // 120 card + 16 horizontal margins
      }
    }
    return offset;
  }

  void _handleCardDrop(int dropIndex) async {
    if (_currentMysteryCard == null) return;
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
          _roundFeedbackText = isValid ? _t('correct') : _t('wrong');
          if (isValid) {
             _playCorrectAudioWithDucking();
             timeline.insert(dropIndex, _currentMysteryCard!);
             _lastPlacedCorrectIndex = dropIndex;
             _celebrationController.repeat(reverse: true);
             if (timeline.length >= widget.targetScore) setState(() => _isTargetReached = true);
          } else {
             _playWrongAudioWithDucking();
             _wrongPlacementIndex = dropIndex;
             int correctIndex = timeline.length;
             for (int i = 0; i < timeline.length; i++) {
                int year = int.tryParse(timeline[i].year) ?? 0;
                if (mysteryYear < year) { correctIndex = i; break; }
             }
             _correctInsertionIndex = correctIndex;
             
             WidgetsBinding.instance.addPostFrameCallback((_) {
               if (_scrollController.hasClients) {
                 double screenWidth = MediaQuery.of(context).size.width;
                 double targetX = 100.0 + (correctIndex * 176.0);
                 double centralOffset = targetX - (screenWidth / 2) + 88.0;
                 _scrollController.animateTo(
                   centralOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
                   duration: const Duration(milliseconds: 800),
                   curve: Curves.easeOutCubic,
                 );
               }
             });
          }
          _isRoundResultShowing = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollIndicators());
       });

       if (widget.roomCode != null) {
         FirebaseService().updateBoaState(
           widget.roomCode!,
           activePlayer: currentPlayerName,
           mysterySong: {
             'title': _currentMysteryCard!.title,
             'artist': _currentMysteryCard!.artist,
             'artworkUrl': _currentMysteryCard!.artworkUrl ?? '',
           },
           timelineSongs: timeline.map((s) => {
             'title': s.title,
             'artist': s.artist,
             'year': s.year,
             'artworkUrl': s.artworkUrl ?? '',
           }).toList(),
           placementResult: isValid ? 'correct' : 'wrong',
         );
       }
    }
  }

  void _handleGameOver() {
    _audioPlayer.stop();
    setState(() => _isGameOver = true);
    BackgroundMusicService.instance.playSfx('correct.mp3');
    String winnerName = "";
    int highScore = -1;
    bool isTie = false;
    _timelines.forEach((name, timeline) {
       if (timeline.length > highScore) { highScore = timeline.length; winnerName = name; isTie = false; }
       else if (timeline.length == highScore) isTie = true;
    });
    final displayWinnerName = isTie ? (widget.uiLanguage == 'ar' ? 'تعادل!' : "IT'S A TIE!") : winnerName;
    showDialog(
      context: context, barrierDismissible: false,
      builder: (context) => BoaGameOverModal(
        winnerName: displayWinnerName,
        winnerScore: highScore,
        uiLanguage: widget.uiLanguage,
        onViewResults: () { Navigator.pop(context); _navigateToResults(); },
        onContinue: () { Navigator.pop(context); setState(() { _isRoundResultShowing = true; _roundFeedbackText = _t('gameOver'); }); },
      ),
    );
  }

  void _navigateToResults() {
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(
        builder: (_) => BoaResultScreen(
          timelines: _timelines, 
          targetScore: widget.targetScore,
          uiLanguage: widget.uiLanguage,
        ),
      ),
    );
  }

  void _nextPlayer() async {
     if (_isGameOver) return;
     _audioPlayer.stop(); 
     bool isLastPlayerOfRound = _currentPlayerIndex == widget.playerNames.length - 1;
     if (_isTargetReached && isLastPlayerOfRound) { _handleGameOver(); return; }
     
     if (widget.roomCode != null) {
       await FirebaseService().clearBoaChoice(widget.roomCode!);
       await FirebaseService().updateBoaState(
         widget.roomCode!,
         activePlayer: widget.playerNames[(_currentPlayerIndex + 1) % widget.playerNames.length],
         mysterySong: {},
         timelineSongs: [],
         placementResult: null,
       );
       await FirebaseService().setWaitingForReady(widget.roomCode!, true);
     }

     setState(() {
        _currentPlayerIndex = (_currentPlayerIndex + 1) % widget.playerNames.length;
        _isWaitingForTurnStart = true;
        _isRoundResultShowing = false;
        _currentMysteryCard = null; 
        _correctInsertionIndex = null;
        _wrongPlacementIndex = null;
     });
  }

  void _stopAutoScroll() => _scrollTimer?.cancel();

  Future<void> _clearCache() async {
    await MediaCacheService().clearCache();
    if (mounted) {
      setState(() {
        _isDiskSpaceError = false;
      });
      // Try to restart audio for current song
      if (_currentMysteryCard != null) {
        _playCurrentMysteryAudio(_currentMysteryCard!);
      }
    }
  }

  Future<void> _playCurrentMysteryAudio(Song song) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      String playUrl = song.link;
      final cachedPath = MediaCacheService().getCachedPath(song.link);
      if (cachedPath != null) {
        playUrl = cachedPath;
        await _audioPlayer.play(DeviceFileSource(playUrl));
      } else {
        await _audioPlayer.play(UrlSource(playUrl));
        MediaCacheService().cacheFile(song.link);
      }
    } catch (e) { debugPrint("Audio Error: $e"); }
  }

  int? _calculateIndexFromGlobal(Offset globalPos) {
    if (!mounted) return null;
    final RenderBox? box = _timelineViewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;

    final Offset local = box.globalToLocal(globalPos + const Offset(60, 90));
    final double x = local.dx;
    final double y = local.dy;

    // Horizon Band check in fallback as well
    final centerY = box.size.height / 2;
    if (y < centerY - 175 || y > centerY + 175) return null;

    final scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    const double pitch = 176.0;
    final double startX = widget.roomCode != null
        ? (MediaQuery.of(context).size.width / 2 - 60)
        : 100.0;
    final relativeX = x + scrollOffset - startX;
    int nearestIndex = (relativeX / pitch).round();
    int maxIndex = _timelines[formattedName]?.length ?? 0;
    return nearestIndex.clamp(0, maxIndex);
  }

  Future<void> _playCorrectAudioWithDucking() async {
    try { await _audioPlayer.setVolume(0.2); await BackgroundMusicService.instance.playSfx('correct.mp3'); await Future.delayed(const Duration(milliseconds: 1500)); await _audioPlayer.setVolume(1.0); } catch (_) {}
  }

  Future<void> _playWrongAudioWithDucking() async {
    try { await _audioPlayer.setVolume(0.2); await BackgroundMusicService.instance.playSfx('wrong.mp3'); await Future.delayed(const Duration(milliseconds: 1500)); await _audioPlayer.setVolume(1.0); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) return Scaffold(backgroundColor: Colors.red, body: Center(child: Text(_errorMessage!, style: const TextStyle(color:Colors.white))));
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final isAr = widget.uiLanguage == 'ar';
    final formattedName = widget.playerNames[_currentPlayerIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, toolbarHeight: 120,
        leading: Padding(padding: const EdgeInsets.all(8.0), child: Image.asset('assets/Before_or_after_logo.png', fit: BoxFit.contain)),
        leadingWidth: 200,
        title: Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Column(
            children: [
              if (_isTargetReached && !_isGameOver) FadeInDown(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)), child: Text(_t('finalRound'), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
              Container(padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16), decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(30)), child: Text(formattedName.toUpperCase())),
              const SizedBox(height: 8),
              _buildProgressTimeline(_timelines[formattedName]!.length, widget.targetScore, Theme.of(context).primaryColor),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          if (!kIsWeb)
            IconButton(
              icon: const Icon(Icons.fullscreen_rounded, color: Colors.black54),
              onPressed: () async {
                final isFull = await windowManager.isFullScreen();
                await windowManager.setFullScreen(!isFull);
              },
              tooltip: 'Fullscreen',
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              onPressed: () { _audioPlayer.stop(); Navigator.pop(context); },
              child: Text(_t('setup'), style: GoogleFonts.outfit(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ]
      ),
      body: Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: DragTarget<Song>(
          onWillAccept: (song) => !_isRoundResultShowing,
          onMove: (details) {
            if (!_isDragging || _isRoundResultShowing) return;
            
            _lastGlobalPosition = details.offset; // Store for fallback
            
            final RenderBox? box = _timelineViewportKey.currentContext?.findRenderObject() as RenderBox?;
            if (box == null) return;

            // Use CENTER of feedback card for much more intuitive aiming
            final Offset centerGlobal = details.offset + const Offset(60, 90); 
            final Offset local = box.globalToLocal(centerGlobal);
            
            final x = local.dx;
            final y = local.dy;
            
            // Horizon Band Constraint:
            // Only accept drops if the card is vertically centered on the timeline (350px band)
            final centerY = box.size.height / 2;
            if (y < centerY - 175 || y > centerY + 175) {
               if (_hoveredDropZoneIndex.value != null) _hoveredDropZoneIndex.value = null;
               return;
            }

            final scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
            const double pitch = 176.0;
            final double startX = widget.roomCode != null
                ? (MediaQuery.of(context).size.width / 2 - 60)
                : 100.0;

            // Math: Local position in viewport + scroll amount - padding
            final relativeX = x + scrollOffset - startX;
            int nearestIndex = (relativeX / pitch).round();
            
            int maxIndex = _timelines[formattedName]?.length ?? 0;
            int targetIndex = nearestIndex.clamp(0, maxIndex);
            
            if (_hoveredDropZoneIndex.value != targetIndex) {
              _hoveredDropZoneIndex.value = targetIndex;
            }
          },
          onLeave: (_) {
             // We no longer nullify on leave to prevent the 'blink' race condition.
             // The selection will only change when moving to another slot or ending the drag.
          },
          onAccept: (song) {
            // Standard onAccept fallback for robustness
            int? index = _hoveredDropZoneIndex.value;
            if (index == null && _lastGlobalPosition != null) {
               index = _calculateIndexFromGlobal(_lastGlobalPosition!);
            }
            if (index != null) _handleCardDrop(index);
            _hoveredDropZoneIndex.value = null;
          },
          // @override
          // Note: Using onAcceptWithDetails for newer Flutter versions to get the exact drop offset.
          // Fallback to onAccept logic for broader compatibility.
          builder: (context, candidateData, rejectedData) => Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: SizedBox(
                        height: 550,
                        width: double.infinity, 
                        child: Stack(
                          children: [
                            Center( 
                              child: Listener(
                                onPointerSignal: (pointerSignal) {
                                  if (pointerSignal is PointerScrollEvent) {
                                    final newOffset = _scrollController.offset + pointerSignal.scrollDelta.dy;
                                    _scrollController.jumpTo(newOffset.clamp(0.0, _scrollController.position.maxScrollExtent));
                                  }
                                },
                                child: Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: SingleChildScrollView(
                                    key: _timelineViewportKey,
                                    controller: _scrollController,
                                    scrollDirection: Axis.horizontal, 
                                    clipBehavior: Clip.none, // Allow enlarged cards to spill out
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: widget.roomCode != null
                                        ? EdgeInsets.symmetric(
                                            horizontal: MediaQuery.of(context).size.width / 2 - 60,
                                            vertical: 40,
                                          )
                                        : const EdgeInsets.symmetric(horizontal: 100, vertical: 40),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        for (int i = 0; i <= (_timelines[formattedName]?.length ?? 0); i++) ...[
                                          _buildDropZone(i),
                                          if (i < (_timelines[formattedName]?.length ?? 0)) _buildTimelineCard(_timelines[formattedName]![i], i)
                                        ]
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(child: _isWaitingForTurnStart ? const SizedBox.shrink() : (_isRoundResultShowing ? _buildResultFeedback() : _buildMysteryDraggable())),
                  ),
                ],
              ),
              if (widget.roomCode != null && 
                  !_isRoundResultShowing && 
                  !_isWaitingForTurnStart && 
                  _currentMysteryCard != null)
                Positioned.fill(
                  child: ValueListenableBuilder<int?>(
                    valueListenable: _hoveredDropZoneIndex,
                    builder: (context, hoveredIdx, _) {
                      if (hoveredIdx == null) return const SizedBox.shrink();
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final double bodyHeight = constraints.maxHeight;
                          final double flex3Height = bodyHeight * 3 / 5;
                          final double flex2Height = bodyHeight * 2 / 5;

                          final double timelineCardBottom = flex3Height / 2 + 90;
                          final double mysteryCardTop = flex3Height + (flex2Height / 2) - 90;

                          if (mysteryCardTop <= timelineCardBottom) return const SizedBox.shrink();

                          return Stack(
                            children: [
                              Positioned(
                                left: 0,
                                right: 0,
                                top: timelineCardBottom,
                                height: mysteryCardTop - timelineCardBottom,
                                child: _AnimatedArrowPainterWidget(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              if (_isWaitingForTurnStart && !_isLoading) _buildReadyScreen(formattedName),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressTimeline(int current, int target, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: List.generate(target, (index) => Container(margin: const EdgeInsets.symmetric(horizontal: 4), width: 12, height: 12, decoration: BoxDecoration(color: index < current ? color : Colors.grey[200], shape: BoxShape.circle))));
  }

  Widget _buildReadyScreen(String playerName) {
    bool isAr = widget.uiLanguage == 'ar';
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        color: Colors.white.withOpacity(0.98),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeInDown(
                child: Image.asset('assets/Before_or_after_logo.png', height: 220),
              ),
              const SizedBox(height: 60),
              ZoomIn(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  _t('readyPrompt'),
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    color: Colors.black54,
                    letterSpacing: isAr ? 0 : 4,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              ZoomIn(
                delay: const Duration(milliseconds: 300),
                child: Text(
                  playerName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).primaryColor,
                    shadows: [
                      Shadow(color: Theme.of(context).primaryColor.withOpacity(0.3), blurRadius: 40),
                    ],
                  ),
                ),
              ),
              if (_isDiskSpaceError)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Disk Space Full! Audio may not play.",
                        style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _clearCache,
                        icon: const Icon(Icons.cleaning_services),
                        label: const Text("Clear Audio Cache"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _startTurn,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  backgroundColor: Theme.of(context).primaryColor,
                  elevation: 10,
                ),
                child: Text(
                  _t('startNow'),
                  style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultFeedback() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Padding(
        padding: const EdgeInsets.all(40.0), 
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            if (!_lastPlacementCorrect && _currentMysteryCard != null) ...[
              _ResultCardHoverWrapper(
                onHoverChanged: (isHovered) => setState(() => _isResultCardHovered = isHovered),
                child: _buildSongCard(_currentMysteryCard!),
              ),
              const SizedBox(height: 12),
              Opacity(
                opacity: _isResultCardHovered ? 0 : 1,
                child: Text(
                  _currentMysteryCard!.year, 
                  style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.black)
                ),
              ),
              const SizedBox(height: 20),
            ],
            _lastPlacementCorrect 
              ? FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  child: Text(_roundFeedbackText ?? "", style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.green))
                )
              : ShakeX(
                  duration: const Duration(milliseconds: 600),
                  child: Text(_roundFeedbackText ?? "", style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.red))
                ),            const SizedBox(height: 20), 
            ElevatedButton(
              onPressed: _isGameOver ? _navigateToResults : _nextPlayer, 
              style: ElevatedButton.styleFrom(
                backgroundColor: _isGameOver ? Colors.redAccent : null,
                foregroundColor: _isGameOver ? Colors.white : null,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: Text(
                _isGameOver ? _t('finishGame') : _t('continue'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              )
            )
          ]
        ),
      ),
    );
  }


  Widget _buildMysteryDraggable() {
    if (_currentMysteryCard == null) return const SizedBox.shrink();
    return Draggable<Song>(
      data: _currentMysteryCard,
      feedback: ValueListenableBuilder<int?>(
        valueListenable: _hoveredDropZoneIndex,
        builder: (context, hoveredIdx, _) {
          bool isReady = hoveredIdx != null;
          return Material(
            color: Colors.transparent,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildSongCard(_currentMysteryCard!, isHighlighted: isReady),
              ],
            ),
          );
        },
      ),
      childWhenDragging: Opacity(opacity: 0.2, child: _buildSongCard(_currentMysteryCard!)),
      onDragStarted: () => setState(() => _isDragging = true),
      onDragEnd: (_) => setState(() => _isDragging = false),
      child: MouseRegion(cursor: SystemMouseCursors.grab, child: _buildSongCard(_currentMysteryCard!)),
    );
  }

  Widget _buildDropZone(int index) {
    if (_isRoundResultShowing && !_lastPlacementCorrect && _correctInsertionIndex == index) {
       return FadeIn(child: MissedGapIndicator(year: _currentMysteryCard?.year ?? "???"));
    }
    if (_isRoundResultShowing && !_lastPlacementCorrect && _wrongPlacementIndex == index) {
       return FadeIn(child: WrongChoiceIndicator(year: _currentMysteryCard?.year ?? "???"));
    }
    
    return ValueListenableBuilder<int?>(
      valueListenable: _hoveredDropZoneIndex,
      builder: (context, hoveredIdx, _) {
        final bool isHovered = hoveredIdx == index && !_isRoundResultShowing;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isHovered ? 120 : 40, 
          height: 180,
          color: Colors.transparent,
          child: (isHovered && widget.roomCode != null)
              ? Center(
                  child: Container(
                    width: 120,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          blurRadius: 8,
                        )
                      ],
                    ),
                  ),
                )
              : Center(
                  child: Container(
                    width: 1, 
                    height: 40, 
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.02), borderRadius: BorderRadius.circular(1)),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildTimelineCard(Song song, int index) {
    final bool isCelebrating = _isRoundResultShowing && _lastPlacementCorrect && index == _lastPlacedCorrectIndex;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8), 
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _celebrationController,
            builder: (context, child) {
               double scale = isCelebrating ? (1.0 + (_celebrationController.value * 0.06)) : 1.0;
               return Transform.scale(
                  scale: scale,
                  child: _TimelineHoverScaleWrapper(
                    isDisabled: _isDragging || isCelebrating,
                    child: _buildSongCard(song, isHighlighted: isCelebrating),
                  ),
               );
            },
          ),
          const SizedBox(height: 12),
          Text(
            song.year, 
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black)
          ),
        ]
      )
    );
  }

  Widget _buildSongCard(Song song, {bool isHighlighted = false}) {
    bool isMystery = _currentMysteryCard?.id == song.id && !_isRoundResultShowing;
    
    return Container(
      width: 120, 
      height: 180, 
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), 
            blurRadius: 15, 
            offset: const Offset(0, 8)
          ),
          if (isHighlighted) BoxShadow(color: Colors.greenAccent.withOpacity(0.6), blurRadius: 20, spreadRadius: 5),
          if (!isHighlighted && isMystery) BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.4), blurRadius: 20, spreadRadius: 2),
        ],
        border: Border.all(
          color: isHighlighted ? Colors.greenAccent : ((isMystery) ? Theme.of(context).primaryColor : Colors.black.withOpacity(0.05)), 
          width: (isMystery || isHighlighted) ? 3 : 1.5
        ),
      ), 
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16), 
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isMystery) 
              Container(
                color: Colors.black,
                padding: const EdgeInsets.all(20),
                child: Image.asset('assets/Before_or_after_logo.png', fit: BoxFit.contain),
              )
            else 
              song.artworkUrl != null 
                  ? Image.network(song.artworkUrl!, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.music_note, size: 50)) 
                  : const Icon(Icons.music_note, color: Colors.grey, size: 50),
            
             if (isMystery)
                Positioned.fill(
                  child: Flash(
                    infinite: true,
                    duration: const Duration(seconds: 4),
                    child: Container(decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1))),
                  ),
                ),

            if (!isMystery)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.9), Colors.transparent]
                    )
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.uiLanguage == 'ar' ? (song.titleAr ?? song.title) : song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        widget.uiLanguage == 'ar' ? (song.artistAr ?? song.artist) : song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 8),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        )
      )
    );
  }
}

class _ResultCardHoverWrapper extends StatefulWidget {
  final Widget child;
  final Function(bool)? onHoverChanged;
  const _ResultCardHoverWrapper({required this.child, this.onHoverChanged});

  @override
  State<_ResultCardHoverWrapper> createState() => _ResultCardHoverWrapperState();
}

class _ResultCardHoverWrapperState extends State<_ResultCardHoverWrapper> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
         setState(() => _isHovered = true);
         widget.onHoverChanged?.call(true);
      },
      onExit: (_) {
         setState(() => _isHovered = false);
         widget.onHoverChanged?.call(false);
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: _isHovered ? 2.0 : 1.0,
        child: widget.child,
      ),
    );
  }
}

class MissedGapIndicator extends StatefulWidget {
  final String year;
  const MissedGapIndicator({super.key, required this.year});

  @override
  State<MissedGapIndicator> createState() => _MissedGapIndicatorState();
}

class _MissedGapIndicatorState extends State<MissedGapIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) { 
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 120, 
          height: 180, 
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16), 
            border: Border.all(
              color: Colors.red.withOpacity(0.3 + (_pulseController.value * 0.4)), 
              width: 3, 
              style: BorderStyle.solid
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.red.withOpacity(0.05),
                Colors.red.withOpacity(0.15),
              ]
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.1 * _pulseController.value),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ]
          ), 
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, 
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.1),
                ),
                child: Icon(Icons.gps_fixed, color: Colors.red.withOpacity(0.8), size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                widget.year, 
                style: GoogleFonts.outfit(
                  color: Colors.red.withOpacity(0.9), 
                  fontSize: 28, 
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                )
              ),
              Text(
                "TARGET",
                style: GoogleFonts.outfit(
                  color: Colors.red.withOpacity(0.5), 
                  fontSize: 10, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                )
              )
            ]
          )
        ); 
      },
    ); 
  }
}

class _TimelineHoverScaleWrapper extends StatefulWidget {
  final Widget child;
  final bool isDisabled;
  const _TimelineHoverScaleWrapper({required this.child, this.isDisabled = false});

  @override
  State<_TimelineHoverScaleWrapper> createState() => _TimelineHoverScaleWrapperState();
}

class _TimelineHoverScaleWrapperState extends State<_TimelineHoverScaleWrapper> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    bool effectiveHover = _isHovered && !widget.isDisabled;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: effectiveHover ? SystemMouseCursors.click : MouseCursor.defer,
      child: AnimatedScale(
        scale: effectiveHover ? 1.25 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _AnimatedArrowPainterWidget extends StatefulWidget {
  final Color color;
  const _AnimatedArrowPainterWidget({required this.color});

  @override
  State<_AnimatedArrowPainterWidget> createState() => _AnimatedArrowPainterWidgetState();
}

class _AnimatedArrowPainterWidgetState extends State<_AnimatedArrowPainterWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ArrowPainter(
            progress: _controller.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ArrowPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    
    // Draw glowing vertical line
    final linePaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(centerX, size.height - 10), Offset(centerX, 20), glowPaint);
    canvas.drawLine(Offset(centerX, size.height - 10), Offset(centerX, 20), linePaint);

    // Draw animated chevrons moving upwards (from bottom to top)
    final chevronPaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const int numChevrons = 3;
    final double pathLength = size.height - 30;
    
    for (int i = 0; i < numChevrons; i++) {
      double t = (progress + (i / numChevrons)) % 1.0;
      double y = (size.height - 15) - (t * pathLength);
      
      final path = Path()
        ..moveTo(centerX - 8, y + 6)
        ..lineTo(centerX, y)
        ..lineTo(centerX + 8, y + 6);
      
      canvas.drawPath(path, chevronPaint);
    }

    // Draw prominent arrowhead pointing UP at the top of the path
    final headPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final headPath = Path()
      ..moveTo(centerX - 12, 20)
      ..lineTo(centerX, 8)
      ..lineTo(centerX + 12, 20)
      ..close();

    canvas.drawPath(headPath, headPaint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class WrongChoiceIndicator extends StatelessWidget {
  final String year;
  const WrongChoiceIndicator({super.key, required this.year});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 8,
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(0.1),
            ),
            child: const Icon(Icons.close_rounded, color: Colors.red, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            "PLAYED\nHERE",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
