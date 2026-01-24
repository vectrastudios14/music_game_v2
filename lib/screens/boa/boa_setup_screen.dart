import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/song_repository.dart';
import 'boa_game_screen.dart';

class BoaSetupScreen extends StatefulWidget {
  const BoaSetupScreen({super.key});

  @override
  State<BoaSetupScreen> createState() => _BoaSetupScreenState();
}

class _BoaSetupScreenState extends State<BoaSetupScreen> {
  int _targetScore = 10;
  int _playerCount = 2;
  final List<TextEditingController> _nameControllers = [];

  @override
  void initState() {
    super.initState();
    _updateControllers();
    _preloadAssets();
  }

  Future<void> _preloadAssets() async {
    await SongRepository().loadSongs();
    // Pre-load for current default players (2) + buffer (2) = 4 to be safe?
    // or just pass _playerCount.
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Timeline Setup', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
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
                  // Target Score
                  FadeInDown(
                    child: _buildSectionTitle('Target Score: $_targetScore Cards'),
                  ),
                  FadeInDown(
                    delay: const Duration(milliseconds: 100),
                    child: Slider(
                      value: _targetScore.toDouble(),
                      min: 6,
                      max: 20, 
                      divisions: 14,
                      label: _targetScore.toString(),
                      onChanged: (value) {
                        setState(() {
                          _targetScore = value.round();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Player Count
                  FadeInDown(
                    delay: const Duration(milliseconds: 200),
                    child: _buildSectionTitle('Number of Players: $_playerCount'),
                  ),
                  FadeInDown(
                    delay: const Duration(milliseconds: 300),
                    child: Slider(
                      value: _playerCount.toDouble(),
                      min: 1,
                      max: 6,
                      divisions: 5,
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

                  // Player Names
                  FadeInDown(
                    delay: const Duration(milliseconds: 400),
                    child: _buildSectionTitle('Player Names'),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    child: Column(
                      children: List.generate(_playerCount, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: TextField(
                            controller: _nameControllers[index],
                            onTap: () => _nameControllers[index].clear(),
                            decoration: InputDecoration(
                              labelText: 'Player ${index + 1}',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[200],
                              prefixIcon: const Icon(Icons.person, color: Colors.black54),
                              labelStyle: const TextStyle(color: Colors.black87),
                            ),
                            style: const TextStyle(color: Colors.black),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Start Button
                  FadeInUp(
                    delay: const Duration(milliseconds: 600),
                    child: ElevatedButton(
                      onPressed: () {
                         // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("SETUP OK - CONNECTING GAME SOON")));
                        
                        List<String> playerNames = _nameControllers.map((c) => c.text).toList();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BoaGameScreen(
                              targetScore: _targetScore,
                              playerNames: playerNames,
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
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
