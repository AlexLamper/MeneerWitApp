import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/leaderboard_entry.dart';
import '../storage/app_storage.dart';
import '../widgets/common.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<AppState>().leaderboard;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranglijst'),
        actions: [
          if (entries.isNotEmpty)
            IconButton(
              tooltip: 'Wissen',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmClear(context),
            ),
        ],
      ),
      body: MwBackground(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: entries.isEmpty
            ? _Empty()
            : ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) =>
                    _EntryTile(rank: i + 1, entry: entries[i]),
              ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ranglijst wissen?'),
        content: const Text('Alle scores worden permanent verwijderd.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Wissen'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<AppState>().clearLeaderboard();
    }
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_outlined,
              size: 64, color: context.palette.mutedForeground),
          const SizedBox(height: 16),
          const Text('Nog geen scores.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Speel een spel om op het bord te komen!',
            style: TextStyle(color: context.palette.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.rank, required this.entry});

  final int rank;
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final medal = switch (rank) {
      1 => context.palette.gold,
      2 => context.palette.silver,
      3 => context.palette.bronze,
      _ => null,
    };
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: medal ?? context.palette.muted,
          foregroundColor:
              medal != null ? Colors.black : context.palette.mutedForeground,
          child: Text(
            '$rank',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        title: Text(
          entry.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${entry.wins} winst${entry.wins == 1 ? '' : 'en'} • ${entry.gamesPlayed} gespeeld',
          style: TextStyle(
            fontSize: 12.5,
            color: context.palette.mutedForeground,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.score}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: context.scheme.primary,
              ),
            ),
            Text(
              'punten',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: context.palette.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
