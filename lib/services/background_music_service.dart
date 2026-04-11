import 'package:audioplayers/audioplayers.dart';

class BackgroundMusicService {
  // Singleton instance
  static final BackgroundMusicService _instance = BackgroundMusicService._internal();
  static BackgroundMusicService get instance => _instance;

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  BackgroundMusicService._internal();

  /// Starts playing the menu music if it's not already playing.
  Future<void> playMenuMusic() async {
    if (_isPlaying) return;

    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('chillhop.mp3'));
      await _player.setVolume(0.3); // Set a reasonable background volume
      _isPlaying = true;
      print("DEBUG: Background music started.");
    } catch (e) {
      print("Error playing background music: $e");
    }
  }

  /// Stops the menu music.
  Future<void> stopMenuMusic() async {
    if (!_isPlaying) return;

    try {
      await _player.stop();
      _isPlaying = false;
      print("DEBUG: Background music stopped.");
    } catch (e) {
      print("Error stopping background music: $e");
    }
  }

  /// Fades out the music before stopping.
  Future<void> fadeOutMenuMusic() async {
    if (!_isPlaying) return;

    try {
      const int steps = 20;
      const double startVolume = 0.3;
      
      for (int i = steps; i >= 0; i--) {
        double volume = (i / steps) * startVolume;
        await _player.setVolume(volume);
        await Future.delayed(const Duration(milliseconds: 50));
      }
      await stopMenuMusic();
    } catch (e) {
      print("Error fading out background music: $e");
    }
  }

  // Separate player for SFX to allow overlapping with music
  final AudioPlayer _sfxPlayer = AudioPlayer();

  /// Plays a sound effect
  Future<void> playSfx(String assetName) async {
    try {
      if (_sfxPlayer.state == PlayerState.playing) {
        await _sfxPlayer.stop(); // Stop current SFX if any (optional, or use multiple players)
      }
      await _sfxPlayer.setReleaseMode(ReleaseMode.release);
      await _sfxPlayer.play(AssetSource(assetName));
      await _sfxPlayer.setVolume(1.0); 
    } catch (e) {
      print("Error playing SFX: $e");
    }
  }

  void dispose() {
    _player.dispose();
    _sfxPlayer.dispose();
  }
}
