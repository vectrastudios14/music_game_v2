import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:math';

import '../../models/song.dart';
import '../../services/song_repository.dart';
import '../../services/itunes_service.dart';
import '../../services/audio_cache_service.dart';
import '../gts/result_screen.dart'; // Reuse result screen if possible or make a new one
import 'widgets/circular_year_node.dart';

class TsGameScreen extends StatefulWidget {
  final List<String> playerNames;
  final Map<String, Color> playerColors;
  final int startingPoints; // New parameter

  const TsGameScreen({
    super.key,
    required this.playerNames,
    this.playerColors = const {},
    this.startingPoints = 100, // Default to 100
  });

  @override
  State<TsGameScreen> createState() => _TsGameScreenState();
}

class _TsGameScreenState extends State<TsGameScreen> with SingleTickerProviderStateMixin {
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

  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isSongCardHovered = false;
  
  // Services
  late final SongRepository _repository;
  
  // Grid
  final int _startYear = 1970;
  final int _endYear = 2025;

  // Animation
  late AnimationController _borderController;

  @override
  void initState() {
    super.initState();
    _playMusicBackground();
    _initializeGame();
    _borderController = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 8),
    )..repeat();
  }
  

  void _playMusicBackground() {
     // Optional: Ambient background?
  }

  Future<void> _initializeGame() async {
    _repository = SongRepository();
    MediaCacheService().init();

    // Init scores
    for (var name in widget.playerNames) {
      _playerScores[name] = widget.startingPoints;
    }

    // Load songs if needed
    if (_repository.allSongs.isEmpty) {
      await _repository.loadSongs();
    }
    _deck = _repository.getValidSongs()..shuffle();

    if (mounted) {
      _startNewRound();
    }
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _borderController.dispose();
    super.dispose();
  }

  void _startNewRound() async {
    if (_deck.isEmpty) {
      // Handle deck empty
      return;
    }

    setState(() {
      _currentSong = _deck.removeLast();
      _platformGuesses.clear();
      _currentGuesserIndex = 0;
      _isRoundActive = true;
      _isRoundResultShowing = false;
      _isPlaying = false;
      _roundLoserName = null;
    });

    // Fetch artwork
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
      await _audioPlayer.setReleaseMode(ReleaseMode.loop); // Enable Loop
      
      String playUrl = _currentSong!.link;
      final cachedPath = MediaCacheService().getCachedPath(_currentSong!.link);
      if (cachedPath != null) {
        playUrl = cachedPath;
      }
      
      await _audioPlayer.play(DeviceFileSource(playUrl).runtimeType == DeviceFileSource ? DeviceFileSource(playUrl) : UrlSource(playUrl));
      setState(() => _isPlaying = true);
    } catch (e) {
      debugPrint("Error playing song: $e");
    }
  }

  void _handleYearSelection(int year) {
    if (!_isRoundActive || _isRoundResultShowing) return;

    final currentPlayerName = widget.playerNames[_currentGuesserIndex];
    
    setState(() {
      _platformGuesses[currentPlayerName] = year;
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
    _audioPlayer.stop(); // Stop music when revealed
    setState(() {
      _isRoundActive = false;
      _isRoundResultShowing = true;
    });
    
    // Calculate damages and apply asynchronously for effect? 
    // For now, apply immediately but show animation in UI
    bool someoneDied = false;
    final actualYear = int.tryParse(_currentSong!.year) ?? 0;
    
    int maxLoss = -1;
    String? maxLoser;

    _platformGuesses.forEach((player, guess) {
      int diff = (guess - actualYear).abs();
      if (diff > maxLoss) {
        maxLoss = diff;
        maxLoser = player;
      }
      
      
      // Fix: Clamp only lower bound to 0, or clamp to startingPoints if we supported healing (we don't).
      // But definitely do NOT clamp to 100 if startingPoints > 100.
      int newScore = _playerScores[player]! - diff;
      _playerScores[player] = max(0, newScore); // Ensure it doesn't drop below 0
      
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
     // Navigate to results
     // Reuse GtsResultScreen? Or just a simple dialog/screen?
     // Mapping scores to simple "Rounds Won" isn't quite right, but we can pass 'score' as value.
     Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (_) => GtsResultScreen(
        scores: _playerScores, 
        totalRounds: widget.startingPoints, // Pass actual starting points
        isLightMode: false,
      ))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 140), // Placeholder for Header
                // 4. Year Grid (Takes remaining space)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(5), // Space for the inner glow/border
                    decoration: BoxDecoration(
                      color: Colors.white, // White board background
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE0E0E0), width: 8), // Lighter outer frame
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 20, offset: const Offset(0, 10)),
                        // Cyber Glow around the board
                        BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.2), blurRadius: 30, spreadRadius: -5), 
                      ],
                    ),
                    child: Container(
                      // Inner inset effect
                      decoration: BoxDecoration(
                         color: Colors.white, // White grid background
                         borderRadius: BorderRadius.circular(16),
                         border: Border.all(color: Colors.black.withOpacity(0.05), width: 1),
                      ),
                      child: CustomPaint(
                        painter: const RealisticBoardPainter(),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                          // 1970 to 2025 = 56 items => 8 columns x 7 rows
                          // Padding: 16 all around inside the frame
                          
                          final int columns = 8;
                          final int rows = 7;
                          
                          final double horizontalPadding = 32.0; 
                          final double verticalPadding = 32.0; 
                          final double totalCrossAxisSpacing = 8.0 * (columns - 1);
                          final double totalMainAxisSpacing = 8.0 * (rows - 1); 
                          
                          final double availableWidth = constraints.maxWidth - horizontalPadding - totalCrossAxisSpacing;
                          final double availableHeight = constraints.maxHeight - verticalPadding - totalMainAxisSpacing;
                          
                          final double itemWidth = availableWidth / columns;
                          final double itemHeight = availableHeight / rows;
                          
                          // Ensure we don't divide by zero or have negative dimensions
                          final double aspectRatio = (itemHeight > 0 && itemWidth > 0) 
                              ? itemWidth / itemHeight 
                              : 1.0;
          
                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            physics: const NeverScrollableScrollPhysics(), 
                            itemCount: 56,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: aspectRatio,
                            ),
                            itemBuilder: (context, index) {
                              final int year = _startYear + index;
                              return _buildYearButton(year);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
                ),
              ],
            ),
            
            // 1. Unified Header Section (Image Left, Title+Players Right)
            Positioned(
              top: 0, left: 0, right: 0,
              height: 140,
              child: Container(
              height: 140, // Fixed height for the header area
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                   // Left: Title + Players
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          // Row 1: Title + Action Button
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white70),
                                onPressed: () => Navigator.of(context).pop(),
                                tooltip: 'Exit Game',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 12),
                              const Text("Time Survival",
                                 style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                              ),
                              const Spacer(),
                              if (_isRoundResultShowing)
                                 ElevatedButton(
                                    onPressed: _isGameOver ? _finishGame : _startNewRound,
                                    style: ElevatedButton.styleFrom(
                                       backgroundColor: _isGameOver ? Colors.red : const Color(0xFF6C63FF),
                                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                       minimumSize: Size.zero, 
                                       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      _isGameOver ? "RANKING" : "NEXT ROUND",
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                                    ),
                                 ),
                            ],
                          ),
                          
                          const Spacer(),
                          
                          // Row 2: Player List (Scrollable)
                          SizedBox(
                             height: 85,
                             child: LayoutBuilder(
                               builder: (context, constraints) {
                                 // Dynamic width calculation
                                 double availableWidth = constraints.maxWidth;
                                 double itemSpacing = 8.0; // Margin right
                                 int count = widget.playerNames.length;
                                 
                                 // Calculate width per item: (Total - TotalSpacing) / Count
                                 // But we want a max width of 100
                                 double dynamicWidth = (availableWidth - (count * itemSpacing)) / count;
                                 
                                 // Clamp spacing for usability
                                 // Min width 60, Max width 100.
                                 // If it goes below 60, we might strictly need scrolling, or just shrink more.
                                 // User asked to "solve this by reducing the width", implies shrinking to fit.
                                 // So let's clamp min to 40 maybe? And handle text scaling.
                                 
                                 double cardWidth = dynamicWidth.clamp(40.0, 100.0);
                                 
                                 return ListView(
                                   scrollDirection: Axis.horizontal,
                                   children: widget.playerNames.map((name) {
                                     final isCurrentTurn = !_isRoundResultShowing && widget.playerNames[_currentGuesserIndex] == name;
                                     final score = _playerScores[name] ?? 100;
                                     final playerColor = widget.playerColors[name] ?? Colors.grey;
                                     
                                     Widget cardContent = Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                             FittedBox(
                                               fit: BoxFit.scaleDown,
                                               child: Text(name, 
                                                 textAlign: TextAlign.center,
                                                 maxLines: 1,
                                                 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)
                                               ),
                                             ),
                                             const SizedBox(height: 2),
                                             FittedBox(
                                               fit: BoxFit.scaleDown,
                                               child: Text("$score", style: TextStyle( 
                                                 color: score < 30 ? Colors.redAccent : Colors.greenAccent, 
                                                 fontSize: 14, 
                                                 fontWeight: FontWeight.w900
                                               )),
                                             ),
                                             const SizedBox(height: 2),
                                             Icon(Icons.person, color: playerColor, size: 16),
                                          ],
                                        );

                                     Widget finalCard = Padding(
                                       padding: EdgeInsets.only(right: itemSpacing),
                                       child: AnimatedContainer(
                                         duration: const Duration(milliseconds: 300),
                                         padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6), 
                                         width: cardWidth, 
                                         decoration: BoxDecoration(
                                           color: playerColor.withOpacity(0.3), // Background matches pawn color
                                           borderRadius: BorderRadius.circular(12),
                                           border: isCurrentTurn ? null : Border.all(color: Colors.white10),
                                         ),
                                         child: isCurrentTurn 
                                          ? CustomPaint(
                                              foregroundPainter: VegasBorderPainter(animation: _borderController),
                                              child: cardContent,
                                            )
                                          : cardContent,
                                       ),
                                     );

                                     if (_isRoundResultShowing && name == _roundLoserName) {
                                       return Stack(
                                         clipBehavior: Clip.none,
                                         alignment: Alignment.center,
                                         children: [
                                           finalCard,
                                           Positioned(
                                             top: -10,
                                             child: FadeInDown(
                                                duration: const Duration(milliseconds: 500),
                                                child: const _LoopingArrow(),
                                             ),
                                           ),
                                         ],
                                       );
                                     }
                                     
                                     return finalCard;
                                   }).toList(),
                                 );
                               }
                             ),
                           ),
                       ],
                     ),
                   ),

                   const SizedBox(width: 12),

                   // Right: Song Image
                   _buildSongDisplay(),
                ],
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongDisplay() {
    final actualYear = int.tryParse(_currentSong!.year) ?? 0;
    
    return Center( // Center within the allocated space
      child: MouseRegion(
        onEnter: (_) => setState(() => _isSongCardHovered = true),
        onExit: (_) => setState(() => _isSongCardHovered = false),
        cursor: SystemMouseCursors.zoomIn,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          transform: _isSongCardHovered 
              ? (Matrix4.identity()..translate(12.0, -12.0)..scale(1.5))
              : Matrix4.identity(),
          transformAlignment: Alignment.topRight,
          child: Container(
        width: 110, 
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[800],
          image: _currentSong!.artworkUrl != null 
              ? DecorationImage(image: NetworkImage(_currentSong!.artworkUrl!), fit: BoxFit.cover)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 1,
            )
          ]
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
             if (_currentSong!.artworkUrl == null)
               const Center(child: Icon(Icons.music_note, size: 40, color: Colors.white54)),
             
             // Text Overlay (Title/Artist)
             Align(
               alignment: Alignment.bottomCenter,
               child: Container(
                 width: double.infinity,
                 padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                 color: Colors.white.withOpacity(0.9),
                 child: Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Text(
                       _currentSong!.title,
                       style: GoogleFonts.outfit(
                         color: Colors.black, 
                         fontWeight: FontWeight.bold, 
                         fontSize: 10
                       ),
                       textAlign: TextAlign.center,
                       maxLines: 1, 
                       overflow: TextOverflow.ellipsis,
                     ),
                     Text(
                       _currentSong!.artist,
                       style: GoogleFonts.outfit(
                         color: Colors.black87, 
                         fontSize: 8
                       ),
                       textAlign: TextAlign.center,
                       maxLines: 1, 
                       overflow: TextOverflow.ellipsis,
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

  Color _getEraBaseColor(int year) {
    if (year < 1980) return const Color(0xFFFF9100); // 70s: Deep Orange
    if (year < 1990) return const Color(0xFFD500F9); // 80s: Neon Purple
    if (year < 2000) return const Color(0xFF00E5FF); // 90s: Cyber Cyan
    if (year < 2010) return const Color(0xFF2979FF); // 00s: Royal Blue
    if (year < 2020) return const Color(0xFF00E676); // 10s: Neon Green
    return const Color(0xFFFF1744);                  // 20s+: Red Accent
  }

  Widget _buildYearButton(int year) {
    // Identify who guessed this year and get their colors
    List<Color> nodePlayerColors = [];
    for (var player in widget.playerNames) {
       if (_platformGuesses[player] == year) {
          nodePlayerColors.add(widget.playerColors[player] ?? Colors.grey);
       }
    }
    
    // Determine State
    bool isCorrect = false;
    bool isWrong = false;
    
    if (_isRoundResultShowing) {
       final actualYear = int.tryParse(_currentSong!.year) ?? 0;
       if (year == actualYear) {
         isCorrect = true;
       } else if (nodePlayerColors.isNotEmpty) {
         isWrong = true;
       }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate max size that fits in the cell (square)
        final double size = min(constraints.maxWidth, constraints.maxHeight);
        
        return Center(
          child: CircularYearNode(
            year: year,
            playerColors: nodePlayerColors,
            baseColor: _getEraBaseColor(year),
            size: size - 4, // Padding
            isCorrect: isCorrect,
            isWrong: isWrong,
            onTap: () => _handleYearSelection(year),
          ),
        );
      }
    );
  }
}

class RealisticBoardPainter extends CustomPainter {
  const RealisticBoardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Base Layer (Subtle warm off-white)
    final rect = Offset.zero & size;
    final basePaint = Paint()..color = const Color(0xFFFAFAFA);
    canvas.drawRect(rect, basePaint);

    // 2. Grain/Noise Texture
    // We use a fixed seed for consistency so it doesn't shimmer on rebuilds
    final random = Random(12345); 
    final noisePaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 1.0;

    // Draw thousands of tiny specks
    // Performance NOTE: For a static board, this is okay. If it animates, use a Picture or Shader.
    // Reducing density for performance safety.
    const int density = 2000; 
    
    for (int i = 0; i < density; i++) {
        final dx = random.nextDouble() * size.width;
        final dy = random.nextDouble() * size.height;
        final opacity = random.nextDouble() * 0.05 + 0.01; // 0.01 to 0.06
        
        noisePaint.color = Colors.black.withOpacity(opacity);
        // Draw tiny rects or points
        canvas.drawRect(Rect.fromLTWH(dx, dy, 1 + random.nextDouble(), 1 + random.nextDouble()), noisePaint);
    }

    // 3. Vignette (Subtle shadow at corners to give depth)
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [
        Colors.transparent,
        Colors.black.withOpacity(0.05), // Very subtle vignette
        Colors.black.withOpacity(0.15),
      ],
      stops: const [0.6, 0.9, 1.0],
    );
    
    final vignettePaint = Paint()
      ..shader = gradient.createShader(rect)
      ..blendMode = BlendMode.darken;

    canvas.drawRect(rect, vignettePaint);
    
    // 4. Subtle Scratch/Paper fibers (Optional detailed imperfections)
    final fiberPaint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
      
    for(int i = 0; i < 20; i++) {
       final x = random.nextDouble() * size.width;
       final y = random.nextDouble() * size.height;
       final len = random.nextDouble() * 20 + 5;
       final angle = random.nextDouble() * 3.14 * 2;
       
       canvas.drawLine(
         Offset(x, y), 
         Offset(x + cos(angle)*len, y + sin(angle)*len), 
         fiberPaint
       );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class VegasBorderPainter extends CustomPainter {
  final Animation<double> animation;
  VegasBorderPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    
    final Path path = Path()..addRRect(rrect);
    
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final pathMetrics = path.computeMetrics();
    
    for (final pathMetric in pathMetrics) {
      double totalLength = pathMetric.length;
      double dashLength = 8.0;
      double gapLength = 6.0;
      
      double currentDist = -(animation.value * totalLength) % (dashLength + gapLength);
      
      while (currentDist < totalLength) {
         if (currentDist >= 0) {
           final extract = pathMetric.extractPath(currentDist, currentDist + dashLength);
           
           // Vegas Lights: Alternating Gold and White
           // Determine "light index"
           int lightIndex = (currentDist / (dashLength + gapLength)).floor();
           bool isGold = lightIndex % 2 == 0;
           
           paint.color = isGold ? const Color(0xFFFFD700) : Colors.white;
           
           // Glow effect for lights
           if (isGold) {
             paint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
           } else {
             paint.maskFilter = null;
           }

           canvas.drawPath(extract, paint);
         }
         currentDist += (dashLength + gapLength);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LoopingArrow extends StatefulWidget {
  const _LoopingArrow();

  @override
  State<_LoopingArrow> createState() => _LoopingArrowState();
}

class _LoopingArrowState extends State<_LoopingArrow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
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
        return Transform.translate(
          offset: Offset(0, 5 * _controller.value), // Move down 5 pixels
          child: child,
        );
      },
      child: const Icon(
        Icons.keyboard_double_arrow_down_rounded,
        color: Colors.redAccent,
        size: 32,
        shadows: [BoxShadow(color: Colors.black, blurRadius: 4)],
      ),
    );
  }
}
