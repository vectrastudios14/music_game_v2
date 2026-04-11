import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/song_repository.dart';
import 'boa_game_screen.dart';
import 'boa_help_screen.dart';
import '../../services/background_music_service.dart';

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
                      height: 220,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 60),
  
                  // 2. Settings Row (Target Score & Player Count)
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
                            // Player Count
                            Expanded(
                              child: Row(
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
  
                  // 3. Player Names
                  Expanded(
                    child: Center(
                      child: FadeInUp(
                        delay: const Duration(milliseconds: 300),
                        child: SingleChildScrollView( 
                          child: Wrap(
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
                              onPressed: () async {
                                List<String> playerNames = _nameControllers.map((c) => c.text).toList();
                                BackgroundMusicService.instance.stopMenuMusic();
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BoaGameScreen(
                                      targetScore: _targetScore,
                                      playerNames: playerNames,
                                      uiLanguage: _uiLanguage,
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
}
