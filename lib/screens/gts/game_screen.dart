import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:ui' as ui;

import '../../models/song.dart';
import '../../services/song_repository.dart';
import 'result_screen.dart';

import 'dart:io';
import '../../services/audio_cache_service.dart';
import '../../services/background_music_service.dart';
import '../../services/firebase_service.dart'; // IMPORT

class GtsGameScreen extends StatefulWidget {
  final int totalRounds;
  final List<String> playerNames;
  final bool isHardMode;
  final bool isTeamMode;
  final String uiLanguage;
  final String? roomCode; // NEW
  final Map<String, List<String>>? teamMembers; // New: Who is in which team

  const GtsGameScreen({
    super.key,
    required this.totalRounds,
    required this.playerNames,
    required this.isHardMode,
    this.isTeamMode = false,
    this.uiLanguage = 'en',
    this.roomCode,
    this.teamMembers,
  });

  @override
  State<GtsGameScreen> createState() => _GtsGameScreenState();
}

class _GtsGameScreenState extends State<GtsGameScreen> {
  late final AudioPlayer _player;
  late final SongRepository _repository;
  
  List<Song> _history = [];
  Map<String, int> _scores = {};
  int _currentRound = 1;
  int _currentPlayerIndex = 0;
  
  Question? _currentQuestion;
  bool _isLoading = true;
  bool _isAnswered = false;
  String? _selectedOptionId;
  int? _earnedPoints;

  int _hintsUsed = 0;
  final Set<String> _hiddenOptionIds = {};
  final List<Question> _questionBuffer = [];
  bool _isBuffering = false;

  Stopwatch _responseTimer = Stopwatch();
  static const int _maxTimeBonus = 500;
  static const int _baseScore = 500;
  String? _lastHintId;
  int? _lastPlayedThreshold; // Track audio warnings
  StreamSubscription? _countdownTicker; // For side effects like sounds/timeout
  final Set<int> _skipVotes = {};
  bool _isSkipped = false;
  Timer? _autoAdvanceTimer;
  int _autoAdvanceSeconds = 10;
  bool _isPaused = false;
  String? _pausedBy;
  StreamSubscription? _firebaseSubscription; // NEW
  
  bool _isWaitingForReady = true; // NEW: Manual start phase
  bool _isAudioLoading = true;

  // TEAM MODE STATE
  int? _activeTeamIndex;
  bool _buzzerPressed = false;
  bool _showChoicesAfterBuzz = false;
  double? _buzzTimeSeconds;
  String? _buzzedPlayerName;
  bool _isBuzzShaking = false;
  String? _answeredPlayerName;
  bool _isResettingRound = false;
  bool _processingHint = false;
  String? _skipPlayer1;
  String? _skipPlayer2;
  Map<String, String> _currentSkipVotes = {};

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer(); 
    _repository = SongRepository()..loadSongs();
    for (var name in widget.playerNames) {
      _scores[name] = 0;
    }
    MediaCacheService().init();
    _startRound();

    if (widget.roomCode != null) {
      _firebaseSubscription = FirebaseService().listenToRoomCustom(widget.roomCode!).listen((data) {
        if (data.isNotEmpty && mounted) {
          if (data['status'] == 'playing') {
            _isResettingRound = false;
          }

          if (data['status'] == 'buzzed' && !_buzzerPressed && !_isAnswered && !_isWaitingForReady && !_isResettingRound) {
            final buzzedTeam = data['buzzedTeam'];
            final buzzedPlayerName = data['buzzedPlayerName'];
            int teamIndex = 0;
            if (buzzedTeam == 'team2') teamIndex = 1;
            else if (buzzedTeam == 'team3') teamIndex = 2;
            else if (buzzedTeam == 'team4') teamIndex = 3;
            _handleBuzz(teamIndex, buzzedPlayerName);
          }
          // Handle Answer Selection in Mobile Controller
          final selectedOptionInfo = data['selectedOptionInfo'];
          if (selectedOptionInfo != null && !_isAnswered) {
            final String answeredPlayer = selectedOptionInfo['playerName'] ?? '';
            final bool isValidAnswer = widget.isTeamMode 
                ? (_buzzerPressed && _answeredPlayerName == null) 
                : (answeredPlayer == widget.playerNames[_currentPlayerIndex]);

            if (isValidAnswer && _currentQuestion != null) {
              try {
                final song = _currentQuestion!.options.firstWhere((s) => s.id.toString() == selectedOptionInfo['id'].toString());
                _answeredPlayerName = answeredPlayer;
                _handleOptionSelected(song);
              } catch (e) {
                print("Selected song not found in options: $e");
              }
            }
          }

          // Handle Pause State
          if (data['pauseState'] != null) {
            final isPaused = data['pauseState']['isPaused'] == true;
            final pausedBy = data['pauseState']['pausedBy'];
            if (_isPaused != isPaused) {
              setState(() {
                _isPaused = isPaused;
                _pausedBy = pausedBy;
                
                if (!isPaused && _isAnswered) {
                  _autoAdvanceSeconds = 3; // Fast-forward or buffer to exactly 3 seconds when resuming
                }
              });
            }
          }

          // Handle Skip Request
          if (data['nextRoundRequested'] == true) {
            if (_isAnswered) {
              FirebaseService().resetNextRoundRequest(widget.roomCode!);
              _autoAdvanceTimer?.cancel();
              _nextTurn();
            }
          }

          // Handle Start Turn Request
          if (data['startTurnRequested'] == true) {
            if (_isWaitingForReady && !_isLoading) {
              FirebaseService().setWaitingForReady(widget.roomCode!, false);
              _beginTurn();
            }
          }

          // Handle Hint Request in Mobile Controller
          if (!widget.isTeamMode && data['hintRequested'] == true && !_isAnswered && _hintsUsed < 2 && !_isLoading && !_processingHint) {
            _processingHint = true;
            FirebaseService().resetHintRequest(widget.roomCode!);
            _useHint();
            Future.delayed(const Duration(milliseconds: 1000), () {
              _processingHint = false;
            });
          }

          // Handle Song Skip Voting - show names immediately on first vote
          if (widget.isTeamMode && !_isAnswered) {
            final Map<String, String> newSkipVotes = {};
            if (data['skipVotes'] != null && !_isLoading) {
              final skipVotes = data['skipVotes'] as Map;
              for (int i = 1; i <= 4; i++) {
                final key = 'team$i';
                if (skipVotes.containsKey(key) && skipVotes[key] != null) {
                  newSkipVotes[key] = skipVotes[key]['playerName'] ?? 'Team $i';
                }
              }
            }

            // Always update the live display (even with one vote)
            if (newSkipVotes.toString() != _currentSkipVotes.toString()) {
              setState(() {
                _currentSkipVotes = newSkipVotes;
              });
            }

            // Trigger skip only when all active teams have voted to skip and buzzer not already pressed
            bool allVoted = true;
            for (int i = 0; i < widget.playerNames.length; i++) {
              if (!newSkipVotes.containsKey('team${i + 1}')) {
                allVoted = false;
                break;
              }
            }
            if (allVoted && !_buzzerPressed && newSkipVotes.isNotEmpty) {
              final p1 = newSkipVotes['team1'] ?? 'Team 1';
              final p2 = newSkipVotes['team2'] ?? 'Team 2';
              _handleSongSkip(p1, p2);
            }
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _responseTimer.stop();
    _countdownTicker?.cancel();
    _autoAdvanceTimer?.cancel();
    _firebaseSubscription?.cancel(); // NEW
    _player.dispose(); 
    MediaCacheService().clearCache();
    super.dispose();
  }

  Future<void> _startRound() async {
    setState(() {
      _isResettingRound = true; // Ignore old Firebase state
      _isLoading = true;
      _isAudioLoading = true;
      _isAnswered = false;
      _selectedOptionId = null;
      _earnedPoints = null;
      _hintsUsed = 0;
      _processingHint = false;
      _hiddenOptionIds.clear();
      _lastHintId = null;
      _answeredPlayerName = null;
      _isPaused = false;
      _pausedBy = null;
      _skipPlayer1 = null;
      _skipPlayer2 = null;
      _currentSkipVotes.clear();
      _autoAdvanceTimer?.cancel();
      
      // Reset Team State
      _activeTeamIndex = null;
      _buzzerPressed = false;
      _showChoicesAfterBuzz = false;
      _buzzTimeSeconds = null;
      _lastPlayedThreshold = null;
    });

    try {
      if (_repository.allSongs.isEmpty) {
        await _repository.loadSongs();
      }

      Question? question;
      if (_repository.cachedNextQuestion != null && _history.isEmpty) {
        question = _repository.cachedNextQuestion;
        _repository.cachedNextQuestion = null;
      } else if (_questionBuffer.isNotEmpty) {
        question = _questionBuffer.removeAt(0);
      } else {
        question = await _repository.getNextQuestion(
          _history, 
          forceUniqueArtists: widget.isHardMode,
          distractorCount: widget.isTeamMode ? 5 : 3,
        );
      }
      
      if (mounted) {
        setState(() {
          _currentQuestion = question;
          _history.add(question!.correctSong);
          _isLoading = false;
          _isWaitingForReady = widget.roomCode != null 
              ? (_currentRound <= 1 && _currentPlayerIndex == 0) 
              : (widget.isTeamMode ? (_currentRound <= 1) : true);
        });
        _fillBuffer();
        if (widget.roomCode != null) {
          FirebaseService().resetBuzzer(widget.roomCode!);
          FirebaseService().clearOptions(widget.roomCode!);
          FirebaseService().clearPauseState(widget.roomCode!);
          FirebaseService().resetNextRoundRequest(widget.roomCode!);
          FirebaseService().clearSkipVotes(widget.roomCode!);
          FirebaseService().setWaitingForReady(widget.roomCode!, _isWaitingForReady);
          FirebaseService().setHintsUsed(widget.roomCode!, 0);
          FirebaseService().resetHintRequest(widget.roomCode!);

          if (!widget.isTeamMode) {
            final currentPlayer = widget.playerNames[_currentPlayerIndex];
            final nextIndex = (_currentPlayerIndex + 1) % widget.playerNames.length;
            final nextPlayer = widget.playerNames[nextIndex];
            FirebaseService().setIndividualActivePlayer(widget.roomCode!, currentPlayer, nextPlayer: nextPlayer);
          }
        }
        
        if (!_isWaitingForReady) {
          _beginTurn();
        }
      }
    } catch (e) {
      print('GTS: Error starting round: $e');
    }
  }

  Future<void> _beginTurn() async {
    if (_currentQuestion == null) return;
    
    setState(() {
      _isWaitingForReady = false;
      _isAudioLoading = true;
    });

    try {
      final audioUrl = _currentQuestion!.correctSong.link;
      final cachedAudio = MediaCacheService().getCachedPath(audioUrl);
      
      if (cachedAudio != null) {
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.play(DeviceFileSource(cachedAudio));
      } else {
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.play(UrlSource(audioUrl));
      }
      
      // Delay slightly to ensure audio has actually reached the speakers
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (mounted) {
        setState(() {
          _isAudioLoading = false;
        });
      }

      if (widget.roomCode != null) {
        FirebaseService().setWaitingForReady(widget.roomCode!, false);
        if (widget.isTeamMode) {
          FirebaseService().startGame(widget.roomCode!);
        } else {
          final currentPlayer = widget.playerNames[_currentPlayerIndex];
          final nextIndex = (_currentPlayerIndex + 1) % widget.playerNames.length;
          final nextPlayer = widget.playerNames[nextIndex];
          FirebaseService().setIndividualActivePlayer(widget.roomCode!, currentPlayer, nextPlayer: nextPlayer);
        }

        _pushOptionsToFirebase();
      }
      
      // Start response timer for ALL modes so bonuses work correctly
      _responseTimer.reset();
      _responseTimer.start();
      _skipVotes.clear();
      _isSkipped = false;
    } catch (e) {
      debugPrint("GTS: Audio start error: $e");
      if (mounted) {
        setState(() {
          _isAudioLoading = false;
        });
      }
    }
  }

  Future<void> _fillBuffer() async {
    if (_isBuffering || _questionBuffer.length >= 2) return;
    _isBuffering = true;
    try {
      final nextQ = await _repository.getNextQuestion(
        [..._history, ..._questionBuffer.map((q) => q.correctSong)],
        forceUniqueArtists: widget.isHardMode,
        distractorCount: widget.isTeamMode ? 5 : 3,
      );
      MediaCacheService().cacheFile(nextQ.correctSong.link);
      for (var opt in nextQ.options) {
        if (opt.artworkUrl != null) {
          MediaCacheService().cacheFile(opt.artworkUrl!);
        }
      }
      if (mounted) {
        setState(() {
           _questionBuffer.add(nextQ);
        });
      }
    } catch (e) {
      debugPrint('GTS: Buffering error: $e');
    } finally {
      _isBuffering = false;
    }
  }

  String _t(String key) {
    final isAr = widget.uiLanguage == 'ar';
    final isMobile = widget.roomCode != null;
    final Map<String, Map<String, String>> strings = {
      'ar': {
        'round': 'الجولة',
        'points': 'نقطة',
        'correctStr': 'إجابة صحيحة!',
        'wrongStr': 'إجابة خاطئة!',
        'nextTurn': 'الدور التالي',
        'hint': 'تلميح',
        'noHints': 'لا يوجد تلميحات',
        'roundComplete': 'مكتملة',
        'finishGame': 'إنهاء اللعبة',
        'setup': 'عودة',
        'startNextRound': 'بدء الجولة التالية',
        'earnedPoints': 'نقطة',
        'readyPrompt': 'دورك:',
        'everyoneReady': 'استعدوا جميعاً!',
        'startNow': 'ابدأ الآن',
        'pressAnySide': isMobile ? 'اضغط على زر البزر في جوالك للمشاركة!' : 'اضغط على أي مفتاح في جهتك للمشاركة!',
        'team1Keys': '1-5، Q-T، A-G، Z-V...',
        'team2Keys': '8-0، I-P، J-L، M-..، رموز...',
      },
      'en': {
        'round': 'ROUND',
        'points': 'pts',
        'correctStr': 'CORRECT!',
        'wrongStr': 'WRONG!',
        'nextTurn': 'NEXT TURN',
        'hint': 'Hint',
        'noHints': 'No Hints Left',
        'roundComplete': 'COMPLETE',
        'finishGame': 'FINISH GAME',
        'setup': 'BACK',
        'startNextRound': 'START NEXT ROUND',
        'earnedPoints': 'POINTS',
        'readyPrompt': 'It\'s your turn:',
        'everyoneReady': 'Everyone get ready!',
        'startNow': 'START NOW',
        'pressAnySide': isMobile ? 'Press the BUZZ button on your phone!' : 'Press any key on YOUR SIDE to buzz!',
        'team1Keys': '1-5, Q-T, A-G, Z-V...',
        'team2Keys': '8-0, I-P, J-L, M-., symbols...',
      },
    };
    return strings[isAr ? 'ar' : 'en']![key] ?? key;
  }

  void _handleBuzz(int teamIndex, [String? playerName]) {
    if (_buzzerPressed || _isAnswered || _isLoading || _isWaitingForReady || _isAudioLoading) return;
    
    _player.pause(); // Stop music immediately on buzz
    _responseTimer.stop();
    final listeningTime = _responseTimer.elapsedMilliseconds / 1000.0;
    
    setState(() {
      _buzzerPressed = true;
      _activeTeamIndex = teamIndex;
      _buzzTimeSeconds = listeningTime;
      _buzzedPlayerName = playerName;
      _isBuzzShaking = true;
    });
    
    BackgroundMusicService.instance.playSfx('tick.mp3');

    // Reset shaking after 500ms
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isBuzzShaking = false;
        });
      }
    });

    // Automatically show choices after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _buzzerPressed && !_showChoicesAfterBuzz && !_isAnswered) {
        _triggerShowChoices();
      }
    });
  }

  void _triggerShowChoices() {
    if (widget.roomCode != null) {
      final listeningTime = _buzzTimeSeconds ?? 0.0;
      final listeningPart = (1000 - (listeningTime * 25)).clamp(500.0, 1000.0).toInt();
      FirebaseService().showChoices(widget.roomCode!, basePoints: listeningPart);
    }
    _responseTimer.reset(); // RESET for fresh thinking window
    _responseTimer.start();
    
    // Start side-effect ticker for sounds and timeout
    _countdownTicker?.cancel();
    _countdownTicker = Stream.periodic(const Duration(milliseconds: 100)).listen((_) {
      if (!mounted || _isAnswered) {
        _countdownTicker?.cancel();
        return;
      }

      final elapsed = _responseTimer.elapsedMilliseconds / 1000.0;
      
      // 1. Auto-Timeout Check
      if (elapsed >= 20.0 && !_isAnswered) {
        _countdownTicker?.cancel();
        _handleOptionSelected(Song(id: 'timeout', title: 'Timeout', artist: 'System', link: '', year: '0', styles: []));
        return;
      }

      // 2. Sound Triggers
      final rawPoints = 1000 - (elapsed / 20.0 * 1250);
      final total = rawPoints.clamp(-250, 1000).toInt();

      if (total <= 200 && _lastPlayedThreshold != 200) {
        _lastPlayedThreshold = 200;
        BackgroundMusicService.instance.playSfx('tick.mp3');
      } else if (total <= 100 && _lastPlayedThreshold != 100) {
        _lastPlayedThreshold = 100;
        BackgroundMusicService.instance.playSfx('tick.mp3');
      } else if (total <= 0 && _lastPlayedThreshold != 0) {
        _lastPlayedThreshold = 0;
        BackgroundMusicService.instance.playSfx('tick.mp3');
      }
    });

    setState(() => _showChoicesAfterBuzz = true);
  }

  void _handleOptionSelected(Song? selectedSong, {bool isSkip = false}) {
    if (_isAnswered) return;
    _isSkipped = isSkip;
    if (widget.isTeamMode && !_buzzerPressed && selectedSong != null) return;
    
    if (widget.isTeamMode) {
      _player.resume();
    }
    
    final isCorrect = selectedSong != null && selectedSong.id == _currentQuestion!.correctSong.id;
    int points = 0;
    
    if (isCorrect) {
      if (widget.isTeamMode && _activeTeamIndex != null) {
        _responseTimer.stop();
        final listeningTime = _buzzTimeSeconds ?? 0;
        final selectionTime = _responseTimer.elapsedMilliseconds / 1000.0;
        
        // Phased Scoring:
        // 1. Listening Score: (1000 to 500 based on buzz speed)
        final listeningPart = (1000 - (listeningTime * 25)).clamp(500.0, 1000.0);
        // 2. Selection Penalty: (-50 per second of thinking)
        final selectionPenalty = selectionTime * 50;
        
        points = (listeningPart - selectionPenalty).toInt().clamp(-250, 1000);
        
        final teamName = widget.playerNames[_activeTeamIndex!];
        _scores[teamName] = (_scores[teamName] ?? 0) + points;
      } else {
        // Individual Mode Scoring
        _responseTimer.stop();
        final elapsed = _responseTimer.elapsedMilliseconds;
        final timeBonus = (_maxTimeBonus - (elapsed / 20)).clamp(0, _maxTimeBonus).toInt();
        final hintPenalty = _hintsUsed * 100;
        points = (_baseScore + timeBonus - hintPenalty).clamp(0, 5000).toInt();
        _scores[widget.playerNames[_currentPlayerIndex]] = (_scores[widget.playerNames[_currentPlayerIndex]] ?? 0) + points;
      }
      _playCorrectAudioWithDucking();
    } else {
      if (isSkip) {
        points = 0;
      } else if (widget.isTeamMode && _activeTeamIndex != null) {
        // Team Mode Penalty
        final teamName = widget.playerNames[_activeTeamIndex!];
        _scores[teamName] = (_scores[teamName] ?? 0) - 250; 
        points = -250;
      } else {
        // Individual Mode Penalty (Wrong Answer)
        final playerName = widget.playerNames[_currentPlayerIndex];
        _scores[playerName] = (_scores[playerName] ?? 0) - 250;
        points = -250; // Track penalty for UI
      }
      if (!isSkip) _playWrongAudioWithDucking();
    }
    
    if (widget.roomCode != null) {
      FirebaseService().clearOptions(widget.roomCode!);
      FirebaseService().setRoundFinished(widget.roomCode!);
    }
    
    setState(() {
      _isAnswered = true;
      _selectedOptionId = selectedSong?.id ?? "";
      _earnedPoints = isCorrect ? points : (isSkip ? 0 : -250);
      _skipVotes.clear();
    });

  }

  void _handleSongSkip(String player1, String player2) {
    if (_isAnswered) return;
    
    _player.stop();
    _responseTimer.stop();
    _countdownTicker?.cancel();

    // No points deducted on skip to allow extra opportunity without point loss
    // _playWrongAudioWithDucking();

    if (widget.roomCode != null) {
      FirebaseService().clearOptions(widget.roomCode!);
      FirebaseService().clearSkipVotes(widget.roomCode!);
      FirebaseService().setRoundFinished(widget.roomCode!);
    }
    
    setState(() {
      _isAnswered = true;
      _showChoicesAfterBuzz = true;
      _selectedOptionId = "skip";
      _earnedPoints = 0;
      _answeredPlayerName = "SKIP";
      _skipPlayer1 = player1;
      _skipPlayer2 = player2;
    });

  }

  void _startAutoAdvanceTimer() {
    _autoAdvanceSeconds = 10;
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return; // do not tick if paused
      setState(() {
        _autoAdvanceSeconds--;
      });
      if (_autoAdvanceSeconds <= 0) {
        timer.cancel();
        _nextTurn();
      }
    });
  }

  void _nextTurn() {
    if (widget.isTeamMode) {
      if (_currentRound >= widget.totalRounds) {
        _finishGame();
      } else {
        setState(() {
          _currentRound++;
        });
        _startRound();
      }
      return;
    }

    int nextIndex = _currentPlayerIndex + 1;
    bool isRoundEnding = nextIndex >= widget.playerNames.length;
    if (isRoundEnding && _currentRound >= widget.totalRounds) {
      _finishGame();
    } else if (isRoundEnding) {
      setState(() {
        _currentPlayerIndex = 0;
        _currentRound++;
      });
      _startRound();
    } else {
      setState(() {
        _currentPlayerIndex = nextIndex;
      });
      _startRound();
    }
  }

  void _finishGame() {
    _player.stop(); 
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GtsResultScreen(
          scores: _scores,
          totalRounds: widget.totalRounds,
        ),
      ),
    );
  }

  void _showRoundSummary(int roundNum) {
    _player.stop();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final sortedEntries = _scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        return Dialog(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFF0F172A).withOpacity(0.95), borderRadius: BorderRadius.circular(20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("${_t('round')} $roundNum ${_t('roundComplete')}", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const Divider(color: Colors.white24),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: sortedEntries.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.white10),
                    itemBuilder: (context, index) {
                       final entry = sortedEntries[index];
                       return ListTile(
                         title: Text(entry.key, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                         trailing: Text("${entry.value} ${_t('points')}", style: GoogleFonts.outfit(color: index == 0 ? Theme.of(context).primaryColor : Colors.white70, fontWeight: FontWeight.bold, fontSize: 20)),
                       );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                   width: double.infinity,
                   child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _startRound(); 
                    },
                    child: Text(roundNum >= widget.totalRounds ? _t('finishGame') : _t('startNextRound')),
                   ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReadyScreen(String playerName) {
    bool isAr = widget.uiLanguage == 'ar';
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeInDown(
                child: Image.asset('assets/Guess_that_song_logo.png', height: 120),
              ),
              const SizedBox(height: 60),
              ZoomIn(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  widget.isTeamMode ? _t('everyoneReady') : _t('readyPrompt'),
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    color: Colors.white70,
                    letterSpacing: isAr ? 0 : 4,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              if (!widget.isTeamMode)
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
                        Shadow(color: Theme.of(context).primaryColor, blurRadius: 40),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: widget.isTeamMode ? 40 : 80),
              ElevatedButton(
                onPressed: _beginTurn,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  backgroundColor: Theme.of(context).primaryColor,
                  elevation: 10,
                ),
                child: Text(
                  _t('startNow'),
                  style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _playCorrectAudioWithDucking() async {
    try {
      await _player.setVolume(0.2); 
      await BackgroundMusicService.instance.playSfx('correct.mp3');
      await Future.delayed(const Duration(milliseconds: 1500));
      await _player.setVolume(1.0);
    } catch (_) {}
  }

  Future<void> _playWrongAudioWithDucking() async {
    try {
      await _player.setVolume(0.2); 
      await BackgroundMusicService.instance.playSfx('wrong.mp3');
      await Future.delayed(const Duration(milliseconds: 1500));
      await _player.setVolume(1.0);
    } catch (_) {}
  }

  void _useHint() {
    if (_currentQuestion == null || _isAnswered || _hintsUsed >= 2) return;
    final correctId = _currentQuestion!.correctSong.id;
    final visibleWrongOptions = _currentQuestion!.options.where((s) => s.id != correctId && !_hiddenOptionIds.contains(s.id)).toList();
    if (visibleWrongOptions.isNotEmpty) {
      setState(() {
        final toHide = (visibleWrongOptions..shuffle()).first;
        _hiddenOptionIds.add(toHide.id);
        _hintsUsed++;
        _lastHintId = toHide.id;
      });
      if (widget.roomCode != null) {
        FirebaseService().setHintsUsed(widget.roomCode!, _hintsUsed);
        _pushOptionsToFirebase();
      }
    }
  }

  void _pushOptionsToFirebase() {
    if (widget.roomCode == null || _currentQuestion == null) return;
    final isArabic = SongRepository().currentLibraryType == 'arabic';
    final optionsList = _currentQuestion!.options
        .map((s) => {
          'id': s.id,
          'title': widget.isHardMode ? '' : (isArabic ? (s.titleAr ?? s.title) : s.title),
          'artist': isArabic ? (s.artistAr ?? s.artist) : s.artist,
          'artworkUrl': s.artworkUrl,
          'hidden': _hiddenOptionIds.contains(s.id),
        }).toList();
    FirebaseService().pushOptions(widget.roomCode!, optionsList);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentQuestion == null && !_isLoading) return const SizedBox.shrink();
    final currentPlayer = widget.playerNames[_currentPlayerIndex];
    
    return Scaffold(
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : Directionality(
                  textDirection: widget.uiLanguage == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                  child: Column(
                    children: [
                      if (widget.isTeamMode) ...[
                        const SizedBox(height: 10),
                        if (_showChoicesAfterBuzz) ...[
                          Image.asset(
                            'assets/Guess_that_song_logo.png',
                            height: 125,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 10),
                        ],
                        _buildTeamHeader(),
                        const SizedBox(height: 10),
                      ] else ...[
                        SizedBox(height: widget.playerNames.length > 5 ? 8 : 15),
                        Image.asset(
                          'assets/Guess_that_song_logo.png',
                          height: widget.playerNames.length > 5 ? 75 : 120,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: widget.playerNames.length > 5 ? 8 : 10),
                      ],
                      Expanded(
                        child: widget.isTeamMode && !_showChoicesAfterBuzz
                          ? _buildBuzzerLayout()
                          : _buildQuestionContent(),
                      ),
                    ],
                  ),
                ),
            
            // Buzzer Alert Overlay (handled inline within the circular wheel layout)

            // Pause Overlay
            if (_isPaused)
               _buildPauseOverlay(),

            // Ready Screen Overlay
            if (_isWaitingForReady && !_isLoading)
              widget.isTeamMode ? _buildReadyScreen("EVERYONE") : _buildReadyScreen(currentPlayer),

             // Back / Setup Button on top of everything (aligned to start/left)
             Positioned.directional(
               textDirection: widget.uiLanguage == 'ar' ? TextDirection.rtl : TextDirection.ltr,
               start: 20,
               top: 20, 
               child: IconButton(
                 onPressed: () { 
                   _player.stop(); 
                   Navigator.pop(context); 
                 },
                 icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
                 tooltip: widget.uiLanguage == 'ar' ? 'العودة للإعدادات' : 'Back to Settings',
                 style: IconButton.styleFrom(
                   backgroundColor: Colors.white.withOpacity(0.05),
                   padding: const EdgeInsets.all(12),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                 ),
               ),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndividualHeader(String currentPlayer) {
    int highestScore = -99999;
    for (var score in _scores.values) {
      if (score > highestScore) {
        highestScore = score;
      }
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: widget.playerNames.map((playerName) {
            final bool isActive = playerName == currentPlayer;
            final int playerScore = _scores[playerName] ?? 0;
            final bool isLeader = playerScore == highestScore && highestScore > 0;

            Color borderColor = Colors.white24;
            double borderWidth = 1.0;
            Color containerBgColor = Colors.white.withOpacity(0.05);

            if (isActive) {
              borderColor = Theme.of(context).primaryColor;
              borderWidth = 2.0;
              containerBgColor = Theme.of(context).primaryColor.withOpacity(0.2);
            } else if (isLeader) {
              borderColor = Colors.amber;
              borderWidth = 2.0;
              containerBgColor = Colors.amber.withOpacity(0.15);
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: containerBgColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: borderColor,
                    width: borderWidth,
                  ),
                  boxShadow: isLeader
                      ? [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLeader) ...[
                      const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      "$playerName: $playerScore",
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.white : (isLeader ? Colors.amberAccent : Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (_isAnswered) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildEarnedPointsBadge(),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildVerticalScoreboard(String currentPlayer) {
    final sortedNames = List<String>.from(widget.playerNames)
      ..sort((a, b) => (_scores[b] ?? 0).compareTo(_scores[a] ?? 0));
      
    final double itemHeight = 56.0;
    final double spacing = 8.0;
    final double totalHeight = widget.playerNames.length * (itemHeight + spacing);

    final int nextIndex = (_currentPlayerIndex + 1) % widget.playerNames.length;
    final String nextPlayerName = widget.playerNames[nextIndex];

    int highestScore = -99999;
    for (var score in _scores.values) {
      if (score > highestScore) {
        highestScore = score;
      }
    }

    return SizedBox(
      width: 220,
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: widget.playerNames.map((playerName) {
          final int index = sortedNames.indexOf(playerName);
          final int playerScore = _scores[playerName] ?? 0;

          // Team Mode specific variables
          final bool isTeam1 = widget.isTeamMode && playerName == widget.playerNames[0];
          final bool isTeam2 = widget.isTeamMode && playerName == widget.playerNames[1];
          final bool isTeam3 = widget.isTeamMode && widget.playerNames.length >= 3 && playerName == widget.playerNames[2];
          final bool isTeam4 = widget.isTeamMode && widget.playerNames.length >= 4 && playerName == widget.playerNames[3];
          final bool isBuzzedTeam = widget.isTeamMode && _buzzerPressed && _activeTeamIndex != null && playerName == widget.playerNames[_activeTeamIndex!];

          // Individual Mode variables
          final bool isActive = !widget.isTeamMode && playerName == currentPlayer;
          final bool isLeader = !widget.isTeamMode && playerScore == highestScore && highestScore > 0;
          final bool isNext = !widget.isTeamMode && _isAnswered && playerName == nextPlayerName && widget.playerNames.length > 1 && !isActive;

          Color teamColor = Colors.cyan;
          if (isTeam1) teamColor = Colors.cyan;
          else if (isTeam2) teamColor = Colors.pinkAccent;
          else if (isTeam3) teamColor = Colors.amber;
          else if (isTeam4) teamColor = Colors.lightGreenAccent;

          Color borderColor = Colors.white10;
          double borderWidth = 1.0;
          Color containerBgColor = Colors.white.withOpacity(0.03);
          Color textAccentColor = Colors.white70;
          Color scoreColor = Colors.white54;
          Color textLabelColor = Colors.white;

          if (widget.isTeamMode) {
            if (isBuzzedTeam) {
              borderColor = teamColor;
              borderWidth = 2.5;
              containerBgColor = teamColor.withOpacity(0.2);
              textAccentColor = teamColor;
              scoreColor = teamColor;
            } else {
              borderColor = teamColor.withOpacity(0.4);
              borderWidth = 1.2;
              containerBgColor = teamColor.withOpacity(0.05);
              textAccentColor = teamColor.withOpacity(0.9);
              scoreColor = teamColor.withOpacity(0.8);
            }
          } else {
            if (isActive) {
              borderColor = Theme.of(context).primaryColor;
              borderWidth = 2.0;
              containerBgColor = Theme.of(context).primaryColor.withOpacity(0.15);
              textLabelColor = Colors.white;
              scoreColor = Colors.white;
            } else if (isLeader) {
              borderColor = Colors.amber;
              borderWidth = 1.5;
              containerBgColor = Colors.amber.withOpacity(0.08);
              textAccentColor = Colors.amberAccent;
              scoreColor = Colors.amber;
            } else if (isNext) {
              borderColor = Colors.pinkAccent;
              borderWidth = 2.0;
              containerBgColor = Colors.pink.withOpacity(0.07);
            }
          }

          return AnimatedPositioned(
            key: ValueKey(playerName),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutBack,
            top: index * (itemHeight + spacing),
            left: 0,
            right: 0,
            height: itemHeight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: containerBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: borderWidth),
                boxShadow: isLeader
                    ? [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.1),
                          blurRadius: 6,
                          spreadRadius: 1,
                        )
                      ]
                    : isNext
                        ? [
                            BoxShadow(
                              color: Colors.pinkAccent.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ]
                        : (isActive || isBuzzedTeam
                            ? [
                                BoxShadow(
                                  color: (widget.isTeamMode ? (isTeam1 ? Colors.cyan : Colors.pinkAccent) : Theme.of(context).primaryColor).withOpacity(0.15),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                )
                              ]
                            : null),
              ),
              child: Row(
                children: [
                  if (isNext)
                    Pulse(
                      infinite: true,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.pinkAccent.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.play_arrow_rounded, color: Colors.pinkAccent, size: 18),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: isLeader 
                            ? Colors.amber.withOpacity(0.2) 
                            : (widget.isTeamMode
                                ? (isTeam1 ? Colors.cyan.withOpacity(0.2) : Colors.pinkAccent.withOpacity(0.2))
                                : (isActive ? Theme.of(context).primaryColor.withOpacity(0.2) : Colors.white12)),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          "${index + 1}",
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: isLeader 
                                ? Colors.amber 
                                : (widget.isTeamMode
                                    ? teamColor
                                    : (isActive ? Colors.white : Colors.white60)),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      playerName,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.isTeamMode
                            ? teamColor
                            : (isActive ? Colors.white : (isLeader ? Colors.amberAccent : Colors.white70)),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    "$playerScore",
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isLeader ? Colors.amber : (isActive || widget.isTeamMode ? Colors.white : Colors.white54),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "pts",
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isLeader 
                          ? Colors.amber.withOpacity(0.7) 
                          : (isActive || widget.isTeamMode ? Colors.white60 : Colors.white30),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTeamHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!_isAnswered && _currentSkipVotes.isNotEmpty) ...[
          _buildLiveSkipVotesBadge(),
        ],
        if (_isAnswered) ...[
          _buildEarnedPointsBadge(),
          if (_answeredPlayerName != null) ...[
            const SizedBox(width: 16),
            _buildAnsweredPlayerBadge(),
          ],
          const SizedBox(width: 24),
          _buildAutoAdvanceTimerBadge(),
        ]
      ],
    );
  }

  Widget _buildAutoAdvanceTimerBadge() {
    if (_isPaused) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(15)),
        child: Text(
          widget.uiLanguage == 'ar' ? "⏸️ متوقف مؤقتاً" : "⏸️ PAUSED", 
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
        ),
      );
    }
    if (widget.roomCode != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Colors.orangeAccent, Colors.deepOrange]),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.orangeAccent.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1,
            )
          ]
        ),
        child: Text(
          widget.uiLanguage == 'ar' ? "👉 اضغط \"الجولة التالية\" من الجوال للاستمرار" : "👉 Press \"Next Round\" on controller", 
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPauseOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: ElasticIn(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pause_circle_filled, size: 100, color: Colors.white),
              const SizedBox(height: 20),
              Text(
                widget.uiLanguage == 'ar' ? 'اللعبة متوقفة مؤقتاً' : 'GAME PAUSED',
                style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              if (_pausedBy != null) ...[
                const SizedBox(height: 10),
                Text(
                  widget.uiLanguage == 'ar' ? 'بطلب من: $_pausedBy' : 'Requested by: $_pausedBy',
                  style: GoogleFonts.outfit(fontSize: 24, color: Colors.white70),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnsweredPlayerBadge() {
    final colors = [
      Colors.cyan,
      Colors.pinkAccent,
      Colors.amber,
      Colors.lightGreenAccent,
    ];
    final color = _answeredPlayerName == 'SKIP' 
        ? Colors.orange 
        : (_activeTeamIndex != null ? colors[_activeTeamIndex! % colors.length] : Colors.cyan);

    return ZoomIn(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color, width: 2),
        ),
        child: _answeredPlayerName == 'SKIP' 
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.uiLanguage == 'ar' ? '⏭️ تم التخطي بطلب من: ' : '⏭️ Skipped by: ',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                ...() {
                  final List<Widget> voters = [];
                  int addedCount = 0;
                  for (int i = 0; i < widget.playerNames.length; i++) {
                    final teamKey = 'team${i + 1}';
                    final voterName = _currentSkipVotes[teamKey];
                    if (voterName != null) {
                      if (addedCount > 0) {
                        voters.add(Text(' & ', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)));
                      }
                      voters.add(Text(
                        voterName,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors[i % colors.length],
                        ),
                      ));
                      addedCount++;
                    }
                  }
                  if (voters.isEmpty) {
                    voters.add(Text(
                      widget.uiLanguage == 'ar' ? 'الجميع' : 'Everyone',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                    ));
                  }
                  return voters;
                }(),
              ],
            )
          : Text(
              widget.uiLanguage == 'ar' 
                  ? 'بواسطة: $_answeredPlayerName'
                  : 'By: $_answeredPlayerName',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
      ),
    );
  }

  Widget _buildLiveSkipVotesBadge() {
    final colors = [
      Colors.cyan,
      Colors.pinkAccent,
      Colors.amber,
      Colors.lightGreenAccent,
    ];
    final List<Widget> children = [
      const Text('⏭️ ', style: TextStyle(fontSize: 16)),
    ];
    
    int addedCount = 0;
    for (int i = 0; i < widget.playerNames.length; i++) {
      final teamKey = 'team${i + 1}';
      final voterName = _currentSkipVotes[teamKey];
      if (voterName != null) {
        if (addedCount > 0) {
          children.add(Text(' & ', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white70)));
        }
        children.add(Text(
          voterName,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: colors[i % colors.length],
          ),
        ));
        addedCount++;
      }
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(_currentSkipVotes.toString()),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.15),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.orange, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }

  Widget _buildEarnedPointsBadge() {
    final isCorrect = (_earnedPoints ?? 0) > 0;
    final isPenalty = (_earnedPoints ?? 0) < 0;
    final isSkip = _answeredPlayerName == 'SKIP' || _isSkipped;
    
    return FadeInDown(
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: (isCorrect 
              ? Colors.green 
              : (isSkip 
                  ? Colors.grey 
                  : (isPenalty ? Colors.red : Colors.red))).withOpacity(0.9),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: Text(
          isCorrect 
            ? "+$_earnedPoints ${_t('earnedPoints')}" 
            : (isSkip 
                ? "0 ${_t('earnedPoints')}" 
                : "$_earnedPoints ${_t('earnedPoints')}"),
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildQuestionContent() {
    final double maxWidth = widget.isTeamMode ? 1300 : 1150;
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: widget.isTeamMode ? 20 : 0),
        constraints: BoxConstraints(maxWidth: maxWidth), 
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.isTeamMode) ...[
              SizedBox(
                height: 45,
                child: _isAnswered ? Center(child: _buildEarnedPointsBadge()) : null,
              ),
              const SizedBox(height: 15),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildVerticalScoreboard(widget.playerNames[_currentPlayerIndex]),
                const SizedBox(width: 40),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isTeamMode && !_isAnswered) ...[
                      _buildPointsDisplay(isLarge: false),
                      const SizedBox(height: 20),
                    ],
                    _buildRoundDisplay(),
                  ],
                ),
                const SizedBox(width: 40),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, 
                          crossAxisSpacing: 16, 
                          mainAxisSpacing: 8,
                          childAspectRatio: widget.isTeamMode ? 2.8 : 1.85,
                        ),
                        itemCount: widget.isTeamMode ? 6 : 4,
                        itemBuilder: (context, index) {
                          final song = _currentQuestion!.options[index];
                          return _OptionCard(
                            song: song,
                            isSelected: _selectedOptionId == song.id,
                            isCorrect: song.id == _currentQuestion!.correctSong.id,
                            isAnswered: _isAnswered,
                            isTeamMode: widget.isTeamMode,
                            isHidden: _hiddenOptionIds.contains(song.id),
                            isLastHint: _lastHintId == song.id,
                            isHardMode: widget.isHardMode,
                            onTap: () => _handleOptionSelected(song),
                            buildArtwork: _buildArtwork,
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      if (!_isAnswered && !widget.isTeamMode)
                        ElasticIn(
                          child: ElevatedButton(
                            onPressed: (_hintsUsed >= 2) ? null : _useHint,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _hintsUsed >= 2 ? Colors.grey : Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            ),
                            child: Text(_hintsUsed >= 2 ? _t('noHints') : _t('hint')),
                          ),
                        ),
                      if (_isAnswered)
                        FadeInUp(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: ElevatedButton.icon(
                              onPressed: _nextTurn,
                              icon: const Icon(Icons.arrow_forward, color: Colors.white),
                              label: Text(
                                widget.uiLanguage == 'ar' ? "الجولة التالية" : "NEXT TURN", 
                                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                elevation: 5,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white12, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ]
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.uiLanguage == 'ar' ? 'الجولة' : 'ROUND',
            style: GoogleFonts.outfit(
              fontSize: 20, 
              fontWeight: FontWeight.w800, 
              color: Colors.white60, 
              letterSpacing: 3.0
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "$_currentRound",
            style: GoogleFonts.outfit(
              fontSize: 130, 
              fontWeight: FontWeight.w900, 
              color: Colors.orangeAccent,
              height: 0.9,
            ),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: _buildRoundIndicators(),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundIndicators() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(widget.totalRounds, (index) {
        final roundNum = index + 1;
        final bool isCompleted = roundNum < _currentRound;
        final bool isActive = roundNum == _currentRound;
        
        Color indicatorColor = Colors.white24;
        double size = 14;
        
        if (isActive) {
          indicatorColor = Colors.orangeAccent;
          size = 16;
        } else if (isCompleted) {
          indicatorColor = Colors.orangeAccent.withOpacity(0.5);
        }
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: indicatorColor,
            borderRadius: BorderRadius.circular(4), // Modern rounded squares
            boxShadow: isActive ? [
              BoxShadow(
                color: Colors.orangeAccent.withOpacity(0.6),
                blurRadius: 10,
                spreadRadius: 2.0,
              )
            ] : null,
          ),
        );
      }),
    );
  }

  Widget _buildBuzzerLayout() {
    final teamCount = widget.playerNames.length;
    final colors = [
      Colors.cyan,
      Colors.pinkAccent,
      Colors.amber,
      Colors.lightGreenAccent,
    ];

    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (event) {
        if (widget.roomCode != null) return; // Disable keyboard buzzing only in Mobile Controller Mode
        if (event is KeyDownEvent) {
          final leftKeys = [
            // Numbers
            LogicalKeyboardKey.digit1, LogicalKeyboardKey.digit2, LogicalKeyboardKey.digit3, LogicalKeyboardKey.digit4, LogicalKeyboardKey.digit5,
            // Row 1
            LogicalKeyboardKey.keyQ, LogicalKeyboardKey.keyW, LogicalKeyboardKey.keyE, LogicalKeyboardKey.keyR, LogicalKeyboardKey.keyT,
            // Row 2
            LogicalKeyboardKey.keyA, LogicalKeyboardKey.keyS, LogicalKeyboardKey.keyD, LogicalKeyboardKey.keyF, LogicalKeyboardKey.keyG,
            // Row 3
            LogicalKeyboardKey.keyZ, LogicalKeyboardKey.keyX, LogicalKeyboardKey.keyC, LogicalKeyboardKey.keyV,
            // Functional Left-side keys
            LogicalKeyboardKey.tab, LogicalKeyboardKey.capsLock, LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.backquote,
          ];
          
          final rightKeys = [
            // Numbers
            LogicalKeyboardKey.digit8, LogicalKeyboardKey.digit9, LogicalKeyboardKey.digit0, LogicalKeyboardKey.minus,
            // Row 1
            LogicalKeyboardKey.keyI, LogicalKeyboardKey.keyO, LogicalKeyboardKey.keyP,
            // Row 2
            LogicalKeyboardKey.keyJ, LogicalKeyboardKey.keyK, LogicalKeyboardKey.keyL, LogicalKeyboardKey.semicolon,
            // Row 3
            LogicalKeyboardKey.keyM, LogicalKeyboardKey.comma, LogicalKeyboardKey.period, LogicalKeyboardKey.slash,
            // Extra symbols (moved to Team 2)
            LogicalKeyboardKey.quote, LogicalKeyboardKey.bracketLeft, LogicalKeyboardKey.bracketRight, LogicalKeyboardKey.equal,
            // Additional Right-side keys
            LogicalKeyboardKey.backspace, LogicalKeyboardKey.backslash, LogicalKeyboardKey.enter, LogicalKeyboardKey.shiftRight,
          ];
          
          final isAr = widget.uiLanguage == 'ar';
          if (leftKeys.contains(event.logicalKey)) {
            _handleBuzz(isAr ? 1 : 0); 
          } else if (rightKeys.contains(event.logicalKey)) {
            _handleBuzz(isAr ? 0 : 1);
          }
        }
      },
      child: Stack(
        children: [
          // Circular Wheel Background Custom Painter
          Positioned.fill(
            child: Center(
              child: CustomPaint(
                size: const Size(600, 600),
                painter: GTSWheelPainter(
                  teamCount: teamCount,
                  colors: colors,
                  activeTeamIndex: _buzzerPressed ? _activeTeamIndex : null,
                ),
              ),
            ),
          ),

          // Central Pulsing Info Card (Logo, status, points)
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E293B),
                boxShadow: [
                  BoxShadow(
                    color: (_buzzerPressed && _activeTeamIndex != null)
                        ? colors[_activeTeamIndex! % colors.length].withOpacity(0.5)
                        : Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                  const BoxShadow(
                    color: Colors.black54,
                    blurRadius: 15,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: (_buzzerPressed && _activeTeamIndex != null)
                          ? [
                              ZoomIn(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  widget.uiLanguage == 'ar' ? "تم الضغط!" : "BUZZED!",
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white70,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ZoomIn(
                                duration: const Duration(milliseconds: 350),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(
                                    _buzzedPlayerName ?? widget.playerNames[_activeTeamIndex!],
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: colors[_activeTeamIndex! % colors.length],
                                      shadows: [
                                        Shadow(
                                          color: colors[_activeTeamIndex! % colors.length].withOpacity(0.5),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (_buzzedPlayerName != null) ...[
                                const SizedBox(height: 4),
                                ZoomIn(
                                  duration: const Duration(milliseconds: 400),
                                  child: Text(
                                    widget.playerNames[_activeTeamIndex!],
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white38,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              ZoomIn(
                                duration: const Duration(milliseconds: 450),
                                child: TextButton(
                                  onPressed: _triggerShowChoices,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                    backgroundColor: colors[_activeTeamIndex! % colors.length].withOpacity(0.2),
                                    side: BorderSide(
                                      color: colors[_activeTeamIndex! % colors.length].withOpacity(0.8),
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  child: Text(
                                    widget.uiLanguage == 'ar' ? 'عرض الخيارات' : 'SHOW CHOICES',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: colors[_activeTeamIndex! % colors.length],
                                    ),
                                  ),
                                ),
                              ),
                            ]
                          : [
                              Pulse(
                                infinite: true,
                                child: Image.asset(
                                  'assets/Guess_that_song_logo.png',
                                  height: 85,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _isAudioLoading
                                    ? (widget.uiLanguage == 'ar' ? 'جاري التحميل...' : 'LOADING...')
                                    : (widget.uiLanguage == 'ar' ? 'استمع جيداً...' : 'LISTENING...'),
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _isAudioLoading
                                  ? const SizedBox(
                                      height: 35,
                                      child: Center(
                                        child: SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                    )
                                  : _buildPointsDisplay(isLarge: false),
                            ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Positioning individual Team overlay widgets dynamically over each sector
          ...List.generate(teamCount, (index) {
            // angle division: 360 / teamCount
            // We want to offset by a standard starting angle (-pi / 2 is top) so the first team is at the top/top-left
            // To rotate sectors nicely:
            final double sectorAngle = 2 * math.pi / teamCount;
            // Center angle of this team's sector:
            final double midAngle = -math.pi / 2 + (index * sectorAngle) + (sectorAngle / 2);
            
            final isBuzzed = _buzzerPressed && _activeTeamIndex == index;
            final isAnyBuzzed = _buzzerPressed;
            final double opacity = isAnyBuzzed ? (isBuzzed ? 1.0 : 0.15) : 1.0;

            // Placement radius from center
            final double currentRadius = isBuzzed ? 215.0 : 200.0; // Pop out by 15 pixels if buzzed
            final double xOffset = currentRadius * math.cos(midAngle);
            final double yOffset = currentRadius * math.sin(midAngle);

            final name = widget.playerNames[index];
            final members = widget.teamMembers?[name] ?? [];
            final color = colors[index % colors.length];

            Widget sectorWidget = SizedBox(
              width: 170,
              height: 170,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Team Name / Indicator
                  Text(
                    name.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(color: color.withOpacity(0.5), blurRadius: 10),
                      ],
                    ),
                  ),
                  
                  // Members
                  if (members.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      members.join(", "),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  
                  const SizedBox(height: 8),

                  // Buzz Button / Status
                  InkWell(
                    onTap: () => _handleBuzz(index),
                    borderRadius: BorderRadius.circular(40),
                    child: AnimatedScale(
                      scale: isBuzzed ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isBuzzed ? color : color.withOpacity(0.12),
                          border: Border.all(
                            color: isBuzzed ? Colors.white : color.withOpacity(0.6),
                            width: isBuzzed ? 3 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(isBuzzed ? 0.7 : 0.25),
                              blurRadius: isBuzzed ? 25 : 10,
                              spreadRadius: isBuzzed ? 3 : 1,
                            )
                          ],
                        ),
                        child: Center(
                          child: isBuzzed
                              ? const Icon(Icons.flash_on, color: Colors.white, size: 32)
                              : Text(
                                  'BUZZ',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: color,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Mini Skip button
                  _buildMiniSkipButton(index),
                ],
              ),
            );

            if (_isBuzzShaking && isBuzzed) {
              sectorWidget = ShakeX(
                duration: const Duration(milliseconds: 500),
                child: sectorWidget,
              );
            } else if (isBuzzed) {
              sectorWidget = Pulse(
                infinite: true,
                duration: const Duration(seconds: 1),
                child: sectorWidget,
              );
            }

            return Center(
              child: Transform.translate(
                offset: Offset(xOffset, yOffset),
                child: AnimatedOpacity(
                  opacity: opacity,
                  duration: const Duration(milliseconds: 300),
                  child: sectorWidget,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMiniSkipButton(int teamIndex) {
    final teamKey = 'team${teamIndex + 1}';
    final hasVoted = _currentSkipVotes.containsKey(teamKey);
    final colors = [
      Colors.cyan,
      Colors.pinkAccent,
      Colors.amber,
      Colors.lightGreenAccent,
    ];
    final color = colors[teamIndex % colors.length];
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleSkipVote(teamIndex),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: hasVoted ? color.withOpacity(0.2) : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: hasVoted ? color : Colors.white12, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasVoted ? Icons.check : Icons.fast_forward,
                size: 13,
                color: hasVoted ? color : Colors.white38,
              ),
              const SizedBox(width: 4),
              Text(
                hasVoted
                    ? (widget.uiLanguage == 'ar' ? 'تم' : 'VOTED')
                    : (widget.uiLanguage == 'ar' ? 'تخطي؟' : 'SKIP?'),
                style: GoogleFonts.outfit(
                  color: hasVoted ? color : Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyZoneHint({required String title, required String keys, required Color color, required bool isLeft}) {
    return FadeInUp(
      delay: Duration(milliseconds: isLeft ? 1000 : 1200),
      child: Container(
        width: 260,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4), width: 2),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.1), blurRadius: 20, spreadRadius: 2),
          ],
        ),
        child: Column(
          children: [
            Text(
              title.toUpperCase(),
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: color, letterSpacing: 1),
            ),
            const SizedBox(height: 15),
            _buildKeyboardMiniMap(color, isLeft),
            const SizedBox(height: 15),
            Icon(isLeft ? Icons.keyboard_double_arrow_left_rounded : Icons.keyboard_double_arrow_right_rounded, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboardMiniMap(Color color, bool isLeftSection) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          _buildKeyboardRow(12, color, isLeftSection, 0),
          const SizedBox(height: 4),
          _buildKeyboardRow(11, color, isLeftSection, 1),
          const SizedBox(height: 4),
          _buildKeyboardRow(10, color, isLeftSection, 2),
          const SizedBox(height: 4),
          _buildKeyboardRow(9, color, isLeftSection, 3),
        ],
      ),
    );
  }

  Widget _buildKeyboardRow(int count, Color color, bool isLeftSection, int rowIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        bool isHighlighted = false;
        
        if (isLeftSection) {
          // Team 1: Left 5 keys roughly
          isHighlighted = index < 5;
        } else {
          // Team 2: Right 5 keys roughly
          isHighlighted = index >= (count - 5);
        }

        return Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isHighlighted ? color : Colors.white10,
            borderRadius: BorderRadius.circular(3),
            boxShadow: isHighlighted ? [
              BoxShadow(color: color.withOpacity(0.5), blurRadius: 4, spreadRadius: 1),
            ] : null,
          ),
        );
      }),
    );
  }

  Widget _buildKeyboardHints() {
    final isAr = widget.uiLanguage == 'ar';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildKeyZoneHint(
          title: widget.playerNames[0],
          keys: _t('team1Keys'),
          color: Colors.cyan,
          isLeft: !isAr,
        ),
        const SizedBox(width: 40),
        _buildKeyZoneHint(
          title: widget.playerNames[1],
          keys: _t('team2Keys'),
          color: Colors.pinkAccent,
          isLeft: isAr,
        ),
      ],
    );
  }

  Widget _buildBuzzButton(int index) {
    final name = widget.playerNames[index];
    final members = widget.teamMembers?[name] ?? [];
    final color = index == 0 ? Colors.cyan : Colors.pinkAccent;
    final isLeft = widget.uiLanguage == 'ar' ? index != 0 : index == 0;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          children: [
            // TOP SECTION: The Buzzer (Massive catch area)
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _handleBuzz(index),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Spacer(),
                        Text(
                          name.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: color,
                            fontSize: 72,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                        if (members.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              members.join(", "),
                              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const Spacer(),
                        if (widget.roomCode == null) _buildKeyboardMiniMap(color, isLeft),
                        if (widget.roomCode == null) const Spacer(),
                        if (widget.roomCode != null)
                          AnimatedScale(
                            scale: (_buzzerPressed && _activeTeamIndex == index) ? 0.8 : 1.0,
                            duration: const Duration(milliseconds: 100),
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color.withOpacity(0.15),
                                border: Border.all(color: color.withOpacity(0.6), width: 4),
                                boxShadow: [
                                  BoxShadow(color: color.withOpacity(0.2), blurRadius: 30, spreadRadius: 5)
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'BUZZ',
                                  style: GoogleFonts.outfit(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: color,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          Column(
                            children: [
                              Text(_t('pressAnySide'), style: GoogleFonts.outfit(color: Colors.white30, fontSize: 12)),
                              const SizedBox(height: 10),
                              const Icon(Icons.touch_app, color: Colors.white10, size: 40),
                            ],
                          ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // BOTTOM SECTION: Skip Button (Safe, separate area)
            _buildSkipButton(index),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBuzzAlert() {
    final teamName = widget.playerNames[_activeTeamIndex!];
    final colors = [
      Colors.cyan,
      Colors.pinkAccent,
      Colors.amber,
      Colors.lightGreenAccent,
    ];
    final color = colors[_activeTeamIndex! % colors.length];

    return Container(
      color: Colors.black,
      child: Center(
        child: ZoomIn(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.uiLanguage == 'ar' ? "تم الضغط بواسطة" : "BUZZED IN!",
                style: GoogleFonts.outfit(fontSize: 24, color: Colors.white60, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                _buzzedPlayerName ?? teamName,
                style: GoogleFonts.outfit(fontSize: 96, color: color, fontWeight: FontWeight.w900),
              ),
              if (_buzzedPlayerName != null && widget.isTeamMode) ...[
                const SizedBox(height: 10),
                Text(
                  widget.uiLanguage == 'ar' ? '(فريق $teamName)' : '($teamName)',
                  style: GoogleFonts.outfit(fontSize: 32, color: color.withOpacity(0.7), fontWeight: FontWeight.bold),
                ),
              ],
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _triggerShowChoices,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(
                  widget.uiLanguage == 'ar' ? 'اظهر الخيارات' : 'SHOW CHOICES',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton(int teamIndex) {
    final teamKey = 'team${teamIndex + 1}';
    final hasVoted = _currentSkipVotes.containsKey(teamKey);
    final colors = [
      Colors.cyan,
      Colors.pinkAccent,
      Colors.amber,
      Colors.lightGreenAccent,
    ];
    final color = colors[teamIndex % colors.length];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleSkipVote(teamIndex),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: hasVoted ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: hasVoted ? color : Colors.white10, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(hasVoted ? Icons.check_circle : Icons.fast_forward, size: 24, color: hasVoted ? color : Colors.white38),
                const SizedBox(width: 12),
                Text(
                  hasVoted 
                    ? (widget.uiLanguage == 'ar' ? 'تم التصويت للتخطي' : 'VOTED TO SKIP')
                    : (widget.uiLanguage == 'ar' ? 'تخطي الأغنية؟' : 'SKIP SONG?'),
                  style: GoogleFonts.outfit(
                    color: hasVoted ? color : Colors.white38, 
                    fontSize: 18, 
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSkipVote(int teamIndex) {
    if (_isAnswered || _buzzerPressed || _isLoading) return;
    
    final teamKey = 'team${teamIndex + 1}';
    
    if (widget.roomCode != null) {
      final hasVoted = _currentSkipVotes.containsKey(teamKey);
      if (hasVoted) {
        FirebaseService().removeSkipVote(widget.roomCode!, teamKey);
      } else {
        FirebaseService().voteToSkip(widget.roomCode!, teamKey, "HOST");
      }
    } else {
      setState(() {
        if (_currentSkipVotes.containsKey(teamKey)) {
          _currentSkipVotes.remove(teamKey);
        } else {
          _currentSkipVotes[teamKey] = widget.playerNames[teamIndex];
        }
        
        // Trigger skip if all active teams voted
        bool allVotedLocal = true;
        for (int i = 0; i < widget.playerNames.length; i++) {
          if (!_currentSkipVotes.containsKey('team${i + 1}')) {
            allVotedLocal = false;
            break;
          }
        }
        if (allVotedLocal) {
          _handleSongSkip(widget.playerNames[0], widget.playerNames[1]);
        }
      });
    }
  }

  Widget _buildPointsDisplay({required bool isLarge}) {
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(milliseconds: 100), (i) => i),
      builder: (context, snapshot) {
        // Double-Phase Logic:
        // 1. If not buzzed yet: Listening Time is current elapsed, Selection Time is 0
        // 2. If buzzed: Listening Time is fixed _buzzTimeSeconds, Selection Time is current elapsed (which resets on reveal)
        final listeningTime = _buzzTimeSeconds ?? (_responseTimer.elapsedMilliseconds / 1000.0);
        final selectionTime = _buzzerPressed ? (_responseTimer.elapsedMilliseconds / 1000.0) : 0.0;
        
        final listeningPart = (1000 - (listeningTime * 25)).clamp(500.0, 1000.0);
        final selectionPenalty = selectionTime * 50;
        
        final total = (listeningPart - selectionPenalty).toInt().clamp(-250, 1000);
        final isNegative = total < 0;
        final displayColor = isNegative ? Colors.redAccent : Colors.greenAccent;
        
        return ZoomIn(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: isLarge ? 40 : 24, vertical: isLarge ? 16 : 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [displayColor, displayColor.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(isLarge ? 35 : 25),
              boxShadow: [
                BoxShadow(color: displayColor.withOpacity(0.5), blurRadius: isNegative ? (isLarge ? 40 : 25) : (isLarge ? 25 : 15), spreadRadius: isLarge ? 4 : 2),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isNegative) 
                   Flash(infinite: true, child: Icon(Icons.warning_amber_rounded, color: Colors.white, size: isLarge ? 40 : 24)),
                if (isNegative) SizedBox(width: isLarge ? 12 : 8),
                Text(
                  "${total > 0 ? '+' : ''}$total ${_t('points')}",
                  style: GoogleFonts.outfit(fontSize: isLarge ? 48 : 24, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedbackOverlay(Color color, String text) {
    return Center(
      child: FadeInUp(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          decoration: BoxDecoration(color: color.withOpacity(0.9), borderRadius: BorderRadius.circular(40)),
          child: Text(text, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildOptionCard(Song song) {
    return _OptionCard(
      song: song,
      isSelected: _selectedOptionId == song.id,
      isCorrect: _currentQuestion != null && song.id == _currentQuestion!.correctSong.id,
      isAnswered: _isAnswered,
      isHidden: _hiddenOptionIds.contains(song.id),
      isLastHint: song.id == _lastHintId,
      isHardMode: widget.isHardMode,
      isTeamMode: widget.isTeamMode,
      onTap: () => _handleOptionSelected(song),
      buildArtwork: _buildArtwork,
    );
  }

  Widget _buildArtwork(Song song) {
    if (song.artworkUrl == null) return Container(color: Colors.grey[850], child: const Icon(Icons.music_note, color: Colors.white70));
    final cachedPath = MediaCacheService().getCachedPath(song.artworkUrl!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: cachedPath != null ? Image.file(File(cachedPath), fit: BoxFit.cover) : Image.network(song.artworkUrl!, fit: BoxFit.cover),
    );
  }
}

class _OptionCard extends StatefulWidget {
  final Song song;
  final bool isSelected;
  final bool isCorrect;
  final bool isAnswered;
  final bool isHidden;
  final bool isLastHint;
  final bool isHardMode;
  final bool isTeamMode;
  final VoidCallback onTap;
  final Widget Function(Song) buildArtwork;

  const _OptionCard({
    required this.song,
    required this.isSelected,
    required this.isCorrect,
    required this.isAnswered,
    required this.isHidden,
    required this.isLastHint,
    required this.isHardMode,
    required this.isTeamMode,
    required this.onTap,
    required this.buildArtwork,
  });

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard> with TickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _scanController;
  late AnimationController _impactController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _orbitController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _impactController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _shimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _orbitController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

    if (widget.isLastHint) {
       _scanController.forward();
       _impactController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _OptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLastHint && !oldWidget.isLastHint) {
      _scanController.forward(from: 0);
      _impactController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _impactController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.transparent;
    if (widget.isAnswered) {
      if (widget.isCorrect) borderColor = Colors.greenAccent;
      else if (widget.isSelected) borderColor = Colors.redAccent;
    } else if (_isHovered) {
      borderColor = Colors.white;
    }

    Widget artwork = widget.buildArtwork(widget.song);

    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      transform: Matrix4.identity()..scale(_isHovered && !widget.isAnswered && !widget.isHidden ? 1.05 : 1.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: (_isHovered || widget.isAnswered) ? 3 : 1.5),
        boxShadow: _isHovered && !widget.isAnswered && !widget.isHidden
          ? [BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)]
          : (widget.isAnswered && widget.isCorrect 
              ? [BoxShadow(color: Colors.greenAccent.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)]
              : null),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: artwork,
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.all(widget.isTeamMode ? 12 : 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, 
                  end: Alignment.topCenter, 
                  colors: [
                    Colors.black.withOpacity(widget.isTeamMode ? 0.95 : 0.8), 
                    Colors.black.withOpacity(0.0)
                  ]
                )
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    SongRepository().currentLibraryType == 'arabic' 
                      ? (widget.song.artistAr ?? widget.song.artist)
                      : widget.song.artist,
                    style: GoogleFonts.outfit(
                      color: Colors.white, 
                      fontSize: 17, 
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      shadows: [
                        const Shadow(color: Colors.black, blurRadius: 12, offset: Offset(0, 2)),
                      ]
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (!widget.isHardMode || widget.isAnswered) ...[
                    const SizedBox(height: 4),
                    Text(
                      SongRepository().currentLibraryType == 'arabic' 
                        ? (widget.song.titleAr ?? widget.song.title)
                        : widget.song.title,
                      style: GoogleFonts.outfit(
                        color: Colors.amberAccent, 
                        fontSize: 13, 
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        shadows: [
                          const Shadow(color: Colors.black, blurRadius: 8, offset: Offset(0, 1)),
                        ]
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (widget.isAnswered)
            Container(color: widget.isCorrect ? Colors.green.withOpacity(0.3) : (widget.isSelected ? Colors.red.withOpacity(0.3) : Colors.black.withOpacity(0.6))),
          
          // Laser Scan Upgrade
          if (widget.isLastHint)
            AnimatedBuilder(
              animation: _scanController,
              builder: (context, child) {
                return Positioned(
                  top: _scanController.value * 200 - 50,
                  left: 0, right: 0,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.redAccent.withOpacity(0),
                          Colors.white.withOpacity(0.9),
                          Colors.redAccent.withOpacity(0.5),
                          Colors.redAccent.withOpacity(0),
                        ],
                        stops: const [0.0, 0.45, 0.55, 1.0],
                      ),
                      boxShadow: [
                         BoxShadow(color: Colors.redAccent.withOpacity(0.6), blurRadius: 15, spreadRadius: 2),
                         BoxShadow(color: Colors.white.withOpacity(0.4), blurRadius: 4),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );

    if (widget.isHidden) {
      if (widget.isLastHint) {
        card = FadeOut(
          delay: const Duration(milliseconds: 1200),
          duration: const Duration(milliseconds: 600),
          child: ShakeX(child: card, duration: const Duration(milliseconds: 500)),
        );
      } else {
        return const SizedBox.shrink();
      }
    } else if (widget.isAnswered && widget.isSelected && !widget.isCorrect) {
      card = ShakeX(child: card);
    } else if (widget.isAnswered && widget.isCorrect) {
      card = Flash(child: card, infinite: true, duration: const Duration(seconds: 4));
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: widget.isHidden ? SystemMouseCursors.basic : SystemMouseCursors.click,
          child: GestureDetector(
            onTap: (widget.isAnswered || widget.isHidden) ? null : widget.onTap,
            child: card,
          ),
        ),
        if (widget.isLastHint)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: ScaleTransition(
                  scale: CurvedAnimation(parent: _impactController, curve: Curves.elasticOut),
                  child: FadeTransition(
                    opacity: _impactController,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 1.0, end: 0.0),
                      duration: const Duration(milliseconds: 3000),
                      builder: (context, opacityValue, child) {
                        return Opacity(
                          opacity: (opacityValue * 2).clamp(0, 1),
                          child: child,
                        );
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // Orbiting Mini-Penalties
                          ...List.generate(3, (i) {
                            return AnimatedBuilder(
                              animation: _orbitController,
                              builder: (context, child) {
                                final angle = (_orbitController.value * 2 * math.pi) + (i * 2.1);
                                return Positioned(
                                  left: 0,
                                  top: 0,
                                  child: Transform.translate(
                                     offset: Offset(
                                       55 * (i % 2 == 0 ? 1 : -0.8) * (0.5 + 0.5 * i/3).clamp(0.5,1.5) * (math.cos(angle)),
                                       35 * (i % 2 == 0 ? 0.6 : -1) * (math.sin(angle)),
                                     ),
                                     child: Text("-", style: TextStyle(color: Colors.redAccent.withOpacity(0.6), fontWeight: FontWeight.bold, fontSize: 18)),
                                  ),
                                );
                              },
                            );
                          }),
                          
                          // Glassmorphic Shimmering Bubble
                          AnimatedBuilder(
                            animation: Listenable.merge([_pulseController, _shimmerController]),
                            builder: (context, child) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.redAccent.withOpacity(0.9),
                                      const Color(0xFF991B1B).withOpacity(0.95),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.redAccent.withOpacity(0.4 + 0.3 * _pulseController.value), 
                                      blurRadius: 15 + 10 * _pulseController.value, 
                                      spreadRadius: 2 + 2 * _pulseController.value,
                                    ),
                                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5, offset: const Offset(0, 4)),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    // Shimmer Light Sweep
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(25),
                                        child: Transform.translate(
                                          offset: Offset(_shimmerController.value * 200 - 100, 0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [
                                                  Colors.white.withOpacity(0),
                                                  Colors.white.withOpacity(0.3),
                                                  Colors.white.withOpacity(0),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.remove_circle_outline, color: Colors.white, size: 20),
                                        const SizedBox(width: 6),
                                        Text(
                                          "-100", 
                                          style: GoogleFonts.outfit(
                                            color: Colors.white, 
                                            fontWeight: FontWeight.w900, 
                                            fontSize: 24,
                                            shadows: [const Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class GTSWheelPainter extends CustomPainter {
  final int teamCount;
  final List<Color> colors;
  final int? activeTeamIndex;

  GTSWheelPainter({
    required this.teamCount,
    required this.colors,
    this.activeTeamIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2;
    // We want a hollow center (donut-like) where the central card sits
    const innerRadius = 140.0;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double sweepAngle = 2 * math.pi / teamCount;
    // Start angle offset by -pi/2 so index 0 starts at the top
    const double startAngleOffset = -math.pi / 2;

    for (int i = 0; i < teamCount; i++) {
      final color = colors[i % colors.length];
      final double startAngle = startAngleOffset + (i * sweepAngle);
      final isBuzzed = activeTeamIndex == i;

      double dx = 0.0;
      double dy = 0.0;
      if (isBuzzed) {
        final double midAngle = startAngle + (sweepAngle / 2);
        const double offsetDistance = 15.0; // Pop out by 15 pixels
        dx = offsetDistance * math.cos(midAngle);
        dy = offsetDistance * math.sin(midAngle);
      }
      final sectorCenter = Offset(center.dx + dx, center.dy + dy);

      // Draw sector background
      paint.color = color.withOpacity(isBuzzed ? 0.22 : 0.04);
      
      final path = Path();
      // Draw sector from innerRadius to outerRadius
      path.arcTo(
        Rect.fromCircle(center: sectorCenter, radius: outerRadius),
        startAngle + 0.02, // slight padding gap
        sweepAngle - 0.04,
        true,
      );
      path.arcTo(
        Rect.fromCircle(center: sectorCenter, radius: innerRadius),
        startAngle + sweepAngle - 0.02,
        -(sweepAngle - 0.04),
        false,
      );
      path.close();
      canvas.drawPath(path, paint);

      // Draw sector outer arc border
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isBuzzed ? 4.5 : 1.5
        ..color = isBuzzed ? color : color.withOpacity(0.25)
        ..isAntiAlias = true;

      canvas.drawArc(
        Rect.fromCircle(center: sectorCenter, radius: outerRadius),
        startAngle + 0.02,
        sweepAngle - 0.04,
        false,
        borderPaint,
      );

      // Draw sector inner arc border
      canvas.drawArc(
        Rect.fromCircle(center: sectorCenter, radius: innerRadius),
        startAngle + 0.02,
        sweepAngle - 0.04,
        false,
        borderPaint,
      );

      // Draw dividers / separator lines
      final dividerPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withOpacity(0.08)
        ..isAntiAlias = true;

      final double divAngle = startAngle;
      final offsetInner = Offset(
        sectorCenter.dx + innerRadius * math.cos(divAngle),
        sectorCenter.dy + innerRadius * math.sin(divAngle),
      );
      final offsetOuter = Offset(
        sectorCenter.dx + outerRadius * math.cos(divAngle),
        sectorCenter.dy + outerRadius * math.sin(divAngle),
      );
      canvas.drawLine(offsetInner, offsetOuter, dividerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GTSWheelPainter oldDelegate) {
    return oldDelegate.teamCount != teamCount ||
        oldDelegate.colors != colors ||
        oldDelegate.activeTeamIndex != activeTeamIndex;
  }
}
