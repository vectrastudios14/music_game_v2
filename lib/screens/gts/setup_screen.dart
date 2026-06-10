import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/song_repository.dart';
import 'game_screen.dart';
import 'help_screen.dart';
import '../../services/background_music_service.dart';
import '../../services/firebase_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

class DesktopScrollBehavior extends MaterialScrollBehavior {
  const DesktopScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class GtsSetupScreen extends StatefulWidget {
  const GtsSetupScreen({super.key});

  @override
  State<GtsSetupScreen> createState() => _GtsSetupScreenState();
}

class _GtsSetupScreenState extends State<GtsSetupScreen> {
  int _rounds = 10;
  int _playerCount = 2;
  bool _isHardMode = true; // Default to Hard (Artist only)
  String _libraryType = SongRepository().currentLibraryType;
  String _uiLanguage = 'en'; // 'en' or 'ar'
  bool _isTeamMode = false;
  bool _isMobileControlEnabled = false;
  bool _isQrZoomed = false;
  String? _roomCode;
  final List<TextEditingController> _nameControllers = [];
  
  int _teamCount = 2;
  
  // Interactive Team Setup State
  final List<String> _playerPool = [];
  final List<String> _team1Members = [];
  final List<String> _team2Members = [];
  final List<String> _team3Members = [];
  final List<String> _team4Members = [];
  final TextEditingController _playerInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateControllers();
    _preloadGameAssets();
  }

  Future<void> _preloadGameAssets() async {
    await SongRepository().loadSongs();
    await SongRepository().prepareFirstRoundGTS(
      isHardMode: _isHardMode,
      distractorCount: _isTeamMode ? 5 : 3,
    );
  }

  void _updateControllers() {
    final count = _isTeamMode ? _teamCount : _playerCount;
    final isAr = _uiLanguage == 'ar';
    
    // Adjust list size
    while (_nameControllers.length < count) {
      _nameControllers.add(TextEditingController());
    }
    while (_nameControllers.length > count) {
      _nameControllers.last.dispose();
      _nameControllers.removeLast();
    }

    // Set or update default texts if they are currently default values or empty
    for (int i = 0; i < _nameControllers.length; i++) {
      final currentText = _nameControllers[i].text.trim();
      final defaultPlayerEn = 'Player ${i + 1}';
      final defaultPlayerAr = 'اللاعب ${i + 1}';
      final defaultTeamEn = 'Team ${i + 1}';
      final defaultTeamAr = 'الفريق ${i + 1}';

      final isDefaultValue = currentText.isEmpty ||
          currentText == defaultPlayerEn ||
          currentText == defaultPlayerAr ||
          currentText == defaultTeamEn ||
          currentText == defaultTeamAr;

      if (isDefaultValue) {
        if (_isTeamMode) {
          _nameControllers[i].text = isAr ? 'الفريق ${i + 1}' : 'Team ${i + 1}';
        } else {
          _nameControllers[i].text = isAr ? 'اللاعب ${i + 1}' : 'Player ${i + 1}';
        }
      }
    }
  }

  @override
  void dispose() {
    FirebaseService().stopListeningForJoins();
    for (var controller in _nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _uiLanguage == 'ar';
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: null,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: [
            if (!kIsWeb)
              IconButton(
                onPressed: () async {
                  final isFull = await windowManager.isFullScreen();
                  await windowManager.setFullScreen(!isFull);
                  setState(() {});
                },
                icon: FutureBuilder<bool>(
                  future: windowManager.isFullScreen(),
                  builder: (context, snapshot) {
                    final isFull = snapshot.data ?? false;
                    return Icon(
                      isFull ? Icons.fullscreen_exit : Icons.fullscreen,
                      color: Colors.white70,
                      size: 24,
                    );
                  },
                ),
                tooltip: isAr ? "ملء الشاشة" : "Toggle Fullscreen",
              ),
            // UI Language Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton.icon(
                onPressed: () => setState(() {
                  _uiLanguage = isAr ? 'en' : 'ar';
                  _updateControllers();
                }),
                icon: const Icon(Icons.language, color: Colors.white70, size: 20),
                label: Text(
                  isAr ? "English" : "عربي",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ScrollConfiguration(
                behavior: const DesktopScrollBehavior().copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                  // 1. Logo
                  FadeInDown(
                    child: Image.asset(
                      'assets/Guess_that_song_logo.png',
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),
  
                  // 2. Rounds, Mode & Library
                  FadeInDown(
                    delay: const Duration(milliseconds: 100),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Rounds Slider
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(isAr ? 'الجولات: $_rounds' : 'Rounds: $_rounds', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white70)),
                                  Expanded(
                                    child: Slider(
                                      value: _rounds.toDouble(),
                                      min: 10, max: 20, divisions: 10,
                                      label: _rounds.toString(),
                                      onChanged: (v) => setState(() => _rounds = v.round()),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(width: 20),
                  
                            // Mode Toggle
                            Column(
                              crossAxisAlignment: isAr ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isAr ? 'الوضع: ' : 'Mode: ', 
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white70)
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      height: 30, 
                                      child: Switch(
                                        value: _isHardMode, 
                                        activeColor: Theme.of(context).primaryColor,
                                        onChanged: (v) => setState(() => _isHardMode = v),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  isAr ? (_isHardMode ? 'فنان فقط' : 'فنان + أغنية') : (_isHardMode ? 'Artist Only' : 'Artist + Song'), 
                                  style: const TextStyle(fontSize: 12, color: Colors.grey)
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Library Toggle
                            Column(
                              children: [
                                Text(
                                  isAr ? 'المكتبة' : 'Library', 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70)
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    ChoiceChip(
                                      label: Text(isAr ? 'الإنجليزية' : 'English', style: const TextStyle(fontSize: 12)),
                                      selected: _libraryType == 'english',
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() => _libraryType = 'english');
                                          SongRepository().setLibrary('english');
                                          _preloadGameAssets();
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 6),
                                    ChoiceChip(
                                      label: Text(isAr ? 'العربية' : 'Arabic', style: const TextStyle(fontSize: 12)),
                                      selected: _libraryType == 'arabic',
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() => _libraryType = 'arabic');
                                          SongRepository().setLibrary('arabic');
                                          _preloadGameAssets();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // 2. Game Type Toggle
                            Column(
                              children: [
                                Text(
                                  isAr ? 'نوع اللعبة' : 'Game Type', 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70)
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    ChoiceChip(
                                      label: Text(isAr ? 'فردي' : 'Individual', style: const TextStyle(fontSize: 12)),
                                      selected: !_isTeamMode,
                                      onSelected: (selected) async { 
                                        if (selected) {
                                          setState(() {
                                            _isTeamMode = false;
                                            _playerPool.clear();
                                            _team1Members.clear();
                                            _team2Members.clear();
                                            if (_isMobileControlEnabled) {
                                              _playerCount = 0;
                                            }
                                          });
                                          if (_isMobileControlEnabled && _roomCode != null) {
                                            await FirebaseService().setRoomMode(_roomCode!, 'individual');
                                          }
                                          _updateControllers();
                                          _preloadGameAssets(); // RELOAD CACHE
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 6),
                                    ChoiceChip(
                                      label: Text(isAr ? 'فرق' : 'Teams', style: const TextStyle(fontSize: 12)),
                                      selected: _isTeamMode,
                                      onSelected: (selected) async { 
                                        if (selected) {
                                          setState(() {
                                            _isTeamMode = true;
                                            _playerPool.clear();
                                            _team1Members.clear();
                                            _team2Members.clear();
                                            _team3Members.clear();
                                            _team4Members.clear();
                                          });
                                          if (_isMobileControlEnabled && _roomCode != null) {
                                            await FirebaseService().setRoomMode(_roomCode!, 'team');
                                            final names = _nameControllers.take(_teamCount).map((c) => c.text).toList();
                                            await FirebaseService().updateTeamNames(_roomCode!, names);
                                          }
                                          _updateControllers();
                                          _preloadGameAssets(); // RELOAD CACHE
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // 3. Mobile Control Toggle
                            Column(
                              children: [
                                Text(
                                  isAr ? 'التحكم' : 'Mobile Control', 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70)
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 38,
                                  child: Switch(
                                    value: _isMobileControlEnabled,
                                    activeColor: Theme.of(context).primaryColor,
                                    onChanged: (val) async {
                                      setState(() {
                                        _isMobileControlEnabled = val;
                                      });
                                      if (val) {
                                        _roomCode = FirebaseService().generateRoomCode();
                                        await FirebaseService().createRoom(_roomCode!);
                                        
                                        if (_isTeamMode) {
                                          await FirebaseService().setRoomMode(_roomCode!, 'team');
                                          final names = _nameControllers.take(_teamCount).map((c) => c.text).toList();
                                          await FirebaseService().updateTeamNames(_roomCode!, names);
                                        } else {
                                          await FirebaseService().setRoomMode(_roomCode!, 'individual');
                                        }

                                        _playerPool.clear();
                                        _team1Members.clear();
                                        _team2Members.clear();
                                        _team3Members.clear();
                                        _team4Members.clear();

                                        FirebaseService().listenForJoins(_roomCode!, (name, team) {
                                          if (mounted) {
                                            setState(() {
                                              if (_isTeamMode) {
                                                if (team == 'team1' && !_team1Members.contains(name)) {
                                                  _team1Members.add(name);
                                                } else if (team == 'team2' && !_team2Members.contains(name)) {
                                                  _team2Members.add(name);
                                                } else if (team == 'team3' && !_team3Members.contains(name)) {
                                                  _team3Members.add(name);
                                                } else if (team == 'team4' && !_team4Members.contains(name)) {
                                                  _team4Members.add(name);
                                                }
                                              } else {
                                                if (!_playerPool.contains(name)) {
                                                  _playerPool.add(name);
                                                  _playerCount = _playerPool.length;
                                                  _updateControllers();
                                                  for (int i = 0; i < _playerPool.length; i++) {
                                                    _nameControllers[i].text = _playerPool[i];
                                                  }
                                                }
                                              }
                                            });
                                          }
                                        });
                                      } else {
                                        _roomCode = null;
                                        FirebaseService().stopListeningForJoins();
                                        _playerPool.clear();
                                        _team1Members.clear();
                                        _team2Members.clear();
                                        _team3Members.clear();
                                        _team4Members.clear();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (_isMobileControlEnabled && _roomCode != null) ...[
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.only(top: 10, bottom: 20),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isQrZoomed = !_isQrZoomed;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      width: _isQrZoomed ? 300 : 100,
                                      height: _isQrZoomed ? 300 : 100,
                                      child: QrImageView(
                                        data: 'https://vectrastudios14.github.io/music_game_v2/#/controller?room=$_roomCode',
                                        version: QrVersions.auto,
                                        backgroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isAr ? 'رمز الغرفة: $_roomCode' : 'Room Code: $_roomCode',
                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_isTeamMode) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(isAr ? 'عدد الفرق: ' : 'Teams: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                                ...[2, 3, 4].map((count) => Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: ChoiceChip(
                                    label: Text('$count'),
                                    selected: _teamCount == count,
                                    onSelected: (selected) async {
                                      if (selected) {
                                        setState(() {
                                          _teamCount = count;
                                        });
                                        _updateControllers();
                                        final names = _nameControllers.take(_teamCount).map((c) => c.text).toList();
                                        await FirebaseService().updateTeamNames(_roomCode!, names);
                                      }
                                    },
                                  ),
                                )).toList(),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ],
                    ),
                  ),
                  
                  // 3. Player Count (Only for Individual Mode without Mobile Control)
                  if (!_isTeamMode && !_isMobileControlEnabled)
                    FadeInDown(
                      delay: const Duration(milliseconds: 200),
                      child: Row(
                        children: [
                          Text(isAr ? 'اللاعبون: $_playerCount' : 'Players: $_playerCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white70)),
                          Expanded(
                            child: Slider(
                              value: _playerCount.toDouble(),
                              min: 1, max: 8, divisions: 7,
                              label: _playerCount.toString(),
                              onChanged: (v) => setState(() {
                                _playerCount = v.round();
                                _updateControllers();
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
  
                  // 4. Player/Team Names (Individual) or Team Setup Board (Teams)
                  _isTeamMode ? _buildTeamSetupBoard(isAr) : _buildIndividualSetup(isAr),
  
                  const SizedBox(height: 20),
  
                  // 5. Start Button
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 60,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_isMobileControlEnabled) {
                                  if (_isTeamMode) {
                                    bool anyEmpty = _team1Members.isEmpty || _team2Members.isEmpty ||
                                        (_teamCount >= 3 && _team3Members.isEmpty) ||
                                        (_teamCount >= 4 && _team4Members.isEmpty);
                                    if (anyEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          behavior: SnackBarBehavior.floating,
                                          margin: const EdgeInsets.only(bottom: 30, left: 30, right: 30),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          content: Text(
                                            isAr 
                                                ? 'يجب أن ينضم لاعب واحد على الأقل لكل فريق!' 
                                                : 'At least one player must join each team!',
                                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                      return;
                                    }
                                  } else {
                                    if (_playerPool.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          behavior: SnackBarBehavior.floating,
                                          margin: const EdgeInsets.only(bottom: 30, left: 30, right: 30),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          content: Text(
                                            isAr 
                                                ? 'يجب أن ينضم لاعب واحد على الأقل لبدء اللعبة!' 
                                                : 'At least one player must join to start the game!',
                                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                      return;
                                    }
                                  }
                                }

                                List<String> playerNames = _nameControllers
                                  .take(_isTeamMode ? _teamCount : _playerCount)
                                  .map((c) => c.text).toList();
                                BackgroundMusicService.instance.stopMenuMusic();
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GtsGameScreen(
                                      totalRounds: _rounds,
                                      playerNames: playerNames,
                                      isHardMode: _isHardMode,
                                      isTeamMode: _isTeamMode,
                                      uiLanguage: _uiLanguage,
                                      roomCode: _isMobileControlEnabled ? _roomCode : null, // PASS ROOM CODE
                                      teamMembers: _isTeamMode ? {
                                        playerNames[0]: _team1Members,
                                        playerNames[1]: _team2Members,
                                        if (_teamCount >= 3) playerNames[2]: _team3Members,
                                        if (_teamCount >= 4) playerNames[3]: _team4Members,
                                      } : null,
                                    ),
                                  ),
                                );
                                BackgroundMusicService.instance.playMenuMusic();
                              },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                elevation: 5,
                              ),
                              child: Text(isAr ? 'ابدأ اللعبة' : 'START GAME', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 100,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => GtsHelpScreen(initialIsArabic: _uiLanguage == 'ar')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.1),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: Text(isAr ? 'مساعدة' : "Help", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ],
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
  Widget _buildIndividualSetup(bool isAr) {
    if (_isMobileControlEnabled) {
      return Center(
        child: FadeInUp(
          delay: const Duration(milliseconds: 300),
          child: Column(
            children: [
              Text(
                isAr ? 'اللاعبون المنضمون' : 'Joined Players',
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (_playerPool.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    isAr ? 'في انتظار انضمام اللاعبين...' : 'Waiting for players to join...',
                    style: GoogleFonts.outfit(
                      color: Colors.white30,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: _playerPool.map((player) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            player,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _playerPool.remove(player);
                                _playerCount = _playerPool.length;
                                _updateControllers();
                                for (int i = 0; i < _playerPool.length; i++) {
                                  _nameControllers[i].text = _playerPool[i];
                                }
                              });
                            },
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      );
    }

    _updateControllers();
    return Center(
      child: FadeInUp(
        delay: const Duration(milliseconds: 300),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: List.generate(_nameControllers.length, (index) {
              final label = isAr ? 'اللاعب ${index + 1}' : 'Player ${index + 1}';
              return SizedBox(
                width: 160,
                child: TextField(
                  controller: _nameControllers[index],
                  onTap: () => _nameControllers[index].clear(),
                  decoration: InputDecoration(
                    labelText: label,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Theme.of(context).cardTheme.color,
                  ),
                ),
              );
          }),
        ),
      ),
    );
  }

  Widget _buildTeamSetupBoard(bool isAr) {
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: Column(
        children: [
          // Player Input Field
          if (!_isMobileControlEnabled) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _playerInputController,
                    decoration: InputDecoration(
                      hintText: isAr ? 'اسم اللاعب...' : 'Enter player name...',
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onSubmitted: (_) => _addPlayer(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addPlayer,
                  icon: const Icon(Icons.add),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _autoShuffle,
                  icon: const Icon(Icons.shuffle),
                  tooltip: isAr ? 'توزيع تلقائي' : 'Auto Shuffle',
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Player Pool
            if (_playerPool.isNotEmpty) ...[
              Text(isAr ? 'اللاعبون غير الموزعين' : 'Unassigned Players', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _playerPool.map((p) => _buildDraggablePlayerChip(p, 'pool')).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ],
          // Teams Board
          if (!_isMobileControlEnabled)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildTeamDropZone(isAr ? 'الفريق 1' : 'Team 1', _team1Members, 'team1', Colors.cyan, 0)),
                const SizedBox(width: 16),
                Expanded(child: _buildTeamDropZone(isAr ? 'الفريق 2' : 'Team 2', _team2Members, 'team2', Colors.pinkAccent, 1)),
              ],
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                SizedBox(
                  width: 360,
                  child: _buildTeamDropZone(isAr ? 'الفريق 1' : 'Team 1', _team1Members, 'team1', Colors.cyan, 0),
                ),
                SizedBox(
                  width: 360,
                  child: _buildTeamDropZone(isAr ? 'الفريق 2' : 'Team 2', _team2Members, 'team2', Colors.pinkAccent, 1),
                ),
                if (_teamCount >= 3)
                  SizedBox(
                    width: 360,
                    child: _buildTeamDropZone(isAr ? 'الفريق 3' : 'Team 3', _team3Members, 'team3', Colors.amber, 2),
                  ),
                if (_teamCount >= 4)
                  SizedBox(
                    width: 360,
                    child: _buildTeamDropZone(isAr ? 'الفريق 4' : 'Team 4', _team4Members, 'team4', Colors.lightGreenAccent, 3),
                  ),
              ],
            ),
        ],
      ),
    );
  }



  Widget _buildDraggablePlayerChip(String name, String source) {
    return Draggable<Map<String, String>>(
      data: {'name': name, 'source': source},
      feedback: Material(
        color: Colors.transparent,
        child: Chip(
          label: Text(name, style: const TextStyle(color: Colors.white)),
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 10,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: Chip(label: Text(name)),
      ),
      child: Chip(
        label: Text(name),
        onDeleted: () {
          setState(() {
            if (source == 'pool') _playerPool.remove(name);
            else if (source == 'team1') _team1Members.remove(name);
            else if (source == 'team2') _team2Members.remove(name);
            else if (source == 'team3') _team3Members.remove(name);
            else if (source == 'team4') _team4Members.remove(name);
          });
        },
      ),
    );
  }

  Widget _buildTeamDropZone(String label, List<String> members, String targetId, Color color, int teamIndex) {
    return DragTarget<Map<String, String>>(
      onWillAccept: (data) => data != null && data['source'] != targetId,
      onAccept: (data) {
        setState(() {
          final name = data['name']!;
          final source = data['source']!;
          // Remove from source
          if (source == 'pool') _playerPool.remove(name);
          else if (source == 'team1') _team1Members.remove(name);
          else if (source == 'team2') _team2Members.remove(name);
          else if (source == 'team3') _team3Members.remove(name);
          else if (source == 'team4') _team4Members.remove(name);
          // Add to target
          members.add(name);
        });
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isHovered ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isHovered ? color : Colors.white10),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20, left: 12, right: 12, bottom: 8),
                child: TextField(
                  controller: _nameControllers[teamIndex],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w900, fontSize: 32),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: label,
                    hintStyle: TextStyle(color: color.withOpacity(0.3)),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    if (_isMobileControlEnabled && _roomCode != null) {
                      final names = _nameControllers.take(_teamCount).map((c) => c.text).toList();
                      FirebaseService().updateTeamNames(_roomCode!, names);
                    }
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: members.map((m) => _buildDraggablePlayerChip(m, targetId)).toList(),
                    ),
                    if (members.isEmpty)
                       Center(
                         child: Padding(
                           padding: const EdgeInsets.all(20),
                           child: Text(
                             _uiLanguage == 'ar' ? 'اسحب أسماء اللاعبين هنا' : 'Drag players here',
                             style: const TextStyle(color: Colors.white10, fontSize: 10),
                             textAlign: TextAlign.center,
                           ),
                         ),
                       ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addPlayer() {
    final name = _playerInputController.text.trim();
    if (name.isNotEmpty && !_playerPool.contains(name) && !_team1Members.contains(name) && !_team2Members.contains(name)) {
      setState(() {
        _playerPool.add(name);
        _playerInputController.clear();
      });
    }
  }

  void _autoShuffle() {
    final allPlayers = [..._playerPool, ..._team1Members, ..._team2Members]..shuffle();
    if (allPlayers.isEmpty) return;
    
    setState(() {
      _playerPool.clear();
      _team1Members.clear();
      _team2Members.clear();
      
      for (int i = 0; i < allPlayers.length; i++) {
        if (i % 2 == 0) _team1Members.add(allPlayers[i]);
        else _team2Members.add(allPlayers[i]);
      }
    });
  }
}
