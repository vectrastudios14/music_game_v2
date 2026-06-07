import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/firebase_service.dart';
import 'controller_buzzer_screen.dart';

class ControllerSetupScreen extends StatefulWidget {
  final String roomCode;

  const ControllerSetupScreen({super.key, required this.roomCode});

  @override
  State<ControllerSetupScreen> createState() => _ControllerSetupScreenState();
}

class _ControllerSetupScreenState extends State<ControllerSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedTeam;
  String? _team1Name;
  String? _team2Name;
  String? _roomMode; // 'team' or 'individual'
  bool _isJoining = false;
  StreamSubscription? _firebaseSubscription;

  @override
  void initState() {
    super.initState();
    _firebaseSubscription = FirebaseService().listenToRoomCustom(widget.roomCode).listen((data) {
      if (!mounted) return;
      if (data.isNotEmpty) {
        setState(() {
          _team1Name = data['team1Name'];
          _team2Name = data['team2Name'];
          _roomMode = data['mode'] ?? 'team';
          if (_roomMode == 'individual') {
            _selectedTeam = 'individual';
          }
        });
      }
    });
    _checkSavedSession();
  }

  void _checkSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRoom = prefs.getString('roomCode');
    final savedName = prefs.getString('playerName');
    final savedTeam = prefs.getString('teamName');
    
    if (savedRoom == widget.roomCode && savedName != null && savedTeam != null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ControllerBuzzerScreen(
              roomCode: savedRoom!,
              playerName: savedName,
              teamName: savedTeam,
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _firebaseSubscription?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  void _joinGame() async {
    if (_nameController.text.trim().isEmpty || _selectedTeam == null) return;
    
    setState(() {
      _isJoining = true;
    });

    final name = _nameController.text.trim();
    
    try {
      await FirebaseService().joinRoom(widget.roomCode, name, _selectedTeam!);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('roomCode', widget.roomCode);
      await prefs.setString('playerName', name);
      await prefs.setString('teamName', _selectedTeam!);
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ControllerBuzzerScreen(
            roomCode: widget.roomCode,
            playerName: name,
            teamName: _selectedTeam!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_roomMode == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final String team1DisplayName = _team1Name != null && _team1Name!.isNotEmpty ? _team1Name! : 'Team 1';
    final String team2DisplayName = _team2Name != null && _team2Name!.isNotEmpty ? _team2Name! : 'Team 2';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              'assets/Guess_that_song_logo.png',
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Your Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white10,
              ),
              style: const TextStyle(fontSize: 18),
            ),
            if (_roomMode != 'individual') ...[
              const SizedBox(height: 24),
              const Text(
                'Select Team:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TeamButton(
                      label: team1DisplayName,
                      color: Colors.cyan,
                      isSelected: _selectedTeam == 'team1',
                      onTap: () => setState(() => _selectedTeam = 'team1'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _TeamButton(
                      label: team2DisplayName,
                      color: Colors.pinkAccent,
                      isSelected: _selectedTeam == 'team2',
                      onTap: () => setState(() => _selectedTeam = 'team2'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isJoining ? null : _joinGame,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isJoining 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('JOIN GAME', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _TeamButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TeamButton({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.3) : color.withOpacity(0.05),
          border: Border.all(color: isSelected ? color : color.withOpacity(0.5), width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
