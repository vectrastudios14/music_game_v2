import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/firebase_service.dart';

class ControllerBoaScreen extends StatefulWidget {
  final String roomCode;
  final String playerName;

  const ControllerBoaScreen({
    super.key,
    required this.roomCode,
    required this.playerName,
  });

  @override
  State<ControllerBoaScreen> createState() => _ControllerBoaScreenState();
}

class _ControllerBoaScreenState extends State<ControllerBoaScreen> with TickerProviderStateMixin {
  String _status = 'waiting';
  String? _activePlayer;
  Map<String, dynamic>? _mysterySong;
  List<Map<String, dynamic>> _timelineSongs = [];
  String? _placementResult; // 'correct', 'wrong', or null
  bool _isWaitingForReady = false;
  String? _winner;

  late StreamSubscription _firebaseSubscription;
  late PageController _pageController;
  int _currentSlotIndex = 0;

  // For result overlays
  late AnimationController _resultAnimController;
  late Animation<double> _resultScale;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _resultAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _resultScale = CurvedAnimation(
      parent: _resultAnimController,
      curve: Curves.elasticOut,
    );

    _firebaseSubscription = FirebaseService().listenToRoomCustom(widget.roomCode).listen((data) {
      if (!mounted) return;
      if (data.isEmpty) return;

      final oldMysteryTitle = _mysterySong?['title'];

      setState(() {
        _status = data['status'] ?? 'waiting';
        _activePlayer = data['activePlayer'];
        _isWaitingForReady = data['isWaitingForReady'] == true;
        _placementResult = data['placementResult'];
        _winner = data['winner'];

        // Mystery Song mapping
        if (data['mysterySong'] != null) {
          _mysterySong = Map<String, dynamic>.from(data['mysterySong'] as Map);
        } else {
          _mysterySong = null;
        }

        // Timeline Songs mapping
        if (data['timelineSongs'] != null) {
          final rawTimeline = data['timelineSongs'] as List;
          _timelineSongs = rawTimeline.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        } else {
          _timelineSongs = [];
        }
      });

      // Reset PageView when a new mystery song appears
      final newMysteryTitle = _mysterySong?['title'];
      if (newMysteryTitle != null && newMysteryTitle != oldMysteryTitle) {
        _currentSlotIndex = 0;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      }

      // Handle placement result animations
      if (_placementResult != null) {
        _resultAnimController.forward();
      } else {
        _resultAnimController.reset();
      }
    });
  }

  @override
  void dispose() {
    _firebaseSubscription.cancel();
    _pageController.dispose();
    _resultAnimController.dispose();
    super.dispose();
  }

  void _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('roomCode');
    await prefs.remove('playerName');
    await prefs.remove('teamName');
  }

  void _submitChoice(int slotIndex) async {
    await FirebaseService().submitBoaChoice(widget.roomCode, slotIndex, widget.playerName);
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
              const Icon(Icons.gavel, color: Colors.redAccent, size: 80),
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

    if (_status == 'game_over' || _status == 'gameover') {
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

    final bool isMyTurn = _activePlayer == widget.playerName;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                _buildHeader(isMyTurn),

                // Body
                Expanded(
                  child: _buildBody(isMyTurn),
                ),
              ],
            ),

            // Results are integrated inline in _buildBody
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMyTurn) {
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
                  color: isMyTurn ? Colors.green[50] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isMyTurn ? Colors.green : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Text(
                  isMyTurn ? 'YOUR TURN' : 'WAITING',
                  style: GoogleFonts.outfit(
                    color: isMyTurn ? Colors.green[800] : Colors.grey[600],
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

  Widget _buildBody(bool isMyTurn) {
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
              'Wait for host to start the timeline...',
              style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (!isMyTurn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.purple.withOpacity(0.2), width: 2),
                ),
                child: const Icon(
                  Icons.audiotrack,
                  color: Colors.purple,
                  size: 60,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                '${_activePlayer ?? "Someone"}\'s Turn',
                style: GoogleFonts.outfit(
                  color: Colors.black87,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Watch the host screen to see their timeline placement!',
                style: GoogleFonts.outfit(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_isWaitingForReady) {
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
                  Icons.play_arrow,
                  color: Colors.green,
                  size: 60,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "It's Your Turn!",
                style: GoogleFonts.outfit(
                  color: Colors.black87,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Are you ready? Tap 'START NOW' to reveal your mystery song and timeline.",
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
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    FirebaseService().requestStartTurn(widget.roomCode);
                  },
                  child: Text(
                    "START NOW",
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

    if (_mysterySong == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.teal),
      );
    }

    // Slidable Gaps Carousel
    return Column(
      children: [
        _buildResultBanner(),
        Expanded(
          child: _buildTimelineCarousel(),
        ),

        const SizedBox(height: 20),

        // 3. Drop action button
        _buildDropButton(),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildMysterySongSection() {
    final artworkUrl = _mysterySong?['artworkUrl'] as String?;
    final title = _mysterySong?['title'] ?? 'Mystery Song';
    final artist = _mysterySong?['artist'] ?? 'Unknown Artist';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.tealAccent.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.tealAccent.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: artworkUrl != null && artworkUrl.isNotEmpty
                ? Image.network(
                    artworkUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey[800],
                      child: const Icon(Icons.music_note, color: Colors.white),
                    ),
                  )
                : Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey[800],
                    child: const Icon(Icons.music_note, color: Colors.white),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Guesser Card',
                  style: GoogleFonts.outfit(
                    color: Colors.tealAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  artist,
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 14,
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

  Widget _buildTimelineCarousel() {
    final int slotsCount = _timelineSongs.length + 1;

    return PageView.builder(
      controller: _pageController,
      itemCount: slotsCount,
      onPageChanged: (index) {
        debugPrint("Controller PageChanged to: $index");
        setState(() {
          _currentSlotIndex = index;
        });
        FirebaseService().updateBoaScrollPosition(widget.roomCode, index);
      },
      itemBuilder: (context, index) {
        // We'll calculate the relative difference from the center page
        // to apply beautiful visual scales and opacity.
        return AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            double value = 1.0;
            if (_pageController.position.haveDimensions) {
              value = _pageController.page! - index;
              value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
            } else {
              // Fallback during initialization
              value = index == 0 ? 1.0 : 0.7;
            }

            return Opacity(
              opacity: value,
              child: Transform.scale(
                scale: value,
                child: child,
              ),
            );
          },
          child: _buildSlotView(index),
        );
      },
    );
  }

  Widget _buildSlotView(int slotIndex) {
    // A slot displays neighbors.
    // Left Neighbor (if slotIndex > 0)
    final bool hasLeft = slotIndex > 0;
    final leftSong = hasLeft ? _timelineSongs[slotIndex - 1] : null;

    // Right Neighbor (if slotIndex < _timelineSongs.length)
    final bool hasRight = slotIndex < _timelineSongs.length;
    final rightSong = hasRight ? _timelineSongs[slotIndex] : null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Left Card Stack / Fading representation
              Expanded(
                child: hasLeft
                    ? _buildTimelineCard(leftSong!, isLeft: true)
                    : _buildEmptyTimelineBoundary(isLeft: true),
              ),

              // Drop-zone Visual Placeholder
              Container(
                width: 50,
                height: 200,
                margin: const EdgeInsets.only(top: 36, left: 10, right: 10),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.teal.withOpacity(0.3),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.arrow_downward,
                    color: Colors.teal,
                    size: 24,
                  ),
                ),
              ),

              // Right Card Stack / Fading representation
              Expanded(
                child: hasRight
                    ? _buildTimelineCard(rightSong!, isLeft: false)
                    : _buildEmptyTimelineBoundary(isLeft: false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(Map<String, dynamic> song, {required bool isLeft}) {
    final artworkUrl = song['artworkUrl'] as String?;
    final title = song['title'] ?? 'Title';
    final year = song['year']?.toString() ?? '????';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Year text above the card
        Text(
          year,
          style: GoogleFonts.outfit(
            color: Colors.teal[800],
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Artwork
                artworkUrl != null && artworkUrl.isNotEmpty
                    ? Image.network(
                        artworkUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(color: Colors.grey[900]),
                      )
                    : Container(color: Colors.grey[900]),

                // Semi-transparent overlay
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                ),

                // Metadata
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTimelineBoundary({required bool isLeft}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Empty placeholder year to align heights
        Text(
          "",
          style: GoogleFonts.outfit(fontSize: 22),
        ),
        const SizedBox(height: 10),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey[300]!,
              style: BorderStyle.solid,
            ),
          ),
          child: Center(
            child: Text(
              isLeft ? 'START' : 'END',
              style: GoogleFonts.outfit(
                color: Colors.grey[400],
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropButton() {
    final bool isShowingResult = _placementResult != null;

    if (isShowingResult) {
      final isCorrect = _placementResult == 'correct';
      final buttonColor = isCorrect ? Colors.green[700]! : Colors.red[700]!;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: buttonColor.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            onPressed: () {
              FirebaseService().requestNextRound(widget.roomCode);
            },
            child: Text(
              "CONTINUE",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      );
    }

    final int slotsCount = _timelineSongs.length + 1;
    String buttonText = "PLACE BETWEEN";
    Color buttonColor = Colors.teal;

    if (_currentSlotIndex == 0) {
      buttonText = "PLACE BEFORE";
      buttonColor = Colors.purple;
    } else if (_currentSlotIndex == slotsCount - 1) {
      buttonText = "PLACE AFTER";
      buttonColor = Colors.indigo;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: buttonColor.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 0,
          ),
          onPressed: () => _submitChoice(_currentSlotIndex),
          child: Text(
            buttonText,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultBanner() {
    if (_placementResult == null) return const SizedBox.shrink();

    final isCorrect = _placementResult == 'correct';
    final bannerColor = isCorrect ? Colors.green[50] : Colors.red[50];
    final borderColor = isCorrect ? Colors.green[300]! : Colors.red[300]!;
    final textColor = isCorrect ? Colors.green[800]! : Colors.red[800]!;
    final icon = isCorrect ? Icons.check_circle_outline : Icons.error_outline;
    final text = isCorrect ? "CORRECT!" : "WRONG!";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: 28),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.outfit(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
