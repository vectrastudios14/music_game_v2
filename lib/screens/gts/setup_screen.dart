import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/song_repository.dart';
import 'game_screen.dart';

class GtsSetupScreen extends StatefulWidget {
  const GtsSetupScreen({super.key});

  @override
  State<GtsSetupScreen> createState() => _GtsSetupScreenState();
}

class _GtsSetupScreenState extends State<GtsSetupScreen> {
  int _rounds = 5;
  int _playerCount = 2;
  bool _isHardMode = true; // Default to Hard (Artist only)
  final List<TextEditingController> _nameControllers = [];

  @override
  void initState() {
    super.initState();
    _updateControllers();
    
    // Pre-load assets
    _preloadGameAssets();
  }

  Future<void> _preloadGameAssets() async {
    // 1. Initialize Repo
    await SongRepository().loadSongs();
    
    // 2. Prepare First Question
    // We need to access the repository and trigger "getNextQuestion" 
    // but store it in the repository for the game screen to pick up.
    // I will add a helper method to Repository for this.
    await SongRepository().prepareFirstRoundGTS();
  }

  void _updateControllers() {
    // Add controllers if needed
    while (_nameControllers.length < _playerCount) {
      _nameControllers.add(TextEditingController(text: 'Player ${_nameControllers.length + 1}'));
    }
    // Remove excess controllers
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Setup'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Rounds Selection
                  FadeInDown(
                    child: _buildSectionTitle('Number of Rounds: $_rounds'),
                  ),
                  FadeInDown(
                    delay: const Duration(milliseconds: 100),
                    child: Slider(
                      value: _rounds.toDouble(),
                      min: 2,
                      max: 10,
                      divisions: 8,
                      label: _rounds.toString(),
                      onChanged: (value) {
                        setState(() {
                          _rounds = value.round();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Player Count Selection
                  FadeInDown(
                    delay: const Duration(milliseconds: 200),
                    child: _buildSectionTitle('Number of Players: $_playerCount'),
                  ),
                  FadeInDown(
                    delay: const Duration(milliseconds: 300),
                    child: Slider(
                      value: _playerCount.toDouble(),
                      min: 1,
                      max: 8,
                      divisions: 7,
                      label: _playerCount.toString(),
                      onChanged: (value) {
                        setState(() {
                          _playerCount = value.round();
                          _updateControllers();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Difficulty Selection
                  FadeInDown(
                    delay: const Duration(milliseconds: 300),
                    child: _buildSectionTitle('Difficulty'),
                  ),
                  FadeInDown(
                    delay: const Duration(milliseconds: 350),
                    child: SwitchListTile(
                      title: Text(
                        _isHardMode ? 'Hard Mode' : 'Easy Mode',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      subtitle: Text(
                        _isHardMode ? 'Artist Name Only' : 'Artist + Song Title',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      value: _isHardMode,
                      activeColor: Theme.of(context).primaryColor,
                      onChanged: (value) {
                        setState(() {
                          _isHardMode = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Player Names
                  FadeInDown(
                    delay: const Duration(milliseconds: 400),
                    child: _buildSectionTitle('Player Names'),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    child: Builder(
                      builder: (context) {
                        // Calculate split for 2 rows
                        int count = _playerCount; // 1 to 8
                        int firstRowCount = (count / 2).ceil();
                        int secondRowCount = count - firstRowCount;
                        
                        return Column(
                          children: [
                            // First Row
                            Row(
                              children: List.generate(firstRowCount, (index) {
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    child: TextField(
                                      controller: _nameControllers[index],
                                      onTap: () => _nameControllers[index].clear(),
                                      decoration: InputDecoration(
                                        labelText: 'Player ${index + 1}',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        filled: true,
                                        fillColor: Theme.of(context).cardTheme.color,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 12),
                            // Second Row
                            if (secondRowCount > 0)
                              Row(
                                children: List.generate(secondRowCount, (index) {
                                  int actualIndex = firstRowCount + index;
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      child: TextField(
                                        controller: _nameControllers[actualIndex],
                                        onTap: () => _nameControllers[actualIndex].clear(),
                                        decoration: InputDecoration(
                                          labelText: 'Player ${actualIndex + 1}',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: Theme.of(context).cardTheme.color,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Start Button
                  FadeInUp(
                    delay: const Duration(milliseconds: 600),
                    child: ElevatedButton(
                  onPressed: () {
                    // Collect names
                    List<String> playerNames = _nameControllers.map((c) => c.text).toList();
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GtsGameScreen(
                          totalRounds: _rounds,
                          playerNames: playerNames,
                          isHardMode: _isHardMode,
                        ),
                      ),
                    );
                  },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(20),
                        textStyle: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      child: const Text('START GAME'),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: Theme.of(context).primaryColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
