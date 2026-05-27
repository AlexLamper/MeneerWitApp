import 'package:flutter_test/flutter_test.dart';
import 'package:meneer_wit/data/word_repository.dart';
import 'package:meneer_wit/game/game_controller.dart';
import 'package:meneer_wit/models/game_models.dart';
import 'package:meneer_wit/storage/app_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppState appState;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    appState = await AppState.create();
  });

  GameController newGame(int n, {int undercover = 1, int mrWhite = 0}) {
    final g = GameController(appState);
    g.startGame(
      names: [for (var i = 0; i < n; i++) 'P$i'],
      gameSettings: GameSettings(
        undercoverCount: undercover,
        mrWhiteCount: mrWhite,
        useCustomWords: true,
      ),
      custom: const [WordPair('appel', 'peer')],
    );
    return g;
  }

  test('assigns the requested role counts and words', () {
    final g = newGame(5, undercover: 1, mrWhite: 1);
    expect(g.players.where((p) => p.role == Role.undercover).length, 1);
    expect(g.players.where((p) => p.role == Role.misterWhite).length, 1);
    expect(g.players.where((p) => p.role == Role.burger).length, 3);
    for (final p in g.players) {
      switch (p.role) {
        case Role.burger:
          expect(p.word, 'appel');
        case Role.undercover:
          expect(p.word, 'peer');
        case Role.misterWhite:
          expect(p.word, isNull);
      }
    }
  });

  test('burgers win once all infiltrators are eliminated', () {
    final g = newGame(4, undercover: 1);
    g.players[0].role = Role.undercover;
    for (var i = 1; i < 4; i++) {
      g.players[i].role = Role.burger;
    }
    g.eliminate(g.players[0]);
    g.resolveAfterElimination();
    expect(g.winner, Winner.burgers);
  });

  test('infiltrators win at parity (one burger left)', () {
    final g = newGame(4, undercover: 1);
    g.players[0].role = Role.undercover;
    for (var i = 1; i < 4; i++) {
      g.players[i].role = Role.burger;
    }
    g.eliminate(g.players[1]);
    g.resolveAfterElimination();
    expect(g.winner, isNull);
    g.eliminate(g.players[2]);
    g.resolveAfterElimination();
    expect(g.winner, Winner.infiltrators);
  });

  test('mister white wins by guessing the burger word (case-insensitive)', () {
    final g = newGame(4, undercover: 0, mrWhite: 1);
    g.players[0].role = Role.misterWhite;
    for (var i = 1; i < 4; i++) {
      g.players[i].role = Role.burger;
    }
    g.eliminate(g.players[0]);
    expect(g.phase, GamePhase.mrWhiteGuess);
    g.submitMisterWhiteGuess('  Appel ');
    expect(g.winner, Winner.misterWhite);
  });

  test('wrong mister white guess eliminates him and burgers win', () {
    final g = newGame(4, undercover: 0, mrWhite: 1);
    g.players[0].role = Role.misterWhite;
    for (var i = 1; i < 4; i++) {
      g.players[i].role = Role.burger;
    }
    g.eliminate(g.players[0]);
    g.submitMisterWhiteGuess('banaan');
    expect(g.mrWhiteGuessedWrong, true);
    expect(g.phase, GamePhase.eliminationReveal);
    g.resolveAfterElimination();
    expect(g.winner, Winner.burgers);
  });

  test('scoring matches the web version', () {
    final g = newGame(4, undercover: 1);
    g.players[0].role = Role.undercover;
    for (var i = 1; i < 4; i++) {
      g.players[i].role = Role.burger;
    }
    g.eliminate(g.players[0]);
    g.resolveAfterElimination(); // Burgers win

    final burger = appState.leaderboard.firstWhere((e) => e.name == 'P1');
    expect(burger.score, 2);
    expect(burger.wins, 1);
    expect(burger.gamesPlayed, 1);
    final undercover = appState.leaderboard.firstWhere((e) => e.name == 'P0');
    expect(undercover.score, 0);
  });

  test('settings validation requires 2 burgers and an infiltrator', () {
    expect(GameSettings(undercoverCount: 0, mrWhiteCount: 0).validate(4),
        isNotNull);
    expect(GameSettings(undercoverCount: 3, mrWhiteCount: 0).validate(4),
        isNotNull);
    expect(GameSettings(undercoverCount: 1, mrWhiteCount: 0).validate(4),
        isNull);
  });

  test('bundled word list loads fully', () async {
    await WordRepository.instance.load();
    expect(WordRepository.instance.categories.length, 24);
    expect(WordRepository.instance.totalPairs, 1619);
  });
}
