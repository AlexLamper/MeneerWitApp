import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/word_repository.dart';
import '../models/game_models.dart';
import '../storage/app_storage.dart';

/// Drives a single game of Meneer Wit through its phases, mirroring the
/// rules and scoring of meneerwit.com.
class GameController extends ChangeNotifier {
  GameController(this._appState);

  final AppState _appState;
  final _rng = Random();

  // ----- Game state -----
  List<Player> players = [];
  GameSettings settings = GameSettings();
  List<WordPair> customWords = [];

  WordPair _wordPair = const WordPair('', '');
  WordPair get wordPair => _wordPair;

  String _categoryLabel = 'Algemeen';
  String get categoryLabel => _categoryLabel;

  GamePhase phase = GamePhase.cardReveal;
  Winner? winner;

  int _startingPlayerId = 0;

  /// Indexes into [players] that still need to see their card, in order.
  /// Eliminated players are skipped when cards are re-dealt mid-game.
  List<int> _revealQueue = [];
  int _revealStep = 0;

  /// Position in the current reveal queue (0-based); used as a widget key.
  int get revealIndex => _revealStep;
  int get revealTotal => _revealQueue.length;

  Player? lastEliminated;
  bool mrWhiteGuessedWrong = false;
  String mrWhiteGuessAttempt = '';
  int round = 1;

  // ----- Derived -----
  List<Player> get alivePlayers =>
      players.where((p) => !p.isEliminated).toList();

  String? get misterWhiteHint =>
      settings.misterWhiteHintEnabled ? 'Categorie: $_categoryLabel' : null;

  Player get currentRevealPlayer => players[_revealQueue[_revealStep]];
  bool get isLastReveal => _revealStep >= _revealQueue.length - 1;

  /// Players ordered for the hint round: the starting player first, then by id.
  List<Player> get hintOrder {
    final alive = alivePlayers..sort((a, b) => a.id.compareTo(b.id));
    final start = alive.indexWhere((p) => p.id == _startingPlayerId);
    if (start <= 0) return alive;
    return [...alive.sublist(start), ...alive.sublist(0, start)];
  }

  Player? get startingPlayer =>
      alivePlayers.where((p) => p.id == _startingPlayerId).firstOrNull;

  // ----- Setup -----
  void startGame({
    required List<String> names,
    required GameSettings gameSettings,
    List<WordPair> custom = const [],
  }) {
    players = [
      for (var i = 0; i < names.length; i++) Player(id: i, name: names[i]),
    ];
    settings = gameSettings;
    customWords = custom;
    round = 1;
    _assignRolesAndWord();
    _enterCardReveal();
  }

  /// Configure a game where names are entered one-by-one during the
  /// pass-and-play card reveal (mirrors meneerwit.com). Roles and the word are
  /// assigned up front; players start with placeholder names.
  void configureGame({
    required int count,
    required GameSettings gameSettings,
    List<WordPair> custom = const [],
  }) {
    players = [
      for (var i = 0; i < count; i++) Player(id: i, name: 'Speler ${i + 1}'),
    ];
    settings = gameSettings;
    customWords = custom;
    round = 1;
    _assignRolesAndWord();
    _enterCardReveal();
  }

  /// Whether the player currently revealing still uses a placeholder name.
  bool get currentNameIsPlaceholder =>
      currentRevealPlayer.name == 'Speler ${currentRevealPlayer.id + 1}';

  /// Whether [name] is already taken by another player in this game.
  bool isNameTaken(String name) {
    final n = name.trim().toLowerCase();
    if (n.isEmpty) return false;
    final current = currentRevealPlayer;
    return players.any((p) => p != current && p.name.toLowerCase() == n);
  }

  /// Store the name entered by the player currently revealing their card.
  void setCurrentRevealName(String name) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) currentRevealPlayer.name = trimmed;
    notifyListeners();
  }

  /// Replace everyone's word, keeping the same roles (the "Woorden" action in
  /// the describe phase), then pass the phone round again so every player
  /// still in the game sees their new word.
  void regenerateWord() {
    _wordPair = _pickWordPair();
    _dealWords();
    _enterCardReveal(onlyAlive: true);
  }

  /// Add a player mid-game as a Burger with the current word. Returns the new
  /// player so the UI can show their card.
  Player addPlayerMidGame(String name) {
    final p = Player(
      id: players.length,
      name: name.trim().isEmpty ? 'Speler ${players.length + 1}' : name.trim(),
    );
    p.role = Role.burger;
    p.word = _wordPair.burger;
    p.isEliminated = false;
    players.add(p);
    notifyListeners();
    return p;
  }

  void _assignRolesAndWord() {
    // Roles
    final shuffled = [...players]..shuffle(_rng);
    for (final p in shuffled) {
      p.role = Role.burger;
      p.isEliminated = false;
      p.votes = 0;
    }
    var idx = 0;
    for (var i = 0; i < settings.undercoverCount && idx < shuffled.length; i++) {
      shuffled[idx++].role = Role.undercover;
    }
    for (var i = 0; i < settings.mrWhiteCount && idx < shuffled.length; i++) {
      shuffled[idx++].role = Role.misterWhite;
    }

    // Word
    _categoryLabel =
        settings.useCustomWords ? 'Eigen woorden' : settings.category;
    _wordPair = _pickWordPair();
    _dealWords();
    _startingPlayerId = _pickStarter();
  }

  WordPair _pickWordPair() {
    final pool = settings.useCustomWords && customWords.isNotEmpty
        ? customWords
        : WordRepository.instance.pairsFor(settings.category);
    if (pool.isEmpty) return const WordPair('Appel', 'Peer');
    // Avoid dealing the exact same pair twice in a row when possible.
    if (pool.length > 1) {
      var next = pool[_rng.nextInt(pool.length)];
      for (var tries = 0;
          tries < 8 &&
              next.burger == _wordPair.burger &&
              next.undercover == _wordPair.undercover;
          tries++) {
        next = pool[_rng.nextInt(pool.length)];
      }
      return next;
    }
    return pool.first;
  }

  void _dealWords() {
    for (final p in players) {
      p.word = switch (p.role) {
        Role.burger => _wordPair.burger,
        Role.undercover => _wordPair.undercover,
        Role.misterWhite => null,
      };
    }
  }

  /// A random starting player who is not Mister White (he would have nothing
  /// to go on), falling back to anyone if only Mister Whites remain.
  int _pickStarter() {
    final candidates =
        alivePlayers.where((p) => p.role != Role.misterWhite).toList();
    final pool = candidates.isEmpty ? alivePlayers : candidates;
    return pool[_rng.nextInt(pool.length)].id;
  }

  void _enterCardReveal({bool onlyAlive = false}) {
    phase = GamePhase.cardReveal;
    winner = null;
    lastEliminated = null;
    mrWhiteGuessedWrong = false;
    mrWhiteGuessAttempt = '';
    _revealQueue = [
      for (var i = 0; i < players.length; i++)
        if (!onlyAlive || !players[i].isEliminated) i,
    ];
    _revealStep = 0;
    notifyListeners();
  }

  // ----- Card reveal -----
  void nextReveal() {
    if (_revealStep < _revealQueue.length - 1) {
      _revealStep++;
      notifyListeners();
    } else {
      phase = GamePhase.hintRound;
      notifyListeners();
    }
  }

  // ----- Hint round -> voting -----
  void startVoting() {
    for (final p in players) {
      p.votes = 0;
    }
    phase = GamePhase.voting;
    notifyListeners();
  }

  // ----- Voting -----
  void eliminate(Player player) {
    player.isEliminated = true;
    lastEliminated = player;
    if (player.role == Role.misterWhite) {
      mrWhiteGuessedWrong = false;
      mrWhiteGuessAttempt = '';
      phase = GamePhase.mrWhiteGuess;
    } else {
      phase = GamePhase.eliminationReveal;
    }
    notifyListeners();
  }

  // ----- Mister White guess -----
  void submitMisterWhiteGuess(String guess) {
    mrWhiteGuessAttempt = guess.trim();
    if (mrWhiteGuessAttempt.isEmpty) return;
    final correct = _normalize(mrWhiteGuessAttempt) ==
        _normalize(_wordPair.burger);
    if (correct) {
      _finish(Winner.misterWhite, guessWin: true);
    } else {
      mrWhiteGuessedWrong = true;
      phase = GamePhase.eliminationReveal;
      notifyListeners();
    }
  }

  /// Case-, accent- and whitespace-insensitive comparison key, so "Crème
  /// brûlée" matches "creme brulee".
  static String _normalize(String s) {
    const from = 'àáâäãåèéêëìíîïòóôöõùúûüýÿçñ';
    const to = 'aaaaaaeeeeiiiiooooouuuuyycn';
    final buf = StringBuffer();
    for (final ch in s.toLowerCase().trim().split('')) {
      final i = from.indexOf(ch);
      buf.write(i == -1 ? ch : to[i]);
    }
    return buf.toString().replaceAll(RegExp(r'\s+'), ' ');
  }

  void skipMisterWhiteGuess() {
    mrWhiteGuessedWrong = true;
    phase = GamePhase.eliminationReveal;
    notifyListeners();
  }

  // ----- Resolve after an elimination -----
  void resolveAfterElimination() {
    final alive = alivePlayers;
    final undercovers = alive.where((p) => p.role == Role.undercover).length;
    final burgers = alive.where((p) => p.role == Role.burger).length;
    final misterWhites = alive.where((p) => p.role == Role.misterWhite).length;

    if (undercovers == 0 && misterWhites == 0) {
      _finish(Winner.burgers);
      return;
    }
    if (burgers <= 1) {
      _finish(Winner.infiltrators);
      return;
    }
    _advanceStartingPlayer();
    round++;
    phase = GamePhase.hintRound;
    notifyListeners();
  }

  void _advanceStartingPlayer() {
    final alive = alivePlayers..sort((a, b) => a.id.compareTo(b.id));
    if (alive.isEmpty) return;
    final i = alive.indexWhere((p) => p.id == _startingPlayerId);
    if (i == -1) {
      // current starter was eliminated: pick next-higher id, else first
      _startingPlayerId =
          (alive.where((p) => p.id > _startingPlayerId).firstOrNull ??
                  alive.first)
              .id;
    } else {
      _startingPlayerId = alive[(i + 1) % alive.length].id;
    }
  }

  void _finish(Winner result, {bool guessWin = false}) {
    winner = result;
    phase = GamePhase.gameOver;
    _appState.recordGame(
      players: players,
      winner: result,
      misterWhiteGuessWin: guessWin,
    );
    notifyListeners();
  }

  // ----- Post-game -----
  /// "Opnieuw spelen": a brand-new game with the same players. As in the
  /// official Undercover rules, roles are dealt again at random with a new
  /// word pair — everyone's role was just revealed, so keeping them would
  /// spoil the next game. Names are kept and pre-filled.
  void nextRound() {
    round = 1;
    _assignRolesAndWord();
    _enterCardReveal();
  }
}
