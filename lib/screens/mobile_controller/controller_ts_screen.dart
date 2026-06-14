import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/firebase_service.dart';

class ControllerTsScreen extends StatefulWidget {
  final String roomCode;
  final String playerName;

  const ControllerTsScreen({
    super.key,
    required this.roomCode,
    required this.playerName,
  });

  @override
  State<ControllerTsScreen> createState() => _ControllerTsScreenState();
}

class _ControllerTsScreenState extends State<ControllerTsScreen> {
  String _status = 'waiting';
  Map<String, int> _playerScores = {};
  Map<String, dynamic>? _currentSong;
  bool _isRoundResultShowing = false;
  bool _isWaitingForReady = false;
  String? _roundLoserName;
  int? _actualYear;
  String? _winner;

  late StreamSubscription _firebaseSubscription;
  late FixedExtentScrollController _scrollController;
  int _selectedYear = 1995; // Default middle year
  bool _hasSubmittedGuess = false;
  bool _isReadyClicked = false;
  int _startingPointsSetting = 100;
  bool _allPlayersGuessed = false;
  bool _showScoreOverlay = false;
  bool _isRevealTriggered = false;

  final int _startYear = 1970;
  final int _endYear = 2026;

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController(
      initialItem: _selectedYear - _startYear,
    );

    _firebaseSubscription = FirebaseService().listenToRoomCustom(widget.roomCode).listen((data) {
      if (!mounted) return;
      if (data.isEmpty) return;

      final oldSongTitle = _currentSong?['title'];

      setState(() {
        _status = data['status'] ?? 'waiting';
        _winner = data['winner'];
        _isRoundResultShowing = data['isRoundResultShowing'] == true;
        _isWaitingForReady = data['isWaitingForReady'] == true;
        _roundLoserName = data['roundLoserName'];
        _actualYear = data['actualYear'] != null ? int.tryParse(data['actualYear'].toString()) : null;

        if (data['startingPoints'] != null) {
          _startingPointsSetting = int.tryParse(data['startingPoints'].toString()) ?? 100;
        }

        // Sync Scores
        if (data['scores'] != null) {
          final rawScores = Map<String, dynamic>.from(data['scores'] as Map);
          _playerScores = rawScores.map((key, value) => MapEntry(key, int.tryParse(value.toString()) ?? 100));
        }

        // Song details
        if (data['currentSong'] != null) {
          _currentSong = Map<String, dynamic>.from(data['currentSong'] as Map);
        } else {
          _currentSong = null;
        }

        // Guesses list check
        final tsGuessesMap = data['tsGuesses'] != null ? Map<String, dynamic>.from(data['tsGuesses'] as Map) : {};
        _hasSubmittedGuess = tsGuessesMap.containsKey(widget.playerName);

        final playerNamesList = data['playerNames'] != null ? List<String>.from(data['playerNames'] as List) : [];
        _allPlayersGuessed = tsGuessesMap.isNotEmpty && tsGuessesMap.length >= playerNamesList.length;
        _showScoreOverlay = data['showScoreOverlay'] == true;
        _isRevealTriggered = data['triggerReveal'] == true;
      });

      // Reset PageView when a new song starts
      final newSongTitle = _currentSong?['title'];
      if (newSongTitle != null && newSongTitle != oldSongTitle) {
        setState(() {
          _selectedYear = 1995;
          _isReadyClicked = false;
          _hasSubmittedGuess = false;
        });
        if (_scrollController.hasClients) {
          _scrollController.jumpToItem(_selectedYear - _startYear);
        }
      }
    });
  }

  @override
  void dispose() {
    _firebaseSubscription.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('roomCode');
    await prefs.remove('playerName');
    await prefs.remove('teamName');
  }

  void _submitGuess() async {
    if (_hasSubmittedGuess) return;
    await FirebaseService().submitTsGuess(widget.roomCode, widget.playerName, _selectedYear);
    setState(() {
      _hasSubmittedGuess = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_status == 'kicked') {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.gavel,
                color: Colors.redAccent,
                size: 80,
              ),
              const SizedBox(height: 20),
              Text(
                'You have been removed',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  _clearSession();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Back to Home'),
              )
            ],
          ),
        ),
      );
    }

    if (_status == 'gameover' || _status == 'game_over') {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F0C1B), Color(0xFF150E28), Color(0xFF0A0515)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.amber.withOpacity(0.3), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: 100,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'GAME OVER',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        if (_winner != null && _winner!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            height: 1,
                            width: 150,
                            color: Colors.white24,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '🏆 WINNER 🏆',
                            style: GoogleFonts.outfit(
                              color: Colors.amberAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _winner!,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      _clearSession();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      'Back to Home',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            _buildSongBanner(),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final myScore = _playerScores[widget.playerName] ?? _startingPointsSetting;
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.playerName,
                style: GoogleFonts.outfit(
                  color: Colors.black87,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[300]!, width: 1),
                ),
                child: Text(
                  'HEALTH: $myScore HP',
                  style: GoogleFonts.outfit(
                    color: Colors.red[700],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.black54),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  title: const Text('Leave Lobby?', style: TextStyle(color: Colors.black87)),
                  content: const Text('Are you sure you want to disconnect?', style: TextStyle(color: Colors.black54)),
                  actions: [
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: () {
                        _clearSession();
                        Navigator.pop(context);
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      child: const Text('Leave'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_status == 'waiting') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.purple),
            const SizedBox(height: 24),
            Text(
              'Lobby Ready',
              style: GoogleFonts.outfit(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Wait for host to start...',
              style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_isRoundResultShowing) {
      return _buildResultsView();
    }

    if (!_isReadyClicked) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.purple[200]!, width: 2),
                ),
                child: const Icon(
                  Icons.lock_open,
                  color: Colors.purple,
                  size: 60,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Secret Guessing",
                style: GoogleFonts.outfit(
                  color: Colors.black87,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Tap below to unlock the timeline and enter your guess secretly.",
                style: GoogleFonts.outfit(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _isReadyClicked = true;
                    });
                  },
                  child: Text(
                    "UNLOCK TIMELINE",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasSubmittedGuess) {
      if (_allPlayersGuessed) {
        if (_isRevealTriggered) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.purple[200]!, width: 2),
                  ),
                  child: const CircularProgressIndicator(color: Colors.purple),
                ),
                const SizedBox(height: 32),
                Text(
                  "REVEALING GUESSES...",
                  style: GoogleFonts.outfit(
                    color: Colors.purple[800],
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Watch the TV screen to see everyone's guess!",
                  style: GoogleFonts.outfit(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green[200]!, width: 2),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.green,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "ALL GUESSES IN!",
                  style: GoogleFonts.outfit(
                    color: Colors.green[800],
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Everyone has submitted their guess. Tap below to reveal them on the TV!",
                  style: GoogleFonts.outfit(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      FirebaseService().triggerTsReveal(widget.roomCode);
                    },
                    child: Text(
                      "REVEAL GUESSES",
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green[200]!, width: 2),
              ),
              child: const Icon(
                Icons.check,
                color: Colors.green,
                size: 60,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "GUESS SUBMITTED!",
              style: GoogleFonts.outfit(
                color: Colors.green[800],
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Your guess is locked at $_selectedYear.\nWaiting for other players to submit...",
              style: GoogleFonts.outfit(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Select Song Year",
          style: GoogleFonts.outfit(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          height: 120,
          child: RotatedBox(
            quarterTurns: 3,
            child: ListWheelScrollView.useDelegate(
              controller: _scrollController,
              itemExtent: 120,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedYear = _startYear + index;
                });
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: _endYear - _startYear + 1,
                builder: (context, index) {
                  final year = _startYear + index;
                  final bool isSelected = year == _selectedYear;

                  return RotatedBox(
                    quarterTurns: 1,
                    child: Center(
                      child: AnimatedScale(
                        scale: isSelected ? 1.4 : 0.8,
                        duration: const Duration(milliseconds: 150),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            year.toString(),
                            maxLines: 1,
                            softWrap: false,
                            style: GoogleFonts.outfit(
                              color: isSelected ? Colors.purple[800] : Colors.grey[400],
                              fontSize: 32,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Icon(Icons.arrow_drop_up, color: Colors.purple, size: 36),
        const SizedBox(height: 50),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: _submitGuess,
              child: Text(
                "SUBMIT SECRET GUESS",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsView() {
    if (_actualYear == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final diff = (_selectedYear - _actualYear!).abs();
    final isLoser = _roundLoserName == widget.playerName;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isLoser ? Colors.red[50] : Colors.green[50],
                shape: BoxShape.circle,
                border: Border.all(color: isLoser ? Colors.red[200]! : Colors.green[200]!, width: 2),
              ),
              child: Icon(
                isLoser ? Icons.trending_down : Icons.thumb_up_alt_outlined,
                color: isLoser ? Colors.red : Colors.green,
                size: 60,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              isLoser ? "BIGGEST LOSS!" : "SURVIVED",
              style: GoogleFonts.outfit(
                color: isLoser ? Colors.red[800] : Colors.green[800],
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Actual Year: $_actualYear\nYour Guess: $_selectedYear\nDifference: $diff years (-$diff HP)",
              style: GoogleFonts.outfit(
                color: Colors.grey[700],
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            if (!_showScoreOverlay)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: () {
                    FirebaseService().triggerTsShowResults(widget.roomCode);
                  },
                  child: Text(
                    "VIEW SCOREBOARD",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: () {
                    FirebaseService().requestNextRound(widget.roomCode);
                  },
                  child: Text(
                    "START NEXT ROUND",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongBanner() {
    if (_currentSong == null || _status == 'waiting') {
      return const SizedBox.shrink();
    }

    final title = _currentSong!['title'] ?? 'Unknown Title';
    final artist = _currentSong!['artist'] ?? 'Unknown Artist';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)], // Purple to magenta-violet
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8E24AA).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.music_note,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "NOW PLAYING",
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  artist,
                  style: GoogleFonts.outfit(
                    color: Colors.purple[100],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
