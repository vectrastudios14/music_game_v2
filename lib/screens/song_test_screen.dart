import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/song.dart';
import '../services/song_review_service.dart';

class SongTestScreen extends StatefulWidget {
  const SongTestScreen({super.key});

  @override
  State<SongTestScreen> createState() => _SongTestScreenState();
}

class _SongTestScreenState extends State<SongTestScreen> {
  final SongReviewService _service = SongReviewService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // State
  String _currentLibrary = 'english'; // 'english', 'arabic'
  List<Song> _songs = [];
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _isPlaying = false;
  bool _isFetchingArt = false;
  bool _isFetchingAudio = false;
  bool _isAddingNew = false;
  
  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();
  final TextEditingController _titleArController = TextEditingController();
  final TextEditingController _artistArController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _artworkController = TextEditingController();
  final TextEditingController _factsController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLibrary();
    
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });

    // Update preview when artwork URL changes
    _artworkController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadLibrary() async {
    setState(() => _isLoading = true);
    try {
      final songs = await _service.loadSongs(_currentLibrary);
      setState(() {
        _songs = songs;
        _currentIndex = 0;
      });
      if (_songs.isNotEmpty) {
        _loadSongData(_songs[0]);
      } else {
        _clearForm();
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _loadSongData(Song song) {
    _titleController.text = song.title;
    _artistController.text = song.artist;
    _titleArController.text = song.titleAr ?? '';
    _artistArController.text = song.artistAr ?? '';
    _yearController.text = song.year;
    _linkController.text = song.link;
    _artworkController.text = song.artworkUrl ?? '';
    _factsController.text = song.facts.join('\n');
    _genderController.text = song.gender ?? '';
    
    _stopMusic(); // Stop previous song when loading new data
  }

  Future<void> _playMusic() async {
    if (_linkController.text.isEmpty) return; // Check if link is available
    try {
      // Use current text field value so user can preview FETCHED audio before saving
      await _audioPlayer.play(UrlSource(_linkController.text));
      setState(() => _isPlaying = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error playing: $e")));
    }
  }

  Future<void> _stopMusic() async {
    await _audioPlayer.stop();
  }
  
  Future<Map<String, dynamic>?> _searchItunes(String term) async {
    try {
      final uri = Uri.https('itunes.apple.com', '/search', {
        'term': term,
        'limit': '1',
        'media': 'music',
        'entity': 'song'
      });
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['resultCount'] > 0) {
          return data['results'][0];
        }
      }
    } catch (e) {
      print("iTunes Search Error: $e");
    }
    return null;
  }

  Future<void> _fetchArtwork() async {
    setState(() => _isFetchingArt = true);
    final term = "${_artistController.text} ${_titleController.text}";
    final result = await _searchItunes(term);
    if (result != null) {
      final artworkUrl = result['artworkUrl100'] as String?;
      if (artworkUrl != null) {
        String art = artworkUrl.replaceAll('100x100bb', '600x600bb');
        setState(() => _artworkController.text = art);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Artwork Found!")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No artwork URL in result")));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No artwork found")));
    }
    setState(() => _isFetchingArt = false);
  }

  Future<void> _fetchAudioLink() async {
    final rawArtist = _artistController.text.trim();
    final rawTitle = _titleController.text.trim();
    
    if (rawArtist.isEmpty || rawTitle.isEmpty) return;

    setState(() => _isFetchingAudio = true);
    try {
      // 1. Clean terms for search
      // Remove ft, feat, parens etc for the search query itself
      String cleanTerm(String s) {
        return s.toLowerCase()
          .replaceAll(RegExp(r'\s(ft\.?|feat\.?|starring|featuring)\s.*'), '') 
          .replaceAll(RegExp(r'\s?\(.*?\)\s?'), '') 
          .replaceAll(RegExp(r'[^\w\s]'), '') 
          .trim();
      }
      
      final searchQueries = [
         "${cleanTerm(rawArtist)} ${cleanTerm(rawTitle)}",
         "$rawArtist $rawTitle", // Fallback to raw params
      ];
      
      List<dynamic> results = [];
      
      // Try strategies until we get results
      for (final query in searchQueries) {
         final uri = Uri.https('itunes.apple.com', '/search', {
          'term': query,
          'limit': '50', // Increase limit to find buried originals
          'media': 'music',
          'entity': 'song'
        });
        
        final response = await http.get(uri);
        if (response.statusCode == 200) {
           final data = jsonDecode(response.body);
           if (data['resultCount'] > 0) {
             results = data['results'];
             break; // Found results, stop trying queries
           }
        }
      }

      if (results.isNotEmpty) {
           // Helper: Remove all non-alphanumeric for comparison
           String cleanCmp(String s) {
             return s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
           }

           final targetArtist = cleanCmp(rawArtist);
           final targetTitle = cleanCmp(rawTitle);

           var candidates = results.where((r) {
             final rArtist = cleanCmp(r['artistName'].toString());
             final rTrack = cleanCmp(r['trackName'].toString());
             
             // Artist must match loosely (substring)
             bool artistMatch = rArtist.contains(targetArtist) || targetArtist.contains(rArtist);

             // Title MUST be present in the result
             bool titleMatch = rTrack.contains(targetTitle) || targetTitle.contains(rTrack);

             // KIND MUST BE SONG
             bool isSong = r['kind'] == 'song';
             
             return artistMatch && titleMatch && isSong;
           }).toList();
           
           if (candidates.isNotEmpty) {
             // Sort: Prefer Non-Remix and Exact Artist Match
             candidates.sort((a, b) {
               final aName = a['trackName'].toString().toLowerCase();
               final bName = b['trackName'].toString().toLowerCase();
               final aArtist = cleanCmp(a['artistName'].toString());
               final bArtist = cleanCmp(b['artistName'].toString());
               
               // 1. Penalize Remix/Cover
               final aIsRemix = aName.contains("remix") || aName.contains("live") || aName.contains("cover");
               final bIsRemix = bName.contains("remix") || bName.contains("live") || bName.contains("cover");
               if (aIsRemix && !bIsRemix) return 1; 
               if (!aIsRemix && bIsRemix) return -1;
               
               // 2. Prefer Exact Artist Match length (shorter is usually better if it matches, e.g. "Tame Impala" vs "Tame Impala Cover Band")
               // But usually we just want to ensure it's the main artist.
               
               return 0;
             });

             final bestMatch = candidates.first;
             final audioUrl = bestMatch['previewUrl'];

             if (audioUrl != null) {
                _updateLink(audioUrl, "Best Match Found: ${bestMatch['trackName']} by ${bestMatch['artistName']}");
             } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No preview URL for best match.")));
             }
           } else {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No matching song found in top 50.")));
           }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No results found on iTunes.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching audio: $e")));
    } finally {
      setState(() => _isFetchingAudio = false);
    }
  }

  void _updateLink(String url, String message, {String? year}) {
    setState(() {
      _linkController.text = url;
      if (year != null && _yearController.text.isEmpty) {
        _yearController.text = year;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveChanges() async {
    if (_songs.isEmpty && !_isAddingNew) return;

    final updatedSong = Song(
      id: _isAddingNew 
          ? "new_${_artistController.text.toLowerCase().replaceAll(' ', '')}_${_titleController.text.toLowerCase().replaceAll(' ', '')}"
          : _songs[_currentIndex].id,
      title: _titleController.text,
      artist: _artistController.text,
      titleAr: _titleArController.text.isEmpty ? null : _titleArController.text,
      artistAr: _artistArController.text.isEmpty ? null : _artistArController.text,
      year: _yearController.text,
      link: _linkController.text,
      styles: _isAddingNew ? ['Pop'] : _songs[_currentIndex].styles,
       artworkUrl: _artworkController.text.isEmpty ? null : _artworkController.text,
      facts: _factsController.text.split('\n').where((s) => s.trim().isNotEmpty).toList(),
      gender: _genderController.text.isEmpty ? null : _genderController.text,
    );

    final indexToSave = _currentIndex;
    if (_isAddingNew) {
      final success = await _service.addSong(_currentLibrary, updatedSong);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Song Added to Library!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green)
          );
          setState(() {
            _songs.add(updatedSong);
            _currentIndex = _songs.length - 1;
            _isAddingNew = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error: Could not add song to disk.", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red)
          );
        }
      }
    } else {
      // Update memory immediately so navigating back/forth sees changes even if disk is slow
      _songs[indexToSave] = updatedSong;
      final success = await _service.saveSong(_currentLibrary, updatedSong, index: indexToSave);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Song Saved & Verified!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green)
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error: Save failed (File might be locked).", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red)
          );
        }
      }
      setState(() {});
    }
  }

  Future<void> _deleteSong() async {
    if (_songs.isEmpty) return;
    
    final indexToDelete = _currentIndex;
    final song = _songs[indexToDelete];
    await _stopMusic();
    final success = await _service.deleteSong(_currentLibrary, song.link);
    
    if (success) {
      setState(() {
        _songs.removeAt(indexToDelete);
        if (_songs.isNotEmpty) {
          if (_currentIndex >= _songs.length) {
            _currentIndex = (_songs.length - 1).clamp(0, 9999);
          }
          _loadSongData(_songs[_currentIndex]);
        } else {
          _currentIndex = 0;
          _clearForm();
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Song Deleted", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red)
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Failed to delete from disk.", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red)
        );
      }
    }
  }

  void _nextSong() {
    if (_songs.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _songs.length;
      _loadSongData(_songs[_currentIndex]);
    });
     _playMusic(); // Auto play next
  }

  void _prevSong() {
    if (_songs.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex - 1 + _songs.length) % _songs.length;
      _loadSongData(_songs[_currentIndex]);
    });
    _playMusic();
  }
  
  void _clearForm() {
    _titleController.clear();
    _artistController.clear();
    _titleArController.clear();
    _artistArController.clear();
    _yearController.clear();
    _linkController.clear();
    _artworkController.clear();
    _factsController.clear();
    _genderController.clear();
  }

  void _startAddingNew() {
    setState(() {
      _isAddingNew = true;
      _clearForm();
      _stopMusic();
    });
  }

  void _cancelAddingNew() {
    setState(() {
      _isAddingNew = false;
      if (_songs.isNotEmpty) {
        _loadSongData(_songs[_currentIndex]);
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _titleController.dispose();
    _artistController.dispose();
    _titleArController.dispose();
    _artistArController.dispose();
    _yearController.dispose();
    _linkController.dispose();
    _artworkController.dispose();
    _factsController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => _PlaylistImportDialog(
        onImport: (songs) async {
          setState(() => _isLoading = true);
          final success = await _service.batchAddSongs(_currentLibrary, songs);
          await _loadLibrary();
          setState(() => _isLoading = false);
          if (mounted) {
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Successfully imported ${songs.length} songs!", style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green)
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Import Failed: File system error.", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red)
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _showJumpDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Jump to Song"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Enter song number (1-${_songs.length})",
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            final index = int.tryParse(value);
            if (index != null) Navigator.pop(context, index);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final index = int.tryParse(controller.text);
              if (index != null) Navigator.pop(context, index);
            },
            child: const Text("Go"),
          ),
        ],
      ),
    );

    if (result != null) {
      final index = result - 1; // Convert to 0-based index
      if (index >= 0 && index < _songs.length) {
        setState(() {
          _currentIndex = index;
          _loadSongData(_songs[_currentIndex]);
        });
        _playMusic();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid song number")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isArabic = _currentLibrary == 'arabic';
    
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: Text("Song Test & Verify", style: GoogleFonts.outfit()),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: InkWell(
                onTap: _showJumpDialog,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search, size: 16, color: Colors.white70),
                      const SizedBox(width: 8),
                      Text(
                        "${_currentIndex + 1} / ${_songs.length}", 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ElevatedButton.icon(
              onPressed: _showImportDialog,
              icon: const Icon(Icons.playlist_add, size: 18),
              label: const Text("IMPORT PLAYLIST"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _isAddingNew 
              ? IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.redAccent),
                  onPressed: _cancelAddingNew,
                  tooltip: "Cancel Adding",
                )
              : ElevatedButton.icon(
                  onPressed: _startAddingNew,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("NEW SONG"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Row(
            children: [
               // Left Panel: Art & Controls
               Expanded(
                 flex: 4,
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                      // Library Selector
                      ToggleButtons(
                        isSelected: [_currentLibrary == 'english', _currentLibrary == 'arabic'],
                        onPressed: (index) {
                          setState(() => _currentLibrary = index == 0 ? 'english' : 'arabic');
                          _loadLibrary();
                        },
                        borderRadius: BorderRadius.circular(10),
                        fillColor: Colors.blueAccent,
                        selectedColor: Colors.white,
                        color: Colors.grey,
                        children: const [
                           Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("ENGLISH")),
                           Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("ARABIC")),
                        ],
                      ),
                      const SizedBox(height: 30),
                      
                      // Artwork
                      Container(
                        width: 300, height: 300,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                          image: _artworkController.text.isNotEmpty 
                            ? DecorationImage(image: NetworkImage(_artworkController.text), fit: BoxFit.cover)
                            : null,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)]
                        ),
                        child: _artworkController.text.isEmpty 
                           ? const Center(child: Icon(Icons.music_note, size: 80, color: Colors.white24)) 
                           : null,
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Audio Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           IconButton(
                             icon: const Icon(Icons.skip_previous, size: 40, color: Colors.white),
                             onPressed: _prevSong,
                           ),
                           const SizedBox(width: 20),
                           IconButton(
                             icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle, size: 64, color: Colors.greenAccent),
                             onPressed: _isPlaying ? _stopMusic : _playMusic,
                           ),
                           const SizedBox(width: 20),
                           IconButton(
                             icon: const Icon(Icons.skip_next, size: 40, color: Colors.white),
                             onPressed: _nextSong,
                           ),
                        ],
                      )
                   ],
                 ),
               ),
               
               // Right Panel: Edit Form
               Expanded(
                 flex: 6,
                 child: Container(
                   padding: const EdgeInsets.all(30),
                   color: const Color(0xFF2D2D44),
                   child: ListView(
                     children: [
                        Text("Edit Meta Data", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white70)),
                        const SizedBox(height: 20),
                        
                        _buildField("Title (English)", _titleController),
                        _buildField("Artist (English)", _artistController),
                        
                        // NEW: Gender field with common options
                        Row(
                          children: [
                            Expanded(child: _buildField("Artist Gender (male/female/group)", _genderController)),
                            const SizedBox(width: 10),
                            Wrap(
                              spacing: 8,
                              children: ['male', 'female', 'group'].map((g) => ChoiceChip(
                                label: Text(g), 
                                selected: _genderController.text == g,
                                onSelected: (val) {
                                  if (val) setState(() => _genderController.text = g);
                                },
                              )).toList(),
                            )
                          ],
                        ),
                        
                        if (isArabic) ...[
                          _buildField("Title (Arabic)", _titleArController),
                          _buildField("Artist (Arabic)", _artistArController),
                        ],
                        _buildField("Release Year", _yearController),
                        
                        // Music Link Field with Fetch Button
                         Row(
                          children: [
                            Expanded(child: _buildField("Music Link (MP3/URL)", _linkController)),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 55,
                              child: ElevatedButton.icon(
                                onPressed: _isFetchingAudio ? null : _fetchAudioLink,
                                icon: _isFetchingAudio ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.music_note), 
                                label: const Text("FETCH AUDIO"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purpleAccent,
                                  foregroundColor: Colors.white
                                ),
                              ),
                            )
                          ],
                        ),
                        
                        // Artwork Field with Fetch Button
                        Row(
                          children: [
                            Expanded(child: _buildField("Artwork URL", _artworkController)),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 55,
                              child: ElevatedButton.icon(
                                onPressed: _isFetchingArt ? null : _fetchArtwork,
                                icon: _isFetchingArt ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.cloud_download), 
                                label: const Text("FETCH ART"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white
                                ),
                              ),
                            )
                          ],
                        ),
                        
                        _buildField("Song Facts / Trivia", _factsController),

                        const SizedBox(height: 40),
                        
                        // Action Buttons
                        Row(
                          children: [
                             Expanded(
                               child: ElevatedButton.icon(
                                 onPressed: _deleteSong,
                                 style: ElevatedButton.styleFrom(
                                   backgroundColor: Colors.redAccent,
                                   foregroundColor: Colors.white,
                                   padding: const EdgeInsets.all(20)
                                 ),
                                 icon: const Icon(Icons.delete),
                                 label: const Text("DELETE SONG"),
                               ),
                             ),
                             const SizedBox(width: 20),
                             Expanded(
                               child: ElevatedButton.icon(
                                 onPressed: _saveChanges,
                                 style: ElevatedButton.styleFrom(
                                   backgroundColor: Colors.green,
                                   foregroundColor: Colors.white,
                                   padding: const EdgeInsets.all(20)
                                 ),
                                 icon: const Icon(Icons.check_circle),
                                 label: Text(_isAddingNew ? "ADD TO LIBRARY" : "VERIFY & SAVE"),
                               ),
                             ),
                          ],
                        )
                     ],
                   ),
                 ),
               )
            ],
          ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Colors.black26,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

class _PlaylistImportDialog extends StatefulWidget {
  final Function(List<Song>) onImport;
  const _PlaylistImportDialog({required this.onImport});

  @override
  State<_PlaylistImportDialog> createState() => _PlaylistImportDialogState();
}

class _PlaylistImportDialogState extends State<_PlaylistImportDialog> {
  final TextEditingController _inputController = TextEditingController();
  List<Song> _parsedSongs = [];
  bool _isProcessing = false;
  bool _isSearching = false;
  int _searchCount = 0;

  void _parseText() {
    final text = _inputController.text;
    if (text.isEmpty) return;

    final lines = text.split('\n').map((l) => l.trim()).toList();
    List<Song> songs = [];
    int i = 0;
    while (i < lines.length) {
      if (lines[i].isEmpty || lines[i].length < 2) { i++; continue; }
      
      String line = lines[i];
      // Skip common YouTube noise
      if (line.contains("Premium") || line.contains("Subscribe") || line.contains("Music") || line.contains("Play across")) {
        i++; continue;
      }

      String title = line;
      String artist = (i + 1 < lines.length) ? lines[i + 1] : "";

      // Heuristic cleaning
      artist = artist.replaceAll(RegExp(r'\s?[\(\|].*?[\)\|\d].*'), '').trim();
      title = title.replaceAll(RegExp(r'\s?[\(\|].*?[\)\|\d].*'), '').trim();

      if (title.isNotEmpty && artist.isNotEmpty && !artist.contains(":") && !RegExp(r'^\d+$').hasMatch(artist)) {
        songs.add(Song(
          id: "yt_${DateTime.now().millisecondsSinceEpoch}_$i",
          title: title,
          artist: artist,
          year: "2020",
          link: "",
          styles: ["Pop"],
          facts: [],
        ));
        i += 2;
        // Skip metadata lines (album, duration, etc.) until we hit an empty line or potential next song
        while (i < lines.length && lines[i].isNotEmpty) {
           // If it looks like a potential next song (no colon, not a duration), stop skipping
           if (!lines[i].contains(":") && !RegExp(r'^\d+$').hasMatch(lines[i])) break;
           i++;
        }
      } else {
        i++;
      }
    }

    setState(() {
      _parsedSongs = songs;
      _isProcessing = false;
    });
  }

  Future<void> _fetchMetadataBatch() async {
    setState(() => _isSearching = true);
    _searchCount = 0;

    String cleanTerm(String s) {
      return s.toLowerCase()
        .replaceAll(RegExp(r'\s(ft\.?|feat\.?|starring|featuring)\s.*'), '') 
        .replaceAll(RegExp(r'\s?\(.*?\)\s?'), '') 
        .replaceAll(RegExp(r'[^\w\s]'), '') 
        .trim();
    }

    String cleanCmp(String s) {
      return s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    }

    for (int i = 0; i < _parsedSongs.length; i++) {
      if (_parsedSongs[i].link.isNotEmpty) continue; // Skip already found

      setState(() => _searchCount = i + 1);
      final song = _parsedSongs[i];
      
      final searchQueries = [
         "${cleanTerm(song.artist)} ${cleanTerm(song.title)}",
         "${song.artist} ${song.title}",
         cleanTerm(song.title), // Title fallback
      ];

      List<dynamic> results = [];
      for (final query in searchQueries) {
        if (query.trim().isEmpty) continue;
        try {
          final uri = Uri.https('itunes.apple.com', '/search', {
            'term': query,
            'limit': '20',
            'media': 'music',
            'entity': 'song'
          });
          final response = await http.get(uri);
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['resultCount'] > 0) {
              results = data['results'];
              break; 
            }
          }
        } catch (e) {
          print("Batch Search Item Error: $e");
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (results.isNotEmpty) {
        final targetArtist = cleanCmp(song.artist);
        final targetTitle = cleanCmp(song.title);

        var candidates = results.where((r) {
          final rArtist = cleanCmp(r['artistName'].toString());
          final rTrack = cleanCmp(r['trackName'].toString());
          bool artistMatch = rArtist.contains(targetArtist) || targetArtist.contains(rArtist);
          bool titleMatch = rTrack.contains(targetTitle) || targetTitle.contains(rTrack);
          return (artistMatch && titleMatch) || titleMatch; // Slightly looser for batch
        }).toList();

        if (candidates.isNotEmpty) {
          // Prefer non-remix
          candidates.sort((a, b) {
            final aName = a['trackName'].toString().toLowerCase();
            final bName = b['trackName'].toString().toLowerCase();
            final aIsRemix = aName.contains("remix") || aName.contains("live");
            final bIsRemix = bName.contains("remix") || bName.contains("live");
            if (aIsRemix && !bIsRemix) return 1;
            if (!aIsRemix && bIsRemix) return -1;
            return 0;
          });

          final m = candidates.first;
          final artworkUrl = m['artworkUrl100'] as String?;
          String? art;
          if (artworkUrl != null) {
            art = artworkUrl.replaceAll('100x100bb', '600x600bb');
          }
          
          final releaseDate = m['releaseDate']?.toString() ?? "";
          final year = releaseDate.length >= 4 ? releaseDate.substring(0, 4) : "2020";

          _parsedSongs[i] = Song(
            id: "yt_${m['trackId']}",
            title: song.title,
            artist: song.artist,
            year: year,
            link: m['previewUrl'] ?? "",
            artworkUrl: art,
            styles: ["Pop"],
            facts: [],
          );
        }
      }
      
      // Small delay between songs to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 100));
    }

    setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Import Playlist"),
      backgroundColor: const Color(0xFF2D2D44),
      titleTextStyle: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
      content: SizedBox(
        width: 800,
        height: 600,
        child: Column(
          children: [
            if (_parsedSongs.isEmpty) ...[
              const Text("Paste raw text from YouTube Music playlist below:", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 10),
              Expanded(
                child: TextField(
                  controller: _inputController,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: "Title\nArtist\nAlbum\nDuration\n...",
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => setState(() => _parseText()),
                child: const Text("PARSE TEXT"),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Parsed ${_parsedSongs.length} songs", style: const TextStyle(color: Colors.greenAccent)),
                  if (!_isSearching)
                    ElevatedButton.icon(
                      onPressed: _fetchMetadataBatch,
                      icon: const Icon(Icons.search),
                      label: const Text("FETCH METADATA ALL"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
                    ),
                ],
              ),
              if (_isSearching)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: LinearProgressIndicator(value: _searchCount / _parsedSongs.length),
                ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _parsedSongs.length,
                  itemBuilder: (context, index) {
                    final song = _parsedSongs[index];
                    final hasLink = song.link.isNotEmpty;
                    return ListTile(
                      leading: song.artworkUrl != null 
                        ? Image.network(song.artworkUrl!, width: 40)
                        : const Icon(Icons.music_note, color: Colors.white24),
                      title: Text(song.title, style: const TextStyle(color: Colors.white)),
                      subtitle: Text("${song.artist} (${song.year})", style: const TextStyle(color: Colors.white54)),
                      trailing: hasLink 
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.pending, color: Colors.orange),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => setState(() => _parsedSongs = []), child: const Text("BACK")),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isSearching ? null : () {
                      widget.onImport(_parsedSongs.where((s) => s.link.isNotEmpty).toList());
                      Navigator.pop(context);
                    },
                    child: const Text("IMPORT ALL VALID"),
                  ),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }
}
