import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/word_repository.dart';
import 'game/game_controller.dart';
import 'models/game_models.dart';
import 'screens/game_screen.dart';
import 'screens/home_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'storage/app_storage.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );
  await WordRepository.instance.load();

  // Screenshot mode (web only): `?shot=<name>` renders one screen with demo
  // data so store screenshots can be captured headlessly. See
  // store_screenshots/shoot.mjs.
  final shot = kIsWeb ? Uri.base.queryParameters['shot'] : null;
  if (shot == 'leaderboard') await _seedLeaderboard();

  final appState = await AppState.create();
  final controller = GameController(appState);
  final home = _homeFor(shot, controller);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appState),
        ChangeNotifierProvider.value(value: controller),
      ],
      child: MeneerWitApp(home: home),
    ),
  );
}

/// Puts the app straight into the requested screenshot state, or returns the
/// normal home screen when not in screenshot mode.
Widget _homeFor(String? shot, GameController controller) {
  switch (shot) {
    case 'reveal':
    case 'hint':
    case 'vote':
    case 'gameover':
      controller.startGame(
        names: ['Milan', 'Daan', 'Emma', 'Lucas', 'Noa', 'Bram', 'Julia'],
        gameSettings: GameSettings(
          undercoverCount: 1,
          mrWhiteCount: 1,
          useCustomWords: true,
        ),
        custom: const [WordPair('Pizza', 'Pasta')],
      );
      if (shot == 'hint') controller.phase = GamePhase.hintRound;
      if (shot == 'vote') controller.startVoting();
      if (shot == 'gameover') {
        controller.winner = Winner.burgers;
        controller.phase = GamePhase.gameOver;
      }
      return const GameScreen();
    case 'leaderboard':
      return const LeaderboardScreen();
    default:
      return const HomeScreen();
  }
}

/// Fills the persisted leaderboard with demo entries for screenshots.
Future<void> _seedLeaderboard() async {
  const demo = [
    ['Milan', 48, 9, 14],
    ['Daan', 36, 6, 13],
    ['Emma', 30, 5, 12],
    ['Lucas', 22, 4, 11],
    ['Noa', 16, 3, 10],
    ['Bram', 12, 2, 9],
    ['Julia', 8, 1, 8],
  ];
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    'meneerwit_leaderboard',
    jsonEncode([
      for (final [name, score, wins, played] in demo)
        {
          'name': name,
          'score': score,
          'wins': wins,
          'gamesPlayed': played,
          'lastPlayed': 0,
          'roleStats': {'burger': played, 'undercover': 0, 'misterWhite': 0},
          'misterWhiteGuessWins': 0,
        },
    ]),
  );
}

class MeneerWitApp extends StatelessWidget {
  const MeneerWitApp({super.key, this.home = const HomeScreen()});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<AppState, ThemeMode>((s) => s.themeMode);
    return MaterialApp(
      title: 'Meneer Wit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: home,
    );
  }
}
