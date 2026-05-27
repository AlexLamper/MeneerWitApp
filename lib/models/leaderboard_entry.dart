class LeaderboardEntry {
  LeaderboardEntry({
    required this.name,
    this.score = 0,
    this.gamesPlayed = 0,
    this.wins = 0,
    this.lastPlayed = 0,
    this.burgerGames = 0,
    this.undercoverGames = 0,
    this.misterWhiteGames = 0,
    this.misterWhiteGuessWins = 0,
  });

  String name;
  int score;
  int gamesPlayed;
  int wins;
  int lastPlayed;
  int burgerGames;
  int undercoverGames;
  int misterWhiteGames;
  int misterWhiteGuessWins;

  Map<String, dynamic> toJson() => {
        'name': name,
        'score': score,
        'gamesPlayed': gamesPlayed,
        'wins': wins,
        'lastPlayed': lastPlayed,
        'roleStats': {
          'burger': burgerGames,
          'undercover': undercoverGames,
          'misterWhite': misterWhiteGames,
        },
        'misterWhiteGuessWins': misterWhiteGuessWins,
      };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final roleStats = (json['roleStats'] as Map?) ?? const {};
    return LeaderboardEntry(
      name: json['name'] as String,
      score: (json['score'] as num?)?.toInt() ?? 0,
      gamesPlayed: (json['gamesPlayed'] as num?)?.toInt() ?? 0,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      lastPlayed: (json['lastPlayed'] as num?)?.toInt() ?? 0,
      burgerGames: (roleStats['burger'] as num?)?.toInt() ?? 0,
      undercoverGames: (roleStats['undercover'] as num?)?.toInt() ?? 0,
      misterWhiteGames: (roleStats['misterWhite'] as num?)?.toInt() ?? 0,
      misterWhiteGuessWins: (json['misterWhiteGuessWins'] as num?)?.toInt() ?? 0,
    );
  }
}
