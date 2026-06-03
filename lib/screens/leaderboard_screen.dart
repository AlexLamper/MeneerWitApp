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
      body: MwBackground(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                MwCircleButton(
                  icon: Icons.arrow_back,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Ranglijst',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ),
                if (entries.isNotEmpty) ...[
                  MwCircleButton(
                    tooltip: 'Wissen',
                    icon: Icons.delete_outline,
                    onPressed: () => _confirmClear(context),
                  ),
                  const SizedBox(width: 10),
                ],
                const ThemeToggleCircle(),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: entries.isEmpty
                  ? const _Empty()
                  : ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) =>
                          _EntryTile(rank: i + 1, entry: entries[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showMwConfirm(
      context,
      title: 'Ranglijst wissen?',
      message: 'Alle scores worden permanent verwijderd.',
      confirmText: 'Wissen',
      destructive: true,
    );
    if (ok && context.mounted) context.read<AppState>().clearLeaderboard();
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 64)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: medal?.withValues(alpha: 0.5) ?? context.palette.border,
        ),
      ),
      child: Stack(
        children: [
          // Ghost rank watermark.
          Positioned(
            right: 2,
            top: -6,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                color: context.scheme.onSurface.withValues(alpha: 0.06),
              ),
            ),
          ),
          Row(
            children: [
              // Rounded-square rank badge.
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: medal ?? context.palette.muted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: medal != null
                        ? Colors.black
                        : context.palette.mutedForeground,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _StatDot(color: context.palette.mutedForeground),
                        const SizedBox(width: 5),
                        _StatText('${entry.gamesPlayed} games'),
                        const SizedBox(width: 12),
                        const _StatDot(color: Color(0xFF22C55E)),
                        const SizedBox(width: 5),
                        _StatText('${entry.wins} wins'),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.score}',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: context.scheme.primary,
                    ),
                  ),
                  Text(
                    'PUNTEN',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: context.palette.mutedForeground,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatDot extends StatelessWidget {
  const _StatDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _StatText extends StatelessWidget {
  const _StatText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: context.palette.mutedForeground,
      ),
    );
  }
}
