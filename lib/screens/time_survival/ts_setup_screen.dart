import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../services/song_repository.dart';
import 'ts_game_screen.dart';
import 'ts_help_screen.dart';
import '../../services/background_music_service.dart';
import '../../services/firebase_service.dart';

class TsSetupScreen extends StatefulWidget {
  const TsSetupScreen({super.key});

  @override
  State<TsSetupScreen> createState() => _TsSetupScreenState();
}

class _TsSetupScreenState extends State<TsSetupScreen> {
  int _playerCount = 2;
  int _startingPoints = 100;
  String _startingLibraryType = SongRepository().currentLibraryType;
  String _uiLanguage = 'en'; // 'en' or 'ar'
  final List<TextEditingController> _nameControllers = [];
  
  bool _isMobileControlEnabled = false;
  String? _roomCode;
  final List<String> _playerPool = [];
  bool _isQrZoomed = false;
  
  final List<Color> _availableColors = [
    const Color(0xFFFF595E),
    const Color(0xFF25A479),
    const Color(0xFF1982C4),
    const Color(0xFFFFCA3A),
    const Color(0xFF8AC926),
    const Color(0xFF6A4C93),
    const Color(0xFFFF924C),
    const Color(0xFF4CC9F0),
    const Color(0xFFF72585),
    const Color(0xFF008080),
    const Color(0xFF800000),
    const Color(0xFFB5179E),
  ];
  late List<Color> _playerColors;

  @override
  void initState() {
    super.initState();
    _playerColors = List.generate(12, (index) => _availableColors[index % _availableColors.length]);
    _updateControllers();
    _preloadAssets();
  }

  Future<void> _preloadAssets() async {
    await SongRepository().loadSongs();
    await SongRepository().prepareDeck(playerCount: _playerCount);
  }

  void _updateControllers() {
    while (_nameControllers.length < _playerCount) {
      _nameControllers.add(TextEditingController(text: 'Player ${_nameControllers.length + 1}'));
    }
    while (_nameControllers.length > _playerCount) {
      _nameControllers.last.dispose();
      _nameControllers.removeLast();
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
        backgroundColor: const Color(0xFF1E1E2C),
        appBar: AppBar(
          title: null,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          actions: [
            // UI Language Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton.icon(
                onPressed: () => setState(() => _uiLanguage = isAr ? 'en' : 'ar'),
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
              child: Column(
                children: [
                  // 1. Logo
                  FadeInDown(
                    child: Image.asset(
                      'assets/TimeSurvival_logo.png',
                      height: 140,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),
  
                  // 2. Settings Row
                  FadeInDown(
                    delay: const Duration(milliseconds: 200),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(isAr ? 'المكتبة: ' : 'Library: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                            const SizedBox(width: 10),
                            FilterChip(
                              label: Text(isAr ? 'الإنجليزية' : 'English'),
                              selected: _startingLibraryType == 'english',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _startingLibraryType = 'english');
                                  SongRepository().setLibrary('english');
                                  _preloadAssets();
                                }
                              },
                            ),
                            const SizedBox(width: 10),
                            FilterChip(
                              label: Text(isAr ? 'العربية' : 'Arabic'),
                              selected: _startingLibraryType == 'arabic',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _startingLibraryType = 'arabic');
                                  SongRepository().setLibrary('arabic');
                                  _preloadAssets();
                                }
                              },
                            ),
                            const SizedBox(width: 10),
                            FilterChip(
                              label: Text(isAr ? 'مزيج' : 'Mix'),
                              selected: _startingLibraryType == 'mix',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _startingLibraryType = 'mix');
                                  SongRepository().setLibrary('mix');
                                  _preloadAssets();
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Mobile Control Switch
                        SwitchListTile(
                          title: Text(
                            isAr ? 'تحكم الجوال' : 'Mobile Control',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white70),
                          ),
                          value: _isMobileControlEnabled,
                          activeColor: const Color(0xFF6C63FF),
                          onChanged: (val) async {
                            setState(() {
                              _isMobileControlEnabled = val;
                            });
                            if (val) {
                              _roomCode = FirebaseService().generateRoomCode();
                              await FirebaseService().createRoom(_roomCode!);
                              await FirebaseService().setGameType(_roomCode!, 'ts');
                              await FirebaseService().setRoomMode(_roomCode!, 'individual');

                              _playerPool.clear();
                              FirebaseService().listenForJoins(_roomCode!, (name, team) {
                                if (mounted) {
                                  setState(() {
                                    if (!_playerPool.contains(name)) {
                                      _playerPool.add(name);
                                      _playerCount = _playerPool.length;
                                      _updateControllers();
                                      for (int i = 0; i < _playerPool.length; i++) {
                                        _nameControllers[i].text = _playerPool[i];
                                      }
                                    }
                                  });
                                }
                              });
                            } else {
                              FirebaseService().stopListeningForJoins();
                              setState(() {
                                _roomCode = null;
                                _playerPool.clear();
                                _playerCount = 2;
                                _updateControllers();
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (!_isMobileControlEnabled)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Text(isAr ? 'اللاعبون: $_playerCount' : 'Players: $_playerCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white70)),
                                    Slider(
                                      value: _playerCount.toDouble(),
                                      min: 2, max: 12, divisions: 10,
                                      label: _playerCount.toString(),
                                      activeColor: const Color(0xFF6C63FF),
                                      onChanged: (value) {
                                        setState(() {
                                          _playerCount = value.round();
                                          _updateControllers();
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            if (!_isMobileControlEnabled) const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(isAr ? 'النقاط: $_startingPoints' : 'Points: $_startingPoints', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white70)),
                                  Slider(
                                    value: _startingPoints.toDouble(),
                                    min: 100, max: 200, divisions: 10,
                                    label: _startingPoints.toString(),
                                    activeColor: const Color(0xFF00E676),
                                    onChanged: (value) => setState(() => _startingPoints = value.round()),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 10),
  
                  // 3. Player Names or QR Display
                  Expanded(
                    child: Center(
                      child: FadeInUp(
                        delay: const Duration(milliseconds: 300),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isMobileControlEnabled && _roomCode != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Column(
                                    children: [
                                      GestureDetector(
                                        onTap: () => setState(() => _isQrZoomed = !_isQrZoomed),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 250),
                                          width: _isQrZoomed ? 260 : 110,
                                          height: _isQrZoomed ? 260 : 110,
                                          child: QrImageView(
                                            data: 'https://vectrastudios14.github.io/music_game_v2/#/controller?room=$_roomCode',
                                            version: QrVersions.auto,
                                            backgroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        isAr ? 'رمز الغرفة: $_roomCode' : 'Room Code: $_roomCode',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  isAr ? 'اللاعبون المنضمون:' : 'Joined Players:',
                                  style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: List.generate(_playerPool.length, (index) {
                                    return Chip(
                                      backgroundColor: _playerColors[index % _playerColors.length],
                                      label: Text(
                                        _playerPool[index],
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    );
                                  }),
                                ),
                              ] else
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    childAspectRatio: 3.5,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemCount: _playerCount,
                                  itemBuilder: (context, index) {
                                    return Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              int currentIndex = _availableColors.indexOf(_playerColors[index]);
                                              _playerColors[index] = _availableColors[(currentIndex + 1) % _availableColors.length];
                                            });
                                          },
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: _playerColors[index],
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 2),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            controller: _nameControllers[index],
                                            onTap: () => _nameControllers[index].clear(),
                                            decoration: InputDecoration(
                                              labelText: isAr ? 'اللاعب ${index + 1}' : 'Player ${index + 1}',
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                              filled: true,
                                              fillColor: Colors.white.withOpacity(0.1),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                              labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                                            ),
                                            style: const TextStyle(color: Colors.white, fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
  
                  const SizedBox(height: 20),
  
                  // 4. Start Button
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 60,
                            child: ElevatedButton(
                              onPressed: (_isMobileControlEnabled && _playerPool.isEmpty) ? null : () async {
                                List<String> playerNames = _isMobileControlEnabled 
                                    ? _playerPool 
                                    : _nameControllers.map((c) => c.text).toList();
                                Map<String, Color> playerColorsMap = {};
                                for (int i=0; i<playerNames.length; i++) {
                                   playerColorsMap[playerNames[i]] = _playerColors[i % _playerColors.length];
                                }
                                BackgroundMusicService.instance.stopMenuMusic();
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TsGameScreen(
                                      playerNames: playerNames,
                                      playerColors: playerColorsMap,
                                      startingPoints: _startingPoints,
                                      uiLanguage: _uiLanguage,
                                      roomCode: _isMobileControlEnabled ? _roomCode : null,
                                    ),
                                  ),
                                );
                                BackgroundMusicService.instance.playMenuMusic();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6C63FF),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                MaterialPageRoute(builder: (context) => TsHelpScreen(initialIsArabic: _uiLanguage == 'ar')),
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
    );
  }
}
