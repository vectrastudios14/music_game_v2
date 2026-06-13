import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:math';class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final String _baseUrl = "https://tug-of-war-quiz-3b5c2-default-rtdb.europe-west1.firebasedatabase.app";

  // Generate a random 4-digit room code
  String generateRoomCode() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString();
  }

  // --- HOST METHODS ---

  Future<void> createRoom(String roomCode) async {
    final Map<String, dynamic> data = {
      'status': 'waiting',
      'buzzedTeam': null,
      'buzzedPlayerName': null,
    };
    if (kIsWeb) {
      try {
        data['createdAt'] = ServerValue.timestamp;
        await _db.child('gts_rooms/$roomCode').set(data);
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode.json");
        await http.put(url, body: jsonEncode(data));
      } catch (e) {
        debugPrint("GTS createRoom error: $e");
      }
    }
  }

  Future<void> updateTeamNames(String roomCode, List<String> teamNames) async {
    final Map<String, dynamic> names = {
      'teamCount': teamNames.length,
    };
    for (int i = 0; i < teamNames.length; i++) {
      names['team${i + 1}Name'] = teamNames[i];
    }
    // Clear unused team names in Firebase
    for (int i = teamNames.length; i < 4; i++) {
      names['team${i + 1}Name'] = "";
    }
    
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode').update(names);
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode.json");
        await http.patch(url, body: jsonEncode(names));
      } catch (e) {
        debugPrint("GTS updateTeamNames error: $e");
      }
    }
  }

  Stream<Map<String, dynamic>> listenToRoomCustom(String roomCode) {
    if (kIsWeb) {
      return _db.child('gts_rooms/$roomCode').onValue.map((event) {
        if (event.snapshot.value != null) {
          return Map<String, dynamic>.from(event.snapshot.value as Map);
        }
        return {};
      });
    } else {
      StreamController<Map<String, dynamic>> controller = StreamController<Map<String, dynamic>>.broadcast();
      Timer.periodic(const Duration(milliseconds: 500), (timer) async {
        if (!controller.hasListener) {
          timer.cancel();
          return;
        }
        try {
          final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode.json");
          final response = await http.get(url);
          if (response.statusCode == 200 && response.body != "null") {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            controller.add(data);
          }
        } catch (e) {}
      });
      return controller.stream;
    }
  }

  Future<void> resetBuzzer(String roomCode) async {
    final data = {
      'status': 'waiting',
      'buzzedTeam': null,
      'buzzedPlayerName': null,
    };
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode').update(data);
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode.json");
        await http.patch(url, body: jsonEncode(data));
      } catch (e) {
        debugPrint("GTS resetBuzzer error: $e");
      }
    }
  }
  
  Future<void> startGame(String roomCode) async {
    final data = {
      'status': 'playing',
      'choicesVisible': false,
    };
    if (kIsWeb) {
      await _db.child('gts_rooms/$roomCode').update(data);
    } else {
      final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode.json");
      await http.patch(url, body: jsonEncode(data));
    }
  }

  Future<void> showChoices(String roomCode, {int? basePoints}) async {
    final data = <String, dynamic>{'choicesVisible': true};
    if (basePoints != null) {
      data['basePoints'] = basePoints;
    }
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode').update(data);
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode.json");
        await http.patch(url, body: jsonEncode(data));
      } catch (e) {
        debugPrint("GTS showChoices error: $e");
      }
    }
  }
  Timer? _joinsTimer;
  final Set<String> _processedJoins = {};

  void listenForJoins(String roomCode, Function(String name, String team) onJoin) {
    _joinsTimer?.cancel();
    _processedJoins.clear();
    
    if (kIsWeb) {
      _db.child('gts_rooms/$roomCode/players').onChildAdded.listen((event) {
        if (event.snapshot.value != null) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          onJoin(data['name'], data['team']);
        }
      });
    } else {
      _joinsTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        try {
          final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode/players.json");
          final response = await http.get(url);
          if (response.statusCode == 200 && response.body != "null") {
            final Map<String, dynamic> players = jsonDecode(response.body);
            debugPrint("GTS listenForJoins received: ${players.keys.length} players");
            players.forEach((key, value) {
              if (value is Map && !_processedJoins.contains(key)) {
                _processedJoins.add(key);
                debugPrint("GTS listenForJoins processing new player: ${value['name']} on team ${value['team']}");
                onJoin(value['name'], value['team']);
              }
            });
          }
        } catch (e) {
          debugPrint("GTS listenForJoins error: $e");
        }
      });
    }
  }

  void stopListeningForJoins() {
    _joinsTimer?.cancel();
  }

  Future<void> kickPlayer(String roomCode, String playerName) async {
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode/kicked_players/$playerName').set(true);
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode/kicked_players/$playerName.json");
        await http.put(url, body: jsonEncode(true));
      } catch (e) {
        debugPrint("GTS kickPlayer error: $e");
      }
    }
  }

  Future<void> pushOptions(String roomCode, List<Map<String, dynamic>> options) async {
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode/options').set(options);
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode/options.json");
        await http.put(url, body: jsonEncode(options));
      } catch (e) {
        debugPrint("GTS pushOptions error: $e");
      }
    }
  }

  Future<void> clearOptions(String roomCode) async {
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode/options').remove();
        await _db.child('gts_rooms/$roomCode/selectedOptionInfo').remove();
        await _db.child('gts_rooms/$roomCode/selectedOptionId').remove();
      } catch (e) {}
    } else {
      try {
        final optionsUrl = Uri.parse("$_baseUrl/gts_rooms/$roomCode/options.json");
        await http.delete(optionsUrl);
        final selectedUrl = Uri.parse("$_baseUrl/gts_rooms/$roomCode/selectedOptionInfo.json");
        await http.delete(selectedUrl);
        final selectedIdUrl = Uri.parse("$_baseUrl/gts_rooms/$roomCode/selectedOptionId.json");
        await http.delete(selectedIdUrl);
      } catch (e) {
        debugPrint("GTS clearOptions error: $e");
      }
    }
  }

  Future<void> setRoomStartingPoints(String roomCode, int points) async {
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode/startingPoints').set(points);
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode/startingPoints.json");
        await http.put(url, body: jsonEncode(points));
      } catch (e) {}
    }
  }

  Future<void> joinRoom(String roomCode, String playerName, String teamName) async {
    // Just a placeholder if we want to track players later
    await _db.child('gts_rooms/$roomCode/players').push().set({
      'name': playerName,
      'team': teamName,
    });
  }

  Future<bool> pressBuzzer(String roomCode, String playerName, String teamName) async {
    final ref = _db.child('gts_rooms/$roomCode');
    
    // We use a transaction to ensure only the first person to press gets it
    final TransactionResult result = await ref.runTransaction((Object? post) {
      if (post == null) {
        return Transaction.abort();
      }

      Map<String, dynamic> roomData = Map<String, dynamic>.from(post as Map);
      
      if (roomData['status'] == 'playing') {
        roomData['status'] = 'buzzed';
        roomData['buzzedTeam'] = teamName;
        roomData['buzzedPlayerName'] = playerName;
        return Transaction.success(roomData);
      }

      return Transaction.abort();
    });

    return result.committed;
  }

  Future<void> submitAnswer(String roomCode, String optionId, String playerName) async {
    final data = {
      'id': optionId,
      'playerName': playerName,
    };
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode/selectedOptionInfo').set(data);
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode/selectedOptionInfo.json");
        await http.put(url, body: jsonEncode(data));
      } catch (e) {
        debugPrint("GTS submitAnswer error: $e");
      }
    }
  }

  Future<void> requestNextRound(String roomCode) async {
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode/nextRoundRequested').set(true);
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode/nextRoundRequested.json");
        await http.put(url, body: 'true');
      } catch (e) {
        debugPrint("GTS requestNextRound error: $e");
      }
    }
  }

  Future<void> resetNextRoundRequest(String roomCode) async {
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode/nextRoundRequested').remove();
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode/nextRoundRequested.json");
        await http.delete(url);
      } catch (e) {}
    }
  }

  Future<void> triggerTsReveal(String roomCode) async {
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode/triggerReveal').set(true);
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode/triggerReveal.json");
        await http.put(url, body: jsonEncode(true));
      } catch (e) {}
    }
  }

  Future<void> resetTsRevealTrigger(String roomCode) async {
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode/triggerReveal').remove();
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode/triggerReveal.json");
        await http.delete(url);
      } catch (e) {}
    }
  }

  Future<void> triggerTsShowResults(String roomCode) async {
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode/triggerShowResults').set(true);
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode/triggerShowResults.json");
        await http.put(url, body: jsonEncode(true));
      } catch (e) {}
    }
  }

  Future<void> resetTsShowResultsTrigger(String roomCode) async {
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode/triggerShowResults').remove();
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode/triggerShowResults.json");
        await http.delete(url);
      } catch (e) {}
    }
  }

  Future<void> setPauseState(String roomCode, bool isPaused, String playerName) async {
    final data = {
      'isPaused': isPaused,
      'pausedBy': isPaused ? playerName : null,
    };
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode/pauseState').set(data);
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode/pauseState.json");
        await http.put(url, body: jsonEncode(data));
      } catch (e) {
        debugPrint("GTS setPauseState error: $e");
      }
    }
  }

  Future<void> clearPauseState(String roomCode) async {
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode/pauseState').remove();
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode/pauseState.json");
        await http.delete(url);
      } catch (e) {}
    }
  }

  Future<void> voteToSkip(String roomCode, String teamName, String playerName) async {
    final data = {
      'playerName': playerName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode/skipVotes/$teamName').set(data);
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode/skipVotes/$teamName.json");
        await http.put(url, body: jsonEncode(data));
      } catch (e) {
        debugPrint("GTS voteToSkip error: $e");
      }
    }
  }

  Future<void> clearSkipVotes(String roomCode) async {
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode/skipVotes').remove();
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode/skipVotes.json");
        await http.delete(url);
      } catch (e) {}
    }
  }

  Future<void> removeSkipVote(String roomCode, String teamName) async {
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode/skipVotes/$teamName').remove();
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode/skipVotes/$teamName.json");
        await http.delete(url);
      } catch (e) {}
    }
  }

  Future<void> setRoundFinished(String roomCode) async {
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode').update({
          'status': 'round_finished',
          'choicesVisible': true,
        });
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode.json");
        await http.patch(url, body: jsonEncode({
          'status': 'round_finished',
          'choicesVisible': true,
        }));
      } catch (e) {}
    }
  }

  Future<void> setRoomMode(String roomCode, String mode) async {
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode').update({
          'mode': mode,
        });
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode.json");
        await http.patch(url, body: jsonEncode({
          'mode': mode,
        }));
      } catch (e) {}
    }
  }

  Future<void> setIndividualActivePlayer(String roomCode, String activePlayer, {String? nextPlayer}) async {
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode').update({
          'choicesVisible': true,
          'activePlayer': activePlayer,
          'nextPlayer': nextPlayer,
          'status': 'playing',
        });
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode.json");
        await http.patch(url, body: jsonEncode({
          'choicesVisible': true,
          'activePlayer': activePlayer,
          'nextPlayer': nextPlayer,
          'status': 'playing',
        }));
      } catch (e) {}
    }
  }

  Future<void> setWaitingForReady(String roomCode, bool isWaiting) async {
    final data = {
      'isWaitingForReady': isWaiting,
      if (isWaiting) 'startTurnRequested': false,
    };
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode').update(data);
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode.json");
        await http.patch(url, body: jsonEncode(data));
      } catch (e) {}
    }
  }

  Future<void> requestStartTurn(String roomCode) async {
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode').update({
          'startTurnRequested': true,
        });
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode.json");
        await http.patch(url, body: jsonEncode({
          'startTurnRequested': true,
        }));
      } catch (e) {}
    }
  }

  Future<void> requestHint(String roomCode) async {
    final data = {'hintRequested': true};
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode').update(data);
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode.json");
        await http.patch(url, body: jsonEncode(data));
      } catch (e) {}
    }
  }

  Future<void> resetHintRequest(String roomCode) async {
    final data = {'hintRequested': false};
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode').update(data);
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode.json");
        await http.patch(url, body: jsonEncode(data));
      } catch (e) {}
    }
  }

  Future<void> setHintsUsed(String roomCode, int hintsUsed) async {
    final data = {'hintsUsed': hintsUsed};
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode').update(data);
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode.json");
        await http.patch(url, body: jsonEncode(data));
      } catch (e) {}
    }
  }

  Future<void> setGameType(String roomCode, String gameType) async {
    final data = {'gameType': gameType};
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode').update(data);
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode.json");
        await http.patch(url, body: jsonEncode(data));
      } catch (e) {}
    }
  }

  Future<void> submitBoaChoice(String roomCode, int slotIndex, String playerName) async {
    final data = {
      'selectedSlot': slotIndex,
      'playerName': playerName,
      'choiceTimestamp': DateTime.now().millisecondsSinceEpoch,
    };
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode/boaChoice').set(data);
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode/boaChoice.json");
        await http.put(url, body: jsonEncode(data));
      } catch (e) {}
    }
  }

  Future<void> clearBoaChoice(String roomCode) async {
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode/boaChoice').remove();
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode/boaChoice.json");
        await http.delete(url);
      } catch (e) {}
    }
  }

  Future<void> updateBoaState(String roomCode, {
    required String activePlayer,
    required Map<String, dynamic> mysterySong,
    required List<Map<String, dynamic>> timelineSongs,
    String? status,
    String? placementResult,
    bool? choicesVisible,
    int? currentSlotIndex,
  }) async {
    final Map<String, dynamic> data = {
      'activePlayer': activePlayer,
      'mysterySong': mysterySong,
      'timelineSongs': timelineSongs,
      if (status != null) 'status': status,
      'placementResult': placementResult,
      if (choicesVisible != null) 'choicesVisible': choicesVisible,
      if (currentSlotIndex != null) 'currentSlotIndex': currentSlotIndex,
    };
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode').update(data);
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode.json");
        await http.patch(url, body: jsonEncode(data));
      } catch (e) {}
    }
  }

  Future<void> updateBoaScrollPosition(String roomCode, int slotIndex) async {
    final data = {'currentSlotIndex': slotIndex};
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode').update(data);
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode.json");
        await http.patch(url, body: jsonEncode(data));
      } catch (e) {}
    }
  }

  Future<void> submitTsGuess(String roomCode, String playerName, int year) async {
    final data = {
      'year': year,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode/tsGuesses/$playerName').set(data);
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode/tsGuesses/$playerName.json");
        await http.put(url, body: jsonEncode(data));
      } catch (e) {}
    }
  }

  Future<void> clearTsGuesses(String roomCode) async {
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode/tsGuesses').remove();
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode/tsGuesses.json");
        await http.delete(url);
      } catch (e) {}
    }
  }

  Future<void> removePlayerTsGuess(String roomCode, String playerName) async {
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode/tsGuesses/$playerName').remove();
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode/tsGuesses/$playerName.json");
        await http.delete(url);
      } catch (e) {}
    }
  }

  Future<void> removePlayerFromRoom(String roomCode, String playerName) async {
    if (kIsWeb) {
      try {
        final snapshot = await _db.child('gts_rooms/$roomCode/players').get();
        if (snapshot.exists && snapshot.value != null) {
          final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
          data.forEach((key, val) async {
            final playerVal = Map<dynamic, dynamic>.from(val as Map);
            if (playerVal['name'] == playerName) {
              await _db.child('gts_rooms/$roomCode/players/$key').remove();
            }
          });
        }
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode/players.json");
        final response = await http.get(url);
        if (response.statusCode == 200 && response.body != 'null') {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          data.forEach((key, val) async {
            final playerVal = Map<String, dynamic>.from(val as Map);
            if (playerVal['name'] == playerName) {
              final deleteUrl = Uri.parse("$_baseUrl/gts_rooms/$roomCode/players/$key.json");
              await http.delete(deleteUrl);
            }
          });
        }
      } catch (e) {}
    }
  }

  Future<void> updateTsRoomState(String roomCode, {
    required List<String> playerNames,
    required Map<String, int> scores,
    Map<String, dynamic>? currentSong,
    String? status,
    bool? isRoundResultShowing,
    bool? isWaitingForReady,
    String? roundLoserName,
    int? actualYear,
    bool? showScoreOverlay,
  }) async {
    final data = {
      'playerNames': playerNames,
      'scores': scores,
      if (currentSong != null) 'currentSong': currentSong,
      if (status != null) 'status': status,
      if (isRoundResultShowing != null) 'isRoundResultShowing': isRoundResultShowing,
      if (isWaitingForReady != null) 'isWaitingForReady': isWaitingForReady,
      if (roundLoserName != null) 'roundLoserName': roundLoserName,
      if (actualYear != null) 'actualYear': actualYear,
      if (showScoreOverlay != null) 'showScoreOverlay': showScoreOverlay,
    };
    if (kIsWeb) {
      try {
        await _db.child('gts_rooms/$roomCode').update(data);
      } catch (e) {}
    } else {
      try {
        final url = Uri.parse("$_baseUrl/gts_rooms/$roomCode.json");
        await http.patch(url, body: jsonEncode(data));
      } catch (e) {}
    }
  }
}

