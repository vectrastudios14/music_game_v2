import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/firebase_service.dart';

class ControllerBuzzerScreen extends StatefulWidget {
  final String roomCode;
  final String playerName;
  final String teamName; // 'team1' or 'team2'

  const ControllerBuzzerScreen({
    super.key,
    required this.roomCode,
    required this.playerName,
    required this.teamName,
  });

  @override
  State<ControllerBuzzerScreen> createState() => _ControllerBuzzerScreenState();
}

class _ControllerBuzzerScreenState extends State<ControllerBuzzerScreen> with SingleTickerProviderStateMixin {
  String _status = 'waiting';
  String? _buzzedTeam;
  String? _team1Name;
  String? _team2Name;
  String? _team3Name;
  String? _team4Name;
  String? _roomMode; // 'team' or 'individual'
  String? _activePlayer;
  String? _nextPlayer;
  List<Map<String, dynamic>> _options = [];
  String? _selectedOptionId;
  bool _choicesVisible = false;
  Timer? _countdownTimer;
  int _currentPoints = 0;
  bool _isPaused = false;
  Timer? _playTimer;
  int _playTimeSeconds = 0;
  bool _hasVotedToSkip = false;
  bool _isWaitingForReady = false;
  int _hintsUsed = 0;
  bool _isRequestingHint = false;
  late StreamSubscription _firebaseSubscription;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _firebaseSubscription = FirebaseService().listenToRoomCustom(widget.roomCode).listen((data) {
      if (!mounted) return;
      if (data.isEmpty) return;

      setState(() {
        _roomMode = data['mode'] ?? 'team';
        _activePlayer = data['activePlayer'];
        _nextPlayer = data['nextPlayer'];

        if (data['kicked_players'] != null && data['kicked_players'][widget.playerName] == true) {
          _status = 'kicked';
          _clearSession();
        } else {
          final newStatus = data['status'] ?? 'waiting';
          _isWaitingForReady = data['isWaitingForReady'] == true;
          final bool isIndividual = _roomMode == 'individual';
          final bool isMyTurn = isIndividual && _activePlayer == widget.playerName;
          final bool shouldPulse = (isIndividual && _isWaitingForReady && isMyTurn) || (!isIndividual && newStatus == 'playing');
          final bool wasPulsing = _pulseController.isAnimating;
          
          if (shouldPulse && !wasPulsing) {
            _pulseController.repeat(reverse: true);
          } else if (!shouldPulse && wasPulsing) {
            _pulseController.stop();
            _pulseController.reset();
          }

          if (newStatus == 'playing' && _status != 'playing') {
            _playTimeSeconds = 0;
            _hasVotedToSkip = false;
            _isRequestingHint = false;
            _playTimer?.cancel();
            _playTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
              if (mounted && _status == 'playing' && !_isPaused) {
                setState(() { _playTimeSeconds++; });
              } else if (!mounted || _status != 'playing') {
                timer.cancel();
              }
            });
          } else if (newStatus != 'playing') {
            _playTimer?.cancel();
          }
          _status = newStatus;
        }
        _buzzedTeam = data['buzzedTeam'];
        _team1Name = data['team1Name'];
        _team2Name = data['team2Name'];
        _team3Name = data['team3Name'];
        _team4Name = data['team4Name'];
        
        final newChoicesVisible = data['choicesVisible'] == true;
        if (newChoicesVisible && !_choicesVisible) {
          _currentPoints = data['basePoints'] ?? 1000;
          _countdownTimer?.cancel();
          _countdownTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
            if (!mounted) {
              timer.cancel();
              return;
            }
            setState(() {
              if (_currentPoints > -250) {
                _currentPoints -= 5;
              }
              if (_currentPoints <= -250) {
                _currentPoints = -250;
                timer.cancel();
              }
            });
          });
        } else if (!newChoicesVisible && _choicesVisible) {
          _countdownTimer?.cancel();
        }
        _choicesVisible = newChoicesVisible;

        if (data['options'] != null) {
          _options = List<Map<String, dynamic>>.from(
              (data['options'] as List).map((e) => Map<String, dynamic>.from(e as Map)));
        } else {
          _options = [];
        }
        if (data['selectedOptionInfo'] != null) {
          _selectedOptionId = data['selectedOptionInfo']['id']?.toString();
        } else {
          _selectedOptionId = null;
        }

        if (data['pauseState'] != null) {
          _isPaused = data['pauseState']['isPaused'] == true;
        } else {
          _isPaused = false;
        }
        _hintsUsed = data['hintsUsed'] ?? 0;
        if (data['hintRequested'] != true) {
          _isRequestingHint = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    _playTimer?.cancel();
    _firebaseSubscription.cancel();
    super.dispose();
  }

  void _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('roomCode');
    await prefs.remove('playerName');
    await prefs.remove('teamName');
  }

  void _pressBuzzer() async {
    if (_status == 'playing') {
      // Trigger haptic vibration on mobile devices
      HapticFeedback.vibrate();
      await FirebaseService().pressBuzzer(widget.roomCode, widget.playerName, widget.teamName);
    }
  }

  Widget _buildIndividualStatusContent(bool isMyTurn) {
    if (_status == 'kicked') {
      return Text(
        'YOU WERE KICKED!',
        style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.redAccent),
      );
    }
    if (_status == 'waiting') {
      return Text(
        'Waiting for host to start...',
        style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white70),
      );
    }

    if (isMyTurn) {
      if (_selectedOptionId != null) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 80, color: Colors.amber),
            const SizedBox(height: 20),
            Text(
              'Answer Submitted!',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber),
            ),
            const SizedBox(height: 10),
            Text(
              'Waiting for host...',
              style: GoogleFonts.outfit(fontSize: 16, color: Colors.white60),
            ),
          ],
        );
      }
      if (_isWaitingForReady) {
        return _buildIndividualReadyToStartControls();
      }
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.amber)),
          const SizedBox(height: 24),
          Text(
            'Your Turn! Look at your screen...',
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber),
          ),
        ],
      );
    } else {
      final String activePlayerName = _activePlayer ?? 'Active Player';
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hourglass_empty, size: 80, color: Colors.white30),
          const SizedBox(height: 24),
          Text(
            "Waiting for $activePlayerName...",
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "They are selecting their answer.",
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.white30),
          ),
        ],
      );
    }
  }

  Widget _buildBuzzerWidget(bool isBuzzerActive, Color teamColor, String statusText) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: GestureDetector(
        onTap: _pressBuzzer,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: isBuzzerActive ? 300 : 250,
          height: isBuzzerActive ? 300 : 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isBuzzerActive ? teamColor : Colors.grey.withOpacity(0.3),
            boxShadow: isBuzzerActive
                ? [
                    BoxShadow(
                      color: teamColor.withOpacity(0.4), 
                      blurRadius: 25, 
                      spreadRadius: 6
                    ),
                    BoxShadow(
                      color: teamColor.withOpacity(0.2), 
                      blurRadius: 45, 
                      spreadRadius: 12
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              isBuzzerActive ? 'BUZZ' : (_status == 'kicked' ? 'KICKED' : 'WAIT'),
              style: GoogleFonts.outfit(
                fontSize: _status == 'kicked' ? 36 : 48,
                fontWeight: FontWeight.w900,
                color: isBuzzerActive ? Colors.white : Colors.white54,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isIndividual = _roomMode == 'individual';
    final bool isMyTurn = isIndividual && _activePlayer == widget.playerName;
    final bool isNextTurn = isIndividual && _nextPlayer == widget.playerName;

    final colors = [
      Colors.cyan,
      Colors.pinkAccent,
      Colors.amber,
      Colors.lightGreenAccent,
    ];
    int teamIndex = 0;
    if (widget.teamName == 'team2') teamIndex = 1;
    else if (widget.teamName == 'team3') teamIndex = 2;
    else if (widget.teamName == 'team4') teamIndex = 3;

    final Color teamColor = isIndividual
        ? Colors.amber
        : colors[teamIndex % colors.length];

    final String defaultTeamDisplayName = isIndividual ? 'Individual' : 'Team ${teamIndex + 1}';
    String teamDisplayName = defaultTeamDisplayName;
    if (!isIndividual) {
      if (widget.teamName == 'team1') {
        teamDisplayName = (_team1Name != null && _team1Name!.isNotEmpty) ? _team1Name! : defaultTeamDisplayName;
      } else if (widget.teamName == 'team2') {
        teamDisplayName = (_team2Name != null && _team2Name!.isNotEmpty) ? _team2Name! : defaultTeamDisplayName;
      } else if (widget.teamName == 'team3') {
        teamDisplayName = (_team3Name != null && _team3Name!.isNotEmpty) ? _team3Name! : defaultTeamDisplayName;
      } else if (widget.teamName == 'team4') {
        teamDisplayName = (_team4Name != null && _team4Name!.isNotEmpty) ? _team4Name! : defaultTeamDisplayName;
      }
    }

    bool isBuzzerActive = !isIndividual && _status == 'playing';
    bool didWeBuzz = !isIndividual && _status == 'buzzed' && _buzzedTeam == widget.teamName;
    bool didTheyBuzz = !isIndividual && _status == 'buzzed' && _buzzedTeam != widget.teamName;

    String statusText;
    Color bgColor = Colors.black;

    if (isIndividual) {
      if (_status == 'kicked') {
        statusText = 'YOU WERE KICKED!';
        bgColor = Colors.red.withOpacity(0.5);
      } else if (_status == 'waiting') {
        statusText = 'Waiting for host to start...';
        bgColor = Colors.black;
      } else if (_status == 'buzzed' && _options.isEmpty) {
        statusText = isNextTurn ? 'YOUR TURN IS NEXT!' : 'Waiting for next turn...';
        bgColor = Colors.black;
      } else if (isMyTurn) {
        statusText = 'YOUR TURN!';
        bgColor = Colors.black;
      } else {
        statusText = 'Waiting for $_activePlayer...';
        bgColor = Colors.black;
      }
    } else {
      if (_status == 'kicked') {
        statusText = 'YOU WERE KICKED!';
        bgColor = Colors.red.withOpacity(0.5);
      } else if (_status == 'waiting') {
        statusText = 'Waiting for host to start...';
      } else if (isBuzzerActive) {
        statusText = 'TAP TO BUZZ!';
        bgColor = teamColor.withOpacity(0.1);
      } else if (didWeBuzz) {
        statusText = 'YOU BUZZED!';
        bgColor = teamColor.withOpacity(0.3);
      } else if (didTheyBuzz) {
        statusText = 'TOO LATE!';
        bgColor = Colors.red.withOpacity(0.2);
      } else {
        statusText = 'Please wait...';
      }

      if (_choicesVisible && (didWeBuzz || didTheyBuzz)) {
        bgColor = Colors.black;
      }
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.playerName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    teamDisplayName,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: teamColor),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: (isIndividual ? (isMyTurn && _options.isNotEmpty && _choicesVisible) : (didWeBuzz && _options.isNotEmpty && _choicesVisible))
                    ? _buildOptionsGrid()
                    : (isIndividual
                        ? (_status == 'round_finished'
                            ? (isNextTurn
                                ? _buildIndividualPostRoundControls(teamColor)
                                : _buildIndividualWaitingForNextPlayer())
                            : _buildIndividualStatusContent(isMyTurn))
                        : ((_status == 'round_finished')
                            ? _buildPostRoundControls(teamColor)
                            : _buildBuzzerWidget(isBuzzerActive, teamColor, statusText)))
              ),
            ),
            if (!isIndividual && isBuzzerActive && _playTimeSeconds >= 20)
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: ElevatedButton.icon(
                  onPressed: _hasVotedToSkip ? null : () {
                    setState(() => _hasVotedToSkip = true);
                    FirebaseService().voteToSkip(widget.roomCode, widget.teamName, widget.playerName);
                  },
                  icon: Icon(_hasVotedToSkip ? Icons.check : Icons.skip_next, size: 24),
                  label: Text(
                    _hasVotedToSkip ? 'Waiting for other team...' : 'Skip this song',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasVotedToSkip ? Colors.grey : Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
            if (isIndividual
                ? !(_activePlayer == widget.playerName && _options.isNotEmpty && _choicesVisible)
                : (!(didWeBuzz && _options.isNotEmpty && _choicesVisible) && !(_status == 'round_finished')))
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Text(
                  statusText,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: didTheyBuzz ? Colors.redAccent : Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostRoundControls(Color teamColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'ROUND FINISHED!',
          style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 40),
        ElevatedButton.icon(
          icon: const Icon(Icons.skip_next, color: Colors.white),
          label: const Text('NEXT ROUND'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            backgroundColor: teamColor,
            textStyle: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 8,
          ),
          onPressed: () {
            FirebaseService().requestNextRound(widget.roomCode);
          },
        ),
      ],
    );
  }

  Widget _buildIndividualPostRoundControls(Color teamColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'YOUR TURN IS NEXT!',
          style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.amber),
        ),
        const SizedBox(height: 10),
        Text(
          'Are you ready?',
          style: GoogleFonts.outfit(fontSize: 16, color: Colors.white70),
        ),
        const SizedBox(height: 45),
        ElevatedButton.icon(
          icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 28),
          label: const Text('NEXT TURN'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 22),
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            textStyle: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 8,
          ),
          onPressed: () {
            FirebaseService().requestNextRound(widget.roomCode);
          },
        ),
      ],
    );
  }

  Widget _buildIndividualReadyToStartControls() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'YOUR TURN!',
          style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.amber),
        ),
        const SizedBox(height: 10),
        Text(
          'Tap START when you are ready to listen',
          style: GoogleFonts.outfit(fontSize: 16, color: Colors.white70),
        ),
        const SizedBox(height: 45),
        ScaleTransition(
          scale: _pulseAnimation,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.play_circle_filled_rounded, color: Colors.black, size: 28),
            label: const Text('START TURN'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 22),
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              textStyle: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 8,
            ),
            onPressed: () {
              FirebaseService().requestStartTurn(widget.roomCode);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIndividualWaitingForNextPlayer() {
    final nextName = _nextPlayer ?? 'next player';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.hourglass_empty_rounded, size: 80, color: Colors.white30),
        const SizedBox(height: 24),
        Text(
          "Waiting for $nextName...",
          style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "They need to press NEXT TURN to start.",
          style: GoogleFonts.outfit(fontSize: 16, color: Colors.white30),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOptionsGrid() {
    if (_selectedOptionId != null) {
      return Center(
        child: Text(
          "Waiting for Host...",
          style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          if (_roomMode != 'individual')
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stars_rounded, color: _currentPoints < 0 ? Colors.redAccent : Colors.yellowAccent, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    '${_currentPoints > 0 ? '+' : ''}$_currentPoints',
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: _currentPoints < 0 ? Colors.redAccent : Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Turn! / دورك!',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                  ElevatedButton.icon(
                    onPressed: (_hintsUsed >= 2 || _isRequestingHint) ? null : () {
                      setState(() {
                        _isRequestingHint = true;
                      });
                      FirebaseService().requestHint(widget.roomCode);
                    },
                    icon: Icon(
                      Icons.help_outline,
                      size: 18,
                      color: (_hintsUsed >= 2 || _isRequestingHint) ? Colors.white30 : Colors.black87,
                    ),
                    label: Text(
                      _hintsUsed >= 2 ? 'No Hints' : (_isRequestingHint ? 'Wait...' : 'Hint / تلميح (${2 - _hintsUsed})'),
                      style: TextStyle(
                        color: (_hintsUsed >= 2 || _isRequestingHint) ? Colors.white30 : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_hintsUsed >= 2 || _isRequestingHint) ? Colors.grey.withOpacity(0.3) : Colors.amber,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                final double height = constraints.maxHeight;
                
                const int cols = 2;
                final int rows = (_options.length / cols).ceil();
                
                final double itemWidth = (width - (cols - 1) * 10) / cols;
                // Calculate itemHeight to perfectly fit within the available height
                final double itemHeight = (height - (rows - 1) * 10) / rows;
                
                double aspectRatio = 1.1;
                if (itemWidth > 0 && itemHeight > 0) {
                  // Ensure aspectRatio is reasonable (between 0.8 and 2.5) to keep UI looking good
                  aspectRatio = (itemWidth / itemHeight).clamp(0.8, 2.5);
                }

                return GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: aspectRatio,
                  ),
                  itemCount: _options.length,
                  itemBuilder: (context, index) {
                    final opt = _options[index];
                    final bool isHidden = opt['hidden'] == true;
                    return Visibility(
                      visible: !isHidden,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: GestureDetector(
                        onTap: isHidden ? null : () {
                          FirebaseService().submitAnswer(widget.roomCode, opt['id'], widget.playerName);
                          setState(() {
                            _selectedOptionId = opt['id'];
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white24, width: 1.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Artwork Image
                                opt['artworkUrl'] != null && opt['artworkUrl'].toString().isNotEmpty
                                    ? Image.network(
                                        'https://images.weserv.nl/?url=${Uri.encodeComponent(opt['artworkUrl'].toString())}',
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(color: Colors.white10, child: const Center(child: Icon(Icons.music_note, color: Colors.white, size: 40))),
                                      )
                                    : Container(color: Colors.white10, child: const Center(child: Icon(Icons.music_note, color: Colors.white, size: 40))),
                                // Gradient Overlay at the bottom
                                Positioned(
                                  bottom: 0, left: 0, right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.black.withOpacity(0.95),
                                          Colors.black.withOpacity(0.0),
                                        ],
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          opt['artist'],
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                            shadows: [
                                              const Shadow(color: Colors.black, blurRadius: 8, offset: Offset(0, 1)),
                                            ],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          opt['title'],
                                          style: GoogleFonts.outfit(
                                            color: Colors.white70,
                                            fontSize: 11,
                                            shadows: [
                                              const Shadow(color: Colors.black, blurRadius: 8, offset: Offset(0, 1)),
                                            ],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
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
                  },
                );
              },
            ),
          ),
  ],
),
);
  }
}
