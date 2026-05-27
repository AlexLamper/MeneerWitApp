import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/game_controller.dart';
import '../models/game_models.dart';
import '../widgets/common.dart';

Color roleColor(BuildContext context, Role role) => switch (role) {
      Role.burger => context.scheme.primary,
      Role.undercover => const Color(0xFFF59E0B),
      Role.misterWhite => context.palette.mutedForeground,
    };

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, game, _) {
        return PopScope(
          canPop: game.phase == GamePhase.gameOver,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final leave = await _confirmExit(context);
            if (leave == true && context.mounted) {
              Navigator.of(context).popUntil((r) => r.isFirst);
            }
          },
          child: Scaffold(
            body: MwBackground(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: _buildPhase(context, game),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhase(BuildContext context, GameController game) {
    return switch (game.phase) {
      GamePhase.cardReveal => _CardRevealView(key: ValueKey(game.revealIndex)),
      GamePhase.hintRound => const _HintRoundView(),
      GamePhase.voting => const _VotingView(),
      GamePhase.eliminationReveal => const _EliminationView(),
      GamePhase.mrWhiteGuess => const _MrWhiteGuessView(),
      GamePhase.gameOver => const _GameOverView(),
    };
  }

  static Future<bool?> _confirmExit(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Spel beëindigen?'),
        content: const Text(
          'Weet je zeker dat je het huidige spel wilt beëindigen? Alle voortgang gaat verloren.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Beëindigen'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card reveal (pass-and-play)
// ---------------------------------------------------------------------------
class _CardRevealView extends StatefulWidget {
  const _CardRevealView({super.key});

  @override
  State<_CardRevealView> createState() => _CardRevealViewState();
}

class _CardRevealViewState extends State<_CardRevealView> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameController>();
    final player = game.currentRevealPlayer;
    final total = game.players.length;
    final index = game.revealIndex;

    return Column(
      children: [
        _StepHeader(
          step: 'Kaart ${index + 1} / $total',
          title: _revealed ? player.name : 'Geef het apparaat aan',
        ),
        const Spacer(),
        if (!_revealed)
          _HandoffCard(
            name: player.name,
            onReveal: () => setState(() => _revealed = true),
          )
        else
          _RoleCard(player: player, hint: game.misterWhiteHint),
        const Spacer(),
        if (_revealed)
          ElevatedButton.icon(
            icon: const Icon(Icons.visibility_off_outlined),
            label: Text(game.isLastReveal
                ? 'Verberg & start ronde'
                : 'Verberg & geef door'),
            onPressed: () {
              setState(() => _revealed = false);
              game.nextReveal();
            },
          ),
      ],
    );
  }
}

class _HandoffCard extends StatelessWidget {
  const _HandoffCard({required this.name, required this.onReveal});

  final String name;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onReveal,
      child: AspectRatio(
        aspectRatio: 0.72,
        child: Card(
          color: context.scheme.primary,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_outlined,
                    size: 64, color: context.scheme.onPrimary),
                const SizedBox(height: 20),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: context.scheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Zorg dat niemand meekijkt!\nTik om te onthullen',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: context.scheme.onPrimary.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.player, required this.hint});

  final Player player;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final color = roleColor(context, player.role);
    return AspectRatio(
      aspectRatio: 0.72,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  player.role.label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              if (player.word != null)
                Text(
                  player.word!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                )
              else ...[
                const Icon(Icons.help_outline, size: 56),
                const SizedBox(height: 12),
                const Text(
                  'Heeft geen woord',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                player.role == Role.misterWhite
                    ? 'Je hebt geen woord. Luister goed naar de hints van anderen en probeer niet op te vallen!'
                    : player.role.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: context.palette.mutedForeground,
                ),
              ),
              if (hint != null && player.role == Role.misterWhite) ...[
                const SizedBox(height: 16),
                InfoPill(text: hint!, icon: Icons.lightbulb_outline),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hint round
// ---------------------------------------------------------------------------
class _HintRoundView extends StatelessWidget {
  const _HintRoundView();

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameController>();
    final order = game.hintOrder;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeader(step: 'Ronde ${game.round}', title: 'Geef je hint'),
        const SizedBox(height: 8),
        Text(
          'Beschrijf je woord nu met één woord of zin, in de volgorde van de nummers!',
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: context.palette.mutedForeground,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: order.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: i == 0
                      ? context.scheme.primary
                      : context.palette.muted,
                  foregroundColor: i == 0
                      ? context.scheme.onPrimary
                      : context.palette.mutedForeground,
                  child: Text('${i + 1}'),
                ),
                title: Text(
                  order[i].name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: i == 0
                    ? Text('Begint',
                        style: TextStyle(
                            color: context.scheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12))
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.how_to_vote_outlined),
          label: const Text('Start stemmen'),
          onPressed: game.startVoting,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Voting
// ---------------------------------------------------------------------------
class _VotingView extends StatelessWidget {
  const _VotingView();

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameController>();
    final alive = game.alivePlayers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepHeader(step: 'Stemmen', title: 'Wie is verdacht?'),
        const SizedBox(height: 8),
        Text(
          'Klik op een speler om te stemmen. De speler met de meeste stemmen wordt geëlimineerd.',
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: context.palette.mutedForeground,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              for (final p in alive)
                _VoteCard(
                  name: p.name,
                  onTap: () => _confirm(context, game, p),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirm(
      BuildContext context, GameController game, Player p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${p.name} elimineren?'),
        content: const Text('Weet je het zeker? Zijn rol wordt onthuld.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Elimineer'),
          ),
        ],
      ),
    );
    if (ok == true) game.eliminate(p);
  }
}

class _VoteCard extends StatelessWidget {
  const _VoteCard({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Elimination reveal
// ---------------------------------------------------------------------------
class _EliminationView extends StatelessWidget {
  const _EliminationView();

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameController>();
    final p = game.lastEliminated!;
    final color = roleColor(context, p.role);
    return Column(
      children: [
        const _StepHeader(step: 'Onthuld', title: 'Uitgeschakeld'),
        const Spacer(),
        Text(
          p.name,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            p.role.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (game.mrWhiteGuessedWrong)
          Text(
            'Het woord was niet "${game.mrWhiteGuessAttempt}".',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.palette.mutedForeground),
          )
        else if (p.word != null)
          Text(
            'Woord: ${p.word}',
            style: TextStyle(
              fontSize: 16,
              color: context.palette.mutedForeground,
            ),
          ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: game.resolveAfterElimination,
            child: const Text('Verder'),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mister White guess
// ---------------------------------------------------------------------------
class _MrWhiteGuessView extends StatefulWidget {
  const _MrWhiteGuessView();

  @override
  State<_MrWhiteGuessView> createState() => _MrWhiteGuessViewState();
}

class _MrWhiteGuessViewState extends State<_MrWhiteGuessView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameController>();
    final p = game.lastEliminated!;
    return Column(
      children: [
        const _StepHeader(step: 'Mister White', title: 'Laatste kans'),
        const Spacer(),
        Text(
          '${p.name} was Mister White!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Text(
          'Je kunt nog winnen! Raad het woord van de Burgers:',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: context.palette.mutedForeground,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _controller,
          textAlign: TextAlign.center,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(hintText: 'Typ het woord...'),
          onSubmitted: (v) => game.submitMisterWhiteGuess(v),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: () => game.submitMisterWhiteGuess(_controller.text),
          child: const Text('Raad'),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: game.skipMisterWhiteGuess,
          child: const Text('Ik weet het niet'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Game over
// ---------------------------------------------------------------------------
class _GameOverView extends StatefulWidget {
  const _GameOverView();

  @override
  State<_GameOverView> createState() => _GameOverViewState();
}

class _GameOverViewState extends State<_GameOverView> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3))
      ..play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameController>();
    final winner = game.winner!;
    return Stack(
      children: [
        Column(
          children: [
            const Spacer(),
            Text(
              winner.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.5,
                color: context.scheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Het woord was "${game.wordPair.burger}"',
              style: TextStyle(
                fontSize: 16,
                color: context.palette.mutedForeground,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  for (final p in game.players)
                    _ResultRow(player: p),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Volgende ronde'),
              onPressed: game.nextRound,
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('Terug naar start'),
            ),
          ],
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirection: pi / 2,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            maxBlastForce: 30,
            minBlastForce: 10,
            gravity: 0.2,
            colors: const [
              Color(0xFF88FF5A),
              Color(0xFFA25AFD),
              Color(0xFFFF36FF),
              Color(0xFFFF5E7E),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final color = roleColor(context, player.role);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              player.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                decoration:
                    player.isEliminated ? TextDecoration.lineThrough : null,
                color: player.isEliminated
                    ? context.palette.mutedForeground
                    : null,
              ),
            ),
          ),
          Text(
            player.role.label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared header
// ---------------------------------------------------------------------------
class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step, required this.title});

  final String step;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          step.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: context.scheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
