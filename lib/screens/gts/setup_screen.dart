import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/song_repository.dart';
import 'game_screen.dart';
import 'help_screen.dart';
import '../../services/background_music_service.dart';

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
  final List<TextEditingController> _nameControllers = [];
  
  // Interactive Team Setup State
  final List<String> _playerPool = [];
  final List<String> _team1Members = [];
  final List<String> _team2Members = [];
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
    final count = _isTeamMode ? 2 : _playerCount;
    final isAr = _uiLanguage == 'ar';
    
    // Adjust list size
    while (_nameControllers.length < count) {
      _nameControllers.add(TextEditingController());
    }
    while (_nameControllers.length > count) {
      _nameControllers.last.dispose();
      _nameControllers.removeLast();
    }
    
    // Set default texts based on mode
    for (int i = 0; i < _nameControllers.length; i++) {
      if (_isTeamMode) {
        _nameControllers[i].text = isAr ? 'الفريق ${i + 1}' : 'Team ${i + 1}';
      } else {
        _nameControllers[i].text = isAr ? 'اللاعب ${i + 1}' : 'Player ${i + 1}';
      }
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
        appBar: AppBar(
          title: null,
          centerTitle: true,
          backgroundColor: Colors.transparent,
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
                                      isAr ? 'الوضع: ${_isHardMode ? "صعب" : "سهل"}' : 'Mode: ${_isHardMode ? "Hard" : "Easy"}', 
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
                        // Library Toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(isAr ? 'المكتبة: ' : 'Library: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(width: 10),
                            FilterChip(
                              label: Text(isAr ? 'الإنجليزية' : 'English'),
                              selected: _libraryType == 'english',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _libraryType = 'english');
                                  SongRepository().setLibrary('english');
                                  _preloadGameAssets();
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
                                  _preloadGameAssets();
                                }
                              },
                            ),
                          ],
                        ),
                        // Game Type Toggle
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(isAr ? 'نوع اللعبة: ' : 'Game Type: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(width: 10),
                            ChoiceChip(
                              label: Text(isAr ? 'فردي' : 'Individual'),
                              selected: !_isTeamMode,
                              onSelected: (selected) { 
                                if (selected) {
                                  setState(() => _isTeamMode = false);
                                  _updateControllers();
                                  _preloadGameAssets(); // RELOAD CACHE
                                }
                              },
                            ),
                            const SizedBox(width: 10),
                            ChoiceChip(
                              label: Text(isAr ? 'فرق' : 'Teams'),
                              selected: _isTeamMode,
                              onSelected: (selected) { 
                                if (selected) {
                                  setState(() => _isTeamMode = true);
                                  _updateControllers();
                                  _preloadGameAssets(); // RELOAD CACHE
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // 3. Player Count (Only for Individual Mode)
                  if (!_isTeamMode)
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
                  Expanded(
                    child: _isTeamMode ? _buildTeamSetupBoard(isAr) : _buildIndividualSetup(isAr),
                  ),
  
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
                                List<String> playerNames = _nameControllers
                                  .take(_isTeamMode ? 2 : _playerCount)
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
                                      teamMembers: _isTeamMode ? {
                                        playerNames[0]: _team1Members,
                                        playerNames[1]: _team2Members,
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
    );
  }
  Widget _buildIndividualSetup(bool isAr) {
    return Center(
      child: FadeInUp(
        delay: const Duration(milliseconds: 300),
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: List.generate(_playerCount, (index) {
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
      ),
    );
  }

  Widget _buildTeamSetupBoard(bool isAr) {
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: Column(
        children: [
          // Player Input Field
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
          // Teams Board
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildTeamDropZone(isAr ? 'الفريق 1' : 'Team 1', _team1Members, 'team1', Colors.cyan, 0)),
                const SizedBox(width: 16),
                Expanded(child: _buildTeamDropZone(isAr ? 'الفريق 2' : 'Team 2', _team2Members, 'team2', Colors.pinkAccent, 1)),
              ],
            ),
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
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(8),
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
