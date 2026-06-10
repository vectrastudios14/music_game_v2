import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../services/song_repository.dart';
import 'boa_game_screen.dart';
import 'boa_help_screen.dart';
import '../../services/background_music_service.dart';
import '../../services/firebase_service.dart';

class BoaSetupScreen extends StatefulWidget {
  const BoaSetupScreen({super.key});

  @override
  State<BoaSetupScreen> createState() => _BoaSetupScreenState();
}

class _BoaSetupScreenState extends State<BoaSetupScreen> {
  int _targetScore = 10;
  int _playerCount = 2;
  String _libraryType = SongRepository().currentLibraryType;
  String _uiLanguage = 'en'; // 'en' or 'ar'
  final List<TextEditingController> _nameControllers = [];

  // Mobile Controller variables
  bool _isMobileControlEnabled = false;
  String? _roomCode;
  final List<String> _playerPool = [];
  bool _isQrZoomed = false;

  @override
  void initState() {
    super.initState();
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
    for (var controller in _nameControllers) {
      controller.dispose();
    }
    FirebaseService().stopListeningForJoins();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _uiLanguage == 'ar';
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: null,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.black),
          elevation: 0,
          actions: [
            // UI Language Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton.icon(
                onPressed: () => setState(() => _uiLanguage = isAr ? 'en' : 'ar'),
                icon: const Icon(Icons.language, color: Colors.black54, size: 20),
                label: Text(
                  isAr ? "English" : "عربي",
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
                      'assets/Before_or_after_logo.png',
                      height: 180,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 30),
  
                  // 2. Settings Row (Target Score & Mobile Control)
                  FadeInDown(
                    delay: const Duration(milliseconds: 100),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Target Score
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    isAr ? 'الهدف: $_targetScore' : 'Target Score: $_targetScore', 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: _targetScore.toDouble(),
                                      min: 6, max: 10, divisions: 4,
                                      label: _targetScore.toString(),
                                      onChanged: (v) => setState(() => _targetScore = v.round()),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Mobile Control Toggle
                            Expanded(
                              child: SwitchListTile(
                                title: Text(
                                  isAr ? 'تحكم الجوال' : 'Mobile Control',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                ),
                                value: _isMobileControlEnabled,
                                onChanged: (val) async {
                                  setState(() {
                                    _isMobileControlEnabled = val;
                                  });
                                  if (val) {
                                    _roomCode = FirebaseService().generateRoomCode();
                                    await FirebaseService().createRoom(_roomCode!);
                                    await FirebaseService().setGameType(_roomCode!, 'boa');
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
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        
                        // Player Count (Only when mobile control is disabled)
                        if (!_isMobileControlEnabled)
                          Row(
                            children: [
                              Text(
                                isAr ? 'اللاعبون: $_playerCount' : 'Players: $_playerCount', 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)
                              ),
                              Expanded(
                                child: Slider(
                                  value: _playerCount.toDouble(),
                                  min: 1, max: 6, divisions: 5,
                                  label: _playerCount.toString(),
                                  onChanged: (v) => setState(() {
                                    _playerCount = v.round();
                                    _updateControllers();
                                  }),
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 10),
                        
                        // Library Toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(isAr ? 'المكتبة: ' : 'Library: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                            const SizedBox(width: 10),
                            FilterChip(
                              label: Text(isAr ? 'الإنجليزية' : 'English'),
                              selected: _libraryType == 'english',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _libraryType = 'english');
                                  SongRepository().setLibrary('english');
                                  _preloadAssets();
                                }
                              },
                            ),
                            const SizedBox(width: 10),
                            FilterChip(
                              label: Text(isAr ? 'العربية' : 'Arabic'),
                              selected: _libraryType == 'arabic',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _libraryType = 'arabic');
                                  SongRepository().setLibrary('arabic');
                                  _preloadAssets();
                                }
                              },
                            ),
                            const SizedBox(width: 10),
                            FilterChip(
                              label: Text(isAr ? 'مزيج' : 'Mix'),
                              selected: _libraryType == 'mix',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _libraryType = 'mix');
                                  SongRepository().setLibrary('mix');
                                  _preloadAssets();
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
  
                  // QR code display
                  if (_isMobileControlEnabled && _roomCode != null) ...[
                    const SizedBox(height: 15),
                    FadeInUp(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey[300]!),
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
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // 3. Player Names / Joined list
                  Expanded(
                    child: Center(
                      child: FadeInUp(
                        delay: const Duration(milliseconds: 300),
                        child: SingleChildScrollView( 
                          child: _isMobileControlEnabled
                              ? _buildJoinedPlayersList(isAr)
                              : Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  alignment: WrapAlignment.center,
                                  children: List.generate(_playerCount, (index) {
                                     return SizedBox(
                                       width: 160,
                                       child: TextField(
                                         controller: _nameControllers[index],
                                         onTap: () => _nameControllers[index].clear(),
                                         decoration: InputDecoration(
                                           labelText: isAr ? 'اللاعب ${index + 1}' : 'Player ${index + 1}',
                                           isDense: true,
                                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                           filled: true,
                                           fillColor: Colors.grey[200],
                                           contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                           prefixIcon: const Icon(Icons.person, color: Colors.black54),
                                           labelStyle: const TextStyle(color: Colors.black87),
                                         ),
                                         style: const TextStyle(color: Colors.black),
                                       ),
                                     );
                                  }),
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
                              onPressed: (_isMobileControlEnabled && _playerPool.isEmpty)
                                  ? null
                                  : () async {
                                      List<String> playerNames = _isMobileControlEnabled
                                          ? _playerPool
                                          : _nameControllers.map((c) => c.text).toList();
                                      
                                      BackgroundMusicService.instance.stopMenuMusic();
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BoaGameScreen(
                                            targetScore: _targetScore,
                                            playerNames: playerNames,
                                            uiLanguage: _uiLanguage,
                                            roomCode: _isMobileControlEnabled ? _roomCode : null,
                                          ),
                                        ),
                                      );
                                      BackgroundMusicService.instance.playMenuMusic();
                                    },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(0),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                                MaterialPageRoute(builder: (context) => BoaHelpScreen(initialIsArabic: _uiLanguage == 'ar')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 0,
                            ),
                            child: Text(isAr ? 'مساعدة' : "Help", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
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

  Widget _buildJoinedPlayersList(bool isAr) {
    if (_playerPool.isEmpty) {
      return Text(
        isAr ? 'في انتظار انضمام اللاعبين...' : 'Waiting for players to join...',
        style: GoogleFonts.outfit(
          color: Colors.grey[500],
          fontSize: 16,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return Column(
      children: [
        Text(
          isAr ? 'اللاعبون المنضمون:' : 'Joined Players:',
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: _playerPool.map((player) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.teal[50],
                border: Border.all(color: Colors.teal[200]!),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    player,
                    style: GoogleFonts.outfit(
                      color: Colors.teal[900],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _playerPool.remove(player);
                        _playerCount = _playerPool.length;
                        _updateControllers();
                      });
                      FirebaseService().kickPlayer(_roomCode!, player);
                    },
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
