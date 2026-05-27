import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_models.dart';
import '../models/leaderboard_entry.dart';

const _kTheme = 'meneerwit_theme';
const _kLeaderboard = 'meneerwit_leaderboard';
const _kLastSettings = 'meneerwit_settings';

/// App-wide persisted state: theme + leaderboard + last-used settings.
class AppState extends ChangeNotifier {
  AppState(this._prefs) {
    _loadTheme();
    _loadLeaderboard();
  }

  final SharedPreferences _prefs;

  static Future<AppState> create() async =>
      AppState(await SharedPreferences.getInstance());

  // ----- Theme -----
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void _loadTheme() {
    switch (_prefs.getString(_kTheme)) {
      case 'light':
        _themeMode = ThemeMode.light;
      case 'dark':
        _themeMode = ThemeMode.dark;
      default:
        _themeMode = ThemeMode.system;
    }
  }

  void cycleTheme() {
    _themeMode = switch (_themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    _prefs.setString(_kTheme, _themeMode.name);
    notifyListeners();
  }

  // ----- Leaderboard -----
  List<LeaderboardEntry> _leaderboard = [];
  List<LeaderboardEntry> get leaderboard => List.unmodifiable(_leaderboard);

  List<String> get knownPlayerNames =>
      _leaderboard.map((e) => e.name).toList();

  void _loadLeaderboard() {
    final raw = _prefs.getString(_kLeaderboard);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      _leaderboard = list
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      _sort();
    } catch (_) {
      _leaderboard = [];
    }
  }

  void _sort() => _leaderboard.sort((a, b) => b.score.compareTo(a.score));

  void _persistLeaderboard() {
    _prefs.setString(
      _kLeaderboard,
      jsonEncode(_leaderboard.map((e) => e.toJson()).toList()),
    );
  }

  LeaderboardEntry _entryFor(String name) {
    final existing = _leaderboard
        .where((e) => e.name.toLowerCase() == name.toLowerCase())
        .firstOrNull;
    if (existing != null) return existing;
    final created = LeaderboardEntry(name: name);
    _leaderboard.add(created);
    return created;
  }

  /// Awards points to all players of a finished game, mirroring the
  /// scoring used on meneerwit.com.
  void recordGame({
    required List<Player> players,
    required Winner winner,
    required bool misterWhiteGuessWin,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final p in players) {
      final entry = _entryFor(p.name);
      entry.gamesPlayed += 1;
      entry.lastPlayed = now;
      switch (p.role) {
        case Role.burger:
          entry.burgerGames += 1;
        case Role.undercover:
          entry.undercoverGames += 1;
        case Role.misterWhite:
          entry.misterWhiteGames += 1;
      }

      var points = 0;
      var won = false;
      switch (winner) {
        case Winner.burgers:
          if (p.role == Role.burger) {
            won = true;
            points = 2;
          }
        case Winner.infiltrators:
          if (p.role == Role.undercover) {
            won = true;
            points = 10;
          } else if (p.role == Role.misterWhite) {
            won = true;
            points = 6;
          }
        case Winner.misterWhite:
          if (p.role == Role.misterWhite) {
            won = true;
            points = 6;
          }
      }
      if (won) entry.wins += 1;
      entry.score += points;
      if (misterWhiteGuessWin && p.role == Role.misterWhite) {
        entry.misterWhiteGuessWins += 1;
      }
    }
    _sort();
    _persistLeaderboard();
    notifyListeners();
  }

  void clearLeaderboard() {
    _leaderboard = [];
    _prefs.remove(_kLeaderboard);
    notifyListeners();
  }

  // ----- Last-used settings -----
  GameSettings loadSettings() {
    final raw = _prefs.getString(_kLastSettings);
    if (raw == null) return GameSettings();
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return GameSettings(
        undercoverCount: (j['undercoverCount'] as num?)?.toInt() ?? 1,
        mrWhiteCount: (j['mrWhiteCount'] as num?)?.toInt() ?? 0,
        misterWhiteHintEnabled: j['misterWhiteHintEnabled'] as bool? ?? false,
        category: j['category'] as String? ?? 'Algemeen',
      );
    } catch (_) {
      return GameSettings();
    }
  }

  void saveSettings(GameSettings s) {
    _prefs.setString(
      _kLastSettings,
      jsonEncode({
        'undercoverCount': s.undercoverCount,
        'mrWhiteCount': s.mrWhiteCount,
        'misterWhiteHintEnabled': s.misterWhiteHintEnabled,
        'category': s.category,
      }),
    );
  }
}
