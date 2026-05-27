import 'package:flutter/material.dart';

enum Role { burger, undercover, misterWhite }

extension RoleInfo on Role {
  String get label => switch (this) {
        Role.burger => 'Burger',
        Role.undercover => 'Undercover',
        Role.misterWhite => 'Mister White',
      };

  String get description => switch (this) {
        Role.burger =>
          'Krijgen het geheime woord. Moeten de indringers vinden.',
        Role.undercover =>
          'Krijgen een woord dat lijkt op dat van de burgers. Moeten onopgemerkt blijven.',
        Role.misterWhite =>
          'Krijgt geen woord. Moet het woord van de burgers raden door goed te luisteren.',
      };

  /// Whether this role counts as an infiltrator (not a Burger).
  bool get isInfiltrator => this != Role.burger;
}

@immutable
class WordPair {
  const WordPair(this.burger, this.undercover);

  final String burger;
  final String undercover;

  factory WordPair.fromJson(Map<String, dynamic> json) =>
      WordPair(json['burger'] as String, json['undercover'] as String);
}

class Player {
  Player({required this.id, required this.name});

  final int id;
  String name;
  Role role = Role.burger;

  /// The word shown on this player's card. `null` for Mister White.
  String? word;

  bool isEliminated = false;
  int votes = 0;
}

enum GamePhase {
  cardReveal,
  hintRound,
  voting,
  eliminationReveal,
  mrWhiteGuess,
  gameOver,
}

enum Winner { burgers, infiltrators, misterWhite }

extension WinnerInfo on Winner {
  String get title => switch (this) {
        Winner.burgers => 'Burgers winnen!',
        Winner.infiltrators => 'Infiltranten winnen!',
        Winner.misterWhite => 'Mister White wint!',
      };
}

class GameSettings {
  GameSettings({
    this.undercoverCount = 1,
    this.mrWhiteCount = 0,
    this.misterWhiteHintEnabled = false,
    this.category = 'Algemeen',
    this.useCustomWords = false,
  });

  int undercoverCount;
  int mrWhiteCount;
  bool misterWhiteHintEnabled;
  String category;
  bool useCustomWords;

  int burgerCount(int totalPlayers) =>
      totalPlayers - undercoverCount - mrWhiteCount;

  /// Mirrors the site: at least 2 Burgers and at least one infiltrator.
  String? validate(int totalPlayers) {
    if (undercoverCount + mrWhiteCount < 1) {
      return 'Kies minimaal één Undercover of Mister White.';
    }
    if (burgerCount(totalPlayers) < 2) {
      return 'Je hebt minimaal 2 Burgers nodig om een geldig spel te starten.';
    }
    return null;
  }

  GameSettings copy() => GameSettings(
        undercoverCount: undercoverCount,
        mrWhiteCount: mrWhiteCount,
        misterWhiteHintEnabled: misterWhiteHintEnabled,
        category: category,
        useCustomWords: useCustomWords,
      );
}
