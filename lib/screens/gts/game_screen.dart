import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:audioplayers/audioplayers.dart'; 
import 'package:google_fonts/google_fonts.dart';

import '../../models/song.dart';
import '../../services/song_repository.dart';
import 'result_screen.dart';

import 'dart:io';
import '../../services/audio_cache_service.dart';

class GtsGameScreen extends StatefulWidget {
  final int totalRounds;
  final List<String> playerNames;
  final bool isHardMode;

  const GtsGameScreen({
    super.key,
    required this.totalRounds,
    required this.playerNames,
    required this.isHardMode,
  });

  @override
  State<GtsGameScreen> createState() => _GtsGameScreenState();
}

class _GtsGameScreenState extends State<GtsGameScreen> {
  // Game State
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

  // Hint State
  int _hintsUsed = 0;
  final Set<String> _hiddenOptionIds = {};
  
  // Buffering
  final List<Question> _questionBuffer = [];
  bool _isBuffering = false;

  // Timer & Scoring
  Stopwatch _responseTimer = Stopwatch();
  static const int _maxTimeBonus = 500;
  static const int _baseScore = 500;

  // Penalty Animation
  int _penaltyAnimationKey = 0;

  @override
  void initState() {
    super.initState();
    print('GTS: initState');
    _player = AudioPlayer(); 
    print('GTS: AudioPlayer created');
    _repository = SongRepository()..loadSongs();
    
    // Initialize scores
    for (var name in widget.playerNames) {
      _scores[name] = 0;
    }
    
    MediaCacheService().init();
    _startRound();
  }

  @override
  void dispose() {
    print('GTS: Disposal');
    _responseTimer.stop();
    _player.dispose(); 
    MediaCacheService().clearCache();
    super.dispose();
  }

  Future<void> _startRound() async {
    setState(() {
      _isLoading = true;
      _isAnswered = false;
      _selectedOptionId = null;
      _hintsUsed = 0;
      _hiddenOptionIds.clear();
    });

    try {
      if (_repository.allSongs.isEmpty) {
        await _repository.loadSongs();
      }

      Question? question;
      
      // 1. Check Repository Cache (from Setup)
      if (_repository.cachedNextQuestion != null && _history.isEmpty) {
        question = _repository.cachedNextQuestion;
        _repository.cachedNextQuestion = null; // Clear it after use
        debugPrint('GTS: Using PRE-LOADED question from Setup');
      } 
      // 2. Check Buffer
      else if (_questionBuffer.isNotEmpty) {
        question = _questionBuffer.removeAt(0);
        debugPrint('GTS: Using BUFFERED question');
      } 
      // 3. Fallback: load directly
      else {
        debugPrint('GTS: Buffer empty, loading directly');
        question = await _repository.getNextQuestion(_history);
      }
      
      if (mounted) {
        setState(() {
          _currentQuestion = question;
          _history.add(question!.correctSong);
          _isLoading = false;
        });
        
        // Play Audio (Check Cache)
        final audioUrl = question!.correctSong.link;
        final cachedAudio = MediaCacheService().getCachedPath(audioUrl);
        if (cachedAudio != null) {
             print('GTS: Playing audio from CACHE: $cachedAudio');
             await _player.play(DeviceFileSource(cachedAudio));
        } else {
             print('GTS: Playing audio from STREAM: $audioUrl');
             await _player.play(UrlSource(audioUrl));
        }
        
        _responseTimer.reset();
        _responseTimer.start();
        
        // Trigger Buffer refill for NEXT round
        _fillBuffer();
      }
    } catch (e) {
      print('GTS: Error starting round: $e');
    }
  }

  // Pre-load next questions
  Future<void> _fillBuffer() async {
    if (_isBuffering || _questionBuffer.length >= 2) return;
    
    _isBuffering = true;
    try {
      // Load next question
      // Note: We need to be careful not to pick songs already in _history or buffer
      // But _repository.getNextQuestion checks _history. 
      // We should ideally add buffered songs to a temporary 'reserved' list or just hope for best
      // To be safe, let's just fetch one.
      
      final nextQ = await _repository.getNextQuestion([..._history, ..._questionBuffer.map((q) => q.correctSong)]);
      
      // DOWNLOAD ASSETS
      
      // 1. Audio
      MediaCacheService().cacheFile(nextQ.correctSong.link);
      
      // 2. Artwork for options
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
      debugPrint('GTS: Buffered 1 new question. Total: ${_questionBuffer.length}');
      
      // Recursive fill if needed? Nah, one at a time is fine.
    } catch (e) {
      debugPrint('GTS: Buffering error: $e');
    } finally {
      _isBuffering = false;
    }
  }

  void _handleOptionSelected(Song selectedSong) {
    if (_isAnswered) return;

    _responseTimer.stop();
    _player.stop();

    setState(() {
      _isAnswered = true;
      _selectedOptionId = selectedSong.id;
    });

    final isCorrect = selectedSong.id == _currentQuestion!.correctSong.id;
    if (isCorrect) {
      final elapsed = _responseTimer.elapsedMilliseconds;
      final timeBonus = (_maxTimeBonus - (elapsed / 20)).clamp(0, _maxTimeBonus).toInt();
      final hintPenalty = _hintsUsed * 100;
      final totalPoints = (_baseScore + timeBonus - hintPenalty).clamp(0, 5000).toInt();

      _scores[widget.playerNames[_currentPlayerIndex]] = 
          (_scores[widget.playerNames[_currentPlayerIndex]] ?? 0) + totalPoints;
    }
  }

  void _nextTurn() {
    int nextIndex = _currentPlayerIndex + 1;
    if (nextIndex >= widget.playerNames.length) {
      nextIndex = 0;
      _currentRound++;
    }

    if (_currentRound > widget.totalRounds) {
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
    } else {
      setState(() {
        _currentPlayerIndex = nextIndex;
      });
      _startRound();
    }
  }

  void _useHint() {
    if (_currentQuestion == null || _isAnswered || _hintsUsed >= 2) return;

    final correctId = _currentQuestion!.correctSong.id;
    final visibleWrongOptions = _currentQuestion!.options.where((s) {
      return s.id != correctId && !_hiddenOptionIds.contains(s.id);
    }).toList();

    if (visibleWrongOptions.isNotEmpty) {
      setState(() {
        final toHide = (visibleWrongOptions..shuffle()).first;
        _hiddenOptionIds.add(toHide.id);
        _hintsUsed++;
        _penaltyAnimationKey++; // Trigger Simple Animation
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPlayer = widget.playerNames[_currentPlayerIndex];
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Round $_currentRound / ${widget.totalRounds}'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Quit to Setup',
            onPressed: () {
              _player.stop();
              Navigator.pop(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.lightbulb),
            tooltip: 'Use Hint (Max 2)',
            onPressed: (_isLoading || _isAnswered || _hintsUsed >= 2) 
                ? null 
                : _useHint,
          ),
        ],
      ),
      floatingActionButton: _isAnswered
          ? FloatingActionButton.extended(
              onPressed: _nextTurn,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('NEXT'),
              backgroundColor: Theme.of(context).primaryColor,
            )
          : null,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Top Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      children: [
                        Text(
                          "It's $currentPlayer's Turn!",
                          style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Score: ${_scores[currentPlayer]}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  // Main Content (Grid)
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: 500, 
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.0,
                            ),
                            itemCount: 4,
                            itemBuilder: (context, index) {
                              final song = _currentQuestion!.options[index];
                              return _buildOptionCard(song);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
          // SIMPLE PENALTY EFFECT (Center Screen)
          if (_penaltyAnimationKey > 0)
            Center(
              child: KeyedSubtree(
                key: ValueKey(_penaltyAnimationKey),
                child: FadeOutUp(
                  duration: const Duration(milliseconds: 2000),
                  from: 50, 
                  child: const Text(
                    "-100",
                    style: TextStyle(
                      fontSize: 100, 
                      fontWeight: FontWeight.w900,
                      color: Colors.red,
                      shadows: [
                        Shadow(blurRadius: 10, color: Colors.black, offset: Offset(2, 2))
                      ]
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(Song song) {
    bool isSelected = _selectedOptionId == song.id;
    bool isCorrect = song.id == _currentQuestion!.correctSong.id;
    
    Color borderColor = Colors.transparent;
    double borderWidth = 0;

    if (_isAnswered) {
      if (isCorrect) {
        borderColor = Colors.greenAccent;
        borderWidth = 4;
      } else if (isSelected && !isCorrect) {
        borderColor = Colors.redAccent;
        borderWidth = 4;
      }
    }

    if (_hiddenOptionIds.contains(song.id)) {
        return const SizedBox.shrink();
    } 

    return GestureDetector(
      onTap: () => _handleOptionSelected(song),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildArtwork(song),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Text(
                    widget.isHardMode ? song.artist : '${song.artist}\n${song.title}',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtwork(Song song) {
    if (song.artworkUrl == null) {
       return Container(
          color: Colors.grey[850],
          child: Icon(Icons.music_note, size: 64, color: Colors.white.withOpacity(0.5)),
       );
    }
    
    final cachedPath = MediaCacheService().getCachedPath(song.artworkUrl!);
    if (cachedPath != null) {
       return Image.file(File(cachedPath), fit: BoxFit.cover);
    } else {
       return Image.network(song.artworkUrl!, fit: BoxFit.cover);
    }
  }
}
