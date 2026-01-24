import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:io';
import 'gts/setup_screen.dart';
import 'boa/boa_setup_screen.dart';

class GameHubScreen extends StatelessWidget {
  const GameHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Hub'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Quit Game',
            onPressed: () {
               exit(0);
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeInDown(
                child: Text(
                  'Choose Your Game',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ),
              const SizedBox(height: 50),
              
              // Guess That Song Game
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: _GameModeCard(
                  title: 'Guess That Song',
                  imagePath: 'assets/gts-logo-transparent.png',
                  onTap: () {
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GtsSetupScreen(),
                      ),
                    );
                    
                    // debugPrint("GTS CLICKED - SAFE MODE");
                  },
                ),
              ),
              
              const SizedBox(height: 30),

              // Before or After Game
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: _GameModeCard(
                  title: 'Before or After?',
                  imagePath: 'assets/boa-logo-transparent.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BoaSetupScreen(),
                      ),
                    );
                    // debugPrint("BOA DISABLED - DEBUGGING CRASH");
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameModeCard extends StatefulWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  const _GameModeCard({
    required this.title,
    required this.imagePath,
    required this.onTap,
  });

  @override
  State<_GameModeCard> createState() => _GameModeCardState();
}

class _GameModeCardState extends State<_GameModeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 350,
          height: 250, // Slightly taller to accommodate image
          transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered 
                  ? Theme.of(context).primaryColor 
                  : Colors.white.withOpacity(0.1),
              width: 2,
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Image.asset(
                    widget.imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              /*
              Expanded(
                flex: 1,
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _isHovered ? Theme.of(context).primaryColor : Colors.white,
                  ),
                ),
              ),
              */
            ],
          ),
        ),
      ),
    );
  }
}
