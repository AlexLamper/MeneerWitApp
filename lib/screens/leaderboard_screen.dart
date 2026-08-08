import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/leaderboard_entry.dart';
import '../storage/app_storage.dart';
import '../theme.dart';
import '../widgets/common.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<AppState>().leaderboard;
    return Scaffold(
      body: MwBackground(
        // `flex flex-col h-full p-6`
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MwHeader(
              title: 'Ranglijst',
              fontSize: 30,
              onBack: () => Navigator.of(context).pop(),
              actions: [
                if (entries.isNotEmpty)
                  MwCircleButton(
                    tooltip: 'Wissen',
                    icon: Icons.delete_outline,
                    onPressed: () => _confirmClear(context),
                  ),
                const ThemeToggleCircle(),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: entries.isEmpty
                  ? const _Empty()
                  : ListView.separated(
                      padding: const EdgeInsets.only(right: 8),
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

/// `text-center text-muted-foreground mt-20`
class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 60, height: 1)),
          const SizedBox(height: 16),
          Text('Nog geen scores.',
              style: MwText.t(16, color: p.mutedForeground)),
          Text(
            'Speel een spel om op het bord te komen!',
            textAlign: TextAlign.center,
            style: MwText.t(14, color: p.mutedForeground),
          ),
        ],
      ),
    );
  }
}

/// `relative overflow-hidden flex flex-col py-7 px-5 rounded-3xl border`
class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.rank, required this.entry});

  final int rank;
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final podium = switch (rank) {
      1 => MwPalette.yellow500,
      2 => MwPalette.slate400,
      3 => MwPalette.bronze,
      _ => null,
    };
    // `bg-gradient-to-br from-<c>/10 to-<c2>/5`
    final gradient = switch (rank) {
      1 => [
          MwPalette.yellow500.withValues(alpha: 0.10),
          MwPalette.yellow600.withValues(alpha: 0.05),
        ],
      2 => [
          MwPalette.slate300.withValues(alpha: 0.10),
          MwPalette.slate400.withValues(alpha: 0.05),
        ],
      3 => [
          MwPalette.bronze.withValues(alpha: 0.10),
          MwPalette.bronze.withValues(alpha: 0.05),
        ],
      _ => null,
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(MwRadius.x3),
      child: Container(
        decoration: BoxDecoration(
          color: gradient == null ? p.card : null,
          gradient: gradient == null
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
          borderRadius: BorderRadius.circular(MwRadius.x3),
          border: Border.all(
            color: podium?.withValues(alpha: 0.3) ?? p.border,
          ),
        ),
        child: Stack(
          children: [
            // `absolute -top-2 -right-2 w-16 h-16 opacity-10` watermark.
            Positioned(
              top: -8,
              right: -8,
              width: 64,
              height: 64,
              child: Opacity(
                opacity: 0.1,
                child: Text(
                  '$rank',
                  style: MwText.t(60, weight: MwText.black)
                      .copyWith(fontStyle: FontStyle.italic, height: 1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // `w-12 h-12 rounded-2xl … text-2xl`
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: podium ?? p.secondary,
                          borderRadius: BorderRadius.circular(MwRadius.x2),
                        ),
                        child: Text(
                          '#$rank',
                          style: MwText.t(
                            24,
                            color: podium != null
                                ? Colors.white
                                : p.mutedForeground,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              entry.name,
                              overflow: TextOverflow.ellipsis,
                              style: MwText.t(20,
                                  weight: MwText.black, tracking: -0.025),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                _Stat(
                                  dot: p.primary.withValues(alpha: 0.4),
                                  text: '${entry.gamesPlayed} games',
                                ),
                                const SizedBox(width: 12),
                                _Stat(
                                  dot: MwPalette.green500
                                      .withValues(alpha: 0.4),
                                  text: '${entry.wins} wins',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${entry.score}',
                            style: MwText.t(
                              30,
                              weight: MwText.black,
                              tracking: -0.05,
                              color: rank < 4 ? p.primary : p.foreground,
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -4),
                            child: Text(
                              'PUNTEN',
                              style: MwText.t(
                                9,
                                weight: MwText.black,
                                tracking: 0.2,
                                color:
                                    p.mutedForeground.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (entry.misterWhiteGuessWins > 0) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.only(top: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                              color: p.border.withValues(alpha: 0.4)),
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: p.primary.withValues(alpha: 0.05),
                            borderRadius:
                                BorderRadius.circular(MwRadius.full),
                            border: Border.all(
                                color: p.primary.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🧠',
                                  style: TextStyle(fontSize: 12, height: 1)),
                              const SizedBox(width: 6),
                              Text(
                                '${entry.misterWhiteGuessWins}X MEESTERBREIN',
                                style: MwText.t(
                                  10,
                                  weight: MwText.black,
                                  tracking: 0.05,
                                  color: p.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `flex items-center gap-1 text-[10px] font-bold text-muted-foreground
/// uppercase tracking-wider` with a `w-1 h-1 rounded-full` dot.
class _Stat extends StatelessWidget {
  const _Stat({required this.dot, required this.text});

  final Color dot;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text.toUpperCase(),
          style: MwText.t(
            10,
            weight: MwText.bold,
            tracking: 0.05,
            color: context.palette.mutedForeground,
          ),
        ),
      ],
    );
  }
}
