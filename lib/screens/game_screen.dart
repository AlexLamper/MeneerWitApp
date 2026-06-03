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
            if (await confirmQuitGame(context) && context.mounted) {
              Navigator.of(context).popUntil((r) => r.isFirst);
            }
          },
          child: Scaffold(
            body: MwBackground(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
      GamePhase.hintRound => const _DescribeView(),
      GamePhase.voting => const _VotingView(),
      GamePhase.eliminationReveal => const _EliminationView(),
      GamePhase.mrWhiteGuess => const _MrWhiteGuessView(),
      GamePhase.gameOver => const _GameOverView(),
    };
  }
}

/// Top bar with theme toggle and a quit button, used on in-game screens.
class _GameTopBar extends StatelessWidget {
  const _GameTopBar({this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (title != null)
          Expanded(
            child: Text(
              title!,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
          )
        else
          const Spacer(),
        const ThemeToggleCircle(),
        const SizedBox(width: 10),
        MwCircleButton(
          tooltip: 'Spel stoppen',
          icon: Icons.logout,
          onPressed: () async {
            if (await confirmQuitGame(context) && context.mounted) {
              Navigator.of(context).popUntil((r) => r.isFirst);
            }
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Card reveal: name entry -> flip card (pass-and-play)
// ---------------------------------------------------------------------------
enum _RevealStage { name, card }

class _CardRevealView extends StatefulWidget {
  const _CardRevealView({super.key});

  @override
  State<_CardRevealView> createState() => _CardRevealViewState();
}

class _CardRevealViewState extends State<_CardRevealView> {
  _RevealStage _stage = _RevealStage.name;
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final game = context.read<GameController>();
    if (!game.currentNameIsPlaceholder) _nameCtrl.text = game.currentRevealPlayer.name;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameController>();
    return Column(
      children: [
        const _GameTopBar(),
        Expanded(
          child: _stage == _RevealStage.name
              ? _nameEntry(context, game)
              : _CardStage(
                  onDone: () {
                    game.nextReveal();
                  },
                ),
        ),
      ],
    );
  }

  Widget _nameEntry(BuildContext context, GameController game) {
    final index = game.revealIndex;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(flex: 3),
        Text(
          'Geef de telefoon aan',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: context.palette.mutedForeground,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Speler ${index + 1}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 28),
        const SectionLabel('Voer je naam in'),
        const SizedBox(height: 8),
        TextField(
          controller: _nameCtrl,
          textAlign: TextAlign.center,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(hintText: 'Je naam...'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          onSubmitted: (_) => _confirmName(game),
        ),
        const SizedBox(height: 14),
        ElevatedButton(
          onPressed: () => _confirmName(game),
          child: const Text('Bekijk kaart'),
        ),
        const Spacer(flex: 4),
      ],
    );
  }

  void _confirmName(GameController game) {
    game.setCurrentRevealName(_nameCtrl.text);
    setState(() => _stage = _RevealStage.card);
  }
}

/// The flip card itself (front handoff -> back with the word).
class _CardStage extends StatefulWidget {
  const _CardStage({required this.onDone});

  final VoidCallback onDone;

  @override
  State<_CardStage> createState() => _CardStageState();
}

class _CardStageState extends State<_CardStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  bool get _revealed => _flip.value > 0.5;

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameController>();
    final player = game.currentRevealPlayer;
    final total = game.players.length;

    return Column(
      children: [
        const SizedBox(height: 12),
        Text(
          'KAART ${game.revealIndex + 1} / $total',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: context.scheme.primary,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            if (_flip.isAnimating) return;
            if (_revealed) return;
            _flip.forward();
          },
          child: AnimatedBuilder(
            animation: _flip,
            builder: (context, _) {
              final angle = _flip.value * pi;
              final showBack = _flip.value > 0.5;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                child: showBack
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(pi),
                        child: _CardBack(player: player, hint: game.misterWhiteHint),
                      )
                    : const _CardFront(),
              );
            },
          ),
        ),
        const Spacer(),
        AnimatedBuilder(
          animation: _flip,
          builder: (context, child) =>
              Opacity(opacity: _flip.isCompleted ? 1 : 0, child: child),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.visibility_off_outlined),
            label: Text(
              game.isLastReveal ? 'Verberg & start ronde' : 'Verberg & geef door',
            ),
            onPressed: () => widget.onDone(),
          ),
        ),
      ],
    );
  }
}

class _CardFront extends StatelessWidget {
  const _CardFront();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.72,
      child: Card(
        color: context.palette.card,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: context.palette.muted,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.question_mark_rounded,
                    size: 44, color: context.scheme.onSurface),
              ),
              const SizedBox(height: 24),
              const Text(
                'Tik om te onthullen',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                'Zorg dat niemand meekijkt!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: context.palette.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({required this.player, required this.hint});

  final Player player;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    // Always the same design — no per-role colours (matches the site).
    final accent = context.scheme.primary;
    return AspectRatio(
      aspectRatio: 0.72,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.palette.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  player.role.label,
                  style: TextStyle(
                      color: accent, fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
              const SizedBox(height: 26),
              if (player.word != null) ...[
                Text(
                  'JOUW WOORD',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: context.palette.mutedForeground,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  player.word!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
              ] else ...[
                const Icon(Icons.help_outline, size: 52),
                const SizedBox(height: 12),
                const Text('Geen woord',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Text(
                  'Luister goed en val niet op!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13.5, color: context.palette.mutedForeground),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 14),
                  InfoPill(text: hint!, icon: Icons.lightbulb_outline),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Describe phase (Omschrijf-fase)
// ---------------------------------------------------------------------------
class _DescribeView extends StatefulWidget {
  const _DescribeView();

  @override
  State<_DescribeView> createState() => _DescribeViewState();
}

class _DescribeViewState extends State<_DescribeView> {
  bool _peek = false;

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameController>();
    final order = game.hintOrder;
    final starter = game.startingPlayer ?? order.first;
    // Map player id -> turn number (1-based) in the hint order.
    final turnOf = {for (var i = 0; i < order.length; i++) order[i].id: i + 1};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GameTopBar(title: 'Omschrijf-fase'),
        const SizedBox(height: 6),
        Text(
          _peek
              ? 'Selecteer je eigen kaart om je woord te zien.'
              : 'Beschrijf je woord nu met één woord of zin, in de volgorde van de nummers!',
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: context.palette.mutedForeground,
          ),
        ),
        const SizedBox(height: 14),
        if (!_peek) _TurnOrderCard(order: order, starter: starter),
        const SizedBox(height: 14),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.9,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              // Display order matches the actual turn order.
              for (final p in order)
                _DescribePlayerCard(
                  player: p,
                  turn: turnOf[p.id] ?? 0,
                  isStarter: p.id == starter.id,
                  peek: _peek,
                  onTap: _peek ? () => _showWord(context, p) : null,
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          icon: const Icon(Icons.how_to_vote_outlined),
          label: const Text('Ga naar stemmen'),
          onPressed: game.startVoting,
        ),
        const SizedBox(height: 12),
        _Toolbar(
          peek: _peek,
          onWoorden: () => _newWords(context, game),
          onOpties: () => _openSettings(context),
          onSpelerPlus: () => _addPlayer(context, game),
          onBekijk: () => setState(() => _peek = !_peek),
        ),
      ],
    );
  }

  void _showWord(BuildContext context, Player p) {
    showDialog(
      context: context,
      builder: (context) => MwDialog(
        title: p.name,
        message: p.word == null
            ? 'Jij bent Mister White — je hebt geen woord.'
            : 'Jouw woord is "${p.word}".',
        actions: [
          MwDialogButton(
            label: 'Sluiten',
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _newWords(BuildContext context, GameController game) async {
    final ok = await showMwConfirm(
      context,
      title: 'Nieuwe woorden?',
      message: 'Iedereen krijgt een nieuw woord. De rollen blijven hetzelfde.',
      confirmText: 'Ja, nieuwe woorden',
    );
    if (ok) game.regenerateWord();
  }

  void _openSettings(BuildContext context) {
    showDialog(context: context, builder: (_) => const _SettingsDialog());
  }

  Future<void> _addPlayer(BuildContext context, GameController game) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => MwDialog(
        title: 'Speler toevoegen',
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(hintText: 'Naam van speler'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          MwDialogButton(
            label: 'Toevoegen',
            onTap: () => Navigator.pop(context, ctrl.text),
          ),
          MwDialogButton(
            label: 'Annuleren',
            variant: MwButtonVariant.muted,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty || !context.mounted) return;
    final player = game.addPlayerMidGame(name);
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _AddedPlayerReveal(player: player)),
    );
    if (context.mounted) setState(() {});
  }
}

class _TurnOrderCard extends StatelessWidget {
  const _TurnOrderCard({required this.order, required this.starter});

  final List<Player> order;
  final Player starter;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BEURTVOLGORDE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: context.scheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13.5,
                  color: context.scheme.onSurface,
                ),
                children: [
                  const TextSpan(text: 'Start bij '),
                  TextSpan(
                    text: starter.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const TextSpan(text: ' en ga daarna verder volgens de nummers.'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < order.length; i++) ...[
                    _OrderChip(
                      number: i + 1,
                      name: order[i].name,
                      highlight: i == 0,
                    ),
                    if (i < order.length - 1) const SizedBox(width: 8),
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

class _OrderChip extends StatelessWidget {
  const _OrderChip(
      {required this.number, required this.name, required this.highlight});

  final int number;
  final String name;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
      decoration: BoxDecoration(
        color: highlight
            ? context.scheme.primary.withValues(alpha: 0.18)
            : context.palette.muted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlight ? context.scheme.primary : context.palette.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor:
                highlight ? context.scheme.primary : context.palette.border,
            foregroundColor:
                highlight ? context.scheme.onPrimary : context.scheme.onSurface,
            child: Text('$number',
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 8),
          Text(name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          if (highlight) ...[
            const SizedBox(width: 8),
            Text('START',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: context.scheme.primary)),
          ],
        ],
      ),
    );
  }
}

class _DescribePlayerCard extends StatelessWidget {
  const _DescribePlayerCard({
    required this.player,
    required this.turn,
    required this.isStarter,
    required this.peek,
    required this.onTap,
  });

  final Player player;
  final int turn;
  final bool isStarter;
  final bool peek;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final highlight = peek || isStarter;
    return Stack(
      children: [
        Material(
          color: context.palette.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: highlight ? context.scheme.primary : context.palette.border,
              width: highlight ? 1.8 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 28, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: context.palette.muted,
                    child: Icon(Icons.person_outline,
                        size: 18, color: context.palette.mutedForeground),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          player.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        Text(
                          isStarter ? 'START SPELER' : 'ACTIEF',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: isStarter
                                ? context.scheme.primary
                                : context.palette.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: CircleAvatar(
            radius: 11,
            backgroundColor: context.scheme.primary,
            foregroundColor: context.scheme.onPrimary,
            child: Text('$turn',
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.peek,
    required this.onWoorden,
    required this.onOpties,
    required this.onSpelerPlus,
    required this.onBekijk,
  });

  final bool peek;
  final VoidCallback onWoorden;
  final VoidCallback onOpties;
  final VoidCallback onSpelerPlus;
  final VoidCallback onBekijk;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.palette.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ToolItem(icon: Icons.autorenew, label: 'Woorden', onTap: onWoorden),
          _ToolItem(icon: Icons.settings_outlined, label: 'Opties', onTap: onOpties),
          _ToolItem(
              icon: Icons.person_add_alt, label: 'Speler+', onTap: onSpelerPlus),
          _ToolItem(
            icon: Icons.visibility_outlined,
            label: 'Bekijk',
            active: peek,
            onTap: onBekijk,
          ),
        ],
      ),
    );
  }
}

class _ToolItem extends StatelessWidget {
  const _ToolItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color =
        active ? context.scheme.primary : context.palette.mutedForeground;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// In-game settings dialog ("Instellingen").
class _SettingsDialog extends StatelessWidget {
  const _SettingsDialog();

  @override
  Widget build(BuildContext context) {
    return MwDialog(
      title: 'Instellingen',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
            decoration: BoxDecoration(
              color: context.palette.muted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Thema',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                const ThemeToggleCircle(),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'VERSIE 1.0.3 • MENEER WIT - DOOR ALEX LAMPER',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: context.palette.mutedForeground,
            ),
          ),
        ],
      ),
      actions: [
        MwDialogButton(
          label: 'Opslaan',
          onTap: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

/// Full-screen reveal for a player added mid-game.
class _AddedPlayerReveal extends StatelessWidget {
  const _AddedPlayerReveal({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MwBackground(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text('${player.name} - bekijk je kaart',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            Expanded(
              child: _CardStage(onDone: () => Navigator.pop(context)),
            ),
          ],
        ),
      ),
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
        const _GameTopBar(),
        // Content pushed further down (top-right buttons stay put).
        const SizedBox(height: 32),
        const Text(
          'Wie is verdacht?',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          'Klik op een speler om te stemmen. De speler met de meeste stemmen wordt geëlimineerd.',
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: context.palette.mutedForeground,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 2.4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              for (final p in alive)
                _VoteCard(name: p.name, onTap: () => _confirm(context, game, p)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirm(
      BuildContext context, GameController game, Player p) async {
    final ok = await showMwConfirm(
      context,
      title: '${p.name} elimineren?',
      message: 'Weet je het zeker? Zijn rol wordt onthuld.',
      confirmText: 'Elimineren',
      destructive: true,
    );
    if (ok) game.eliminate(p);
  }
}

class _VoteCard extends StatelessWidget {
  const _VoteCard({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: context.scheme.primary,
                child: Icon(Icons.fingerprint,
                    color: context.scheme.onPrimary, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    Text('STEMMEN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: context.palette.mutedForeground,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Elimination reveal ("X was... ROL")
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
        const _GameTopBar(),
        const Spacer(),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${p.name} was...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      Text('ROL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: context.palette.mutedForeground,
                          )),
                      const SizedBox(height: 6),
                      Text(
                        p.role.label,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                if (game.mrWhiteGuessedWrong) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Het woord was niet "${game.mrWhiteGuessAttempt}".',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.palette.mutedForeground),
                  ),
                ] else if (p.word != null) ...[
                  const SizedBox(height: 14),
                  Text('Woord: ${p.word}',
                      style:
                          TextStyle(color: context.palette.mutedForeground)),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: game.resolveAfterElimination,
                    child: const Text('Doorgaan'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mister White last guess
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
        const _GameTopBar(),
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
          style: TextStyle(fontSize: 15, color: context.palette.mutedForeground),
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
// Game over (Einde spel)
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
    _confetti = ConfettiController(duration: const Duration(seconds: 5))..play();
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 56),
            Text(
              'EINDE SPEL',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                color: context.palette.mutedForeground,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              winner.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                height: 1.05,
                letterSpacing: -1.5,
                color: context.scheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Het woord was "${game.wordPair.burger}"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: context.palette.mutedForeground,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: SectionLabel('Speler')),
                SectionLabel('Rol & woord'),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  for (final p in game.players) _ResultCard(player: p),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Opnieuw spelen'),
              onPressed: game.nextRound,
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('Terug naar start'),
            ),
          ],
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.04,
            numberOfParticles: 24,
            maxBlastForce: 60,
            minBlastForce: 25,
            gravity: 0.3,
            particleDrag: 0.05,
            minimumSize: const Size(8, 8),
            maximumSize: const Size(16, 16),
            colors: const [
              Color(0xFF88FF5A),
              Color(0xFFA25AFD),
              Color(0xFFFF36FF),
              Color(0xFFFF5E7E),
              Color(0xFF5A8CFF),
              Color(0xFFFFD93D),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final color = roleColor(context, player.role);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.palette.border),
      ),
      child: Row(
        children: [
          if (player.isEliminated) ...[
            const Text('💀', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              player.name,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                decoration:
                    player.isEliminated ? TextDecoration.lineThrough : null,
                color: player.isEliminated
                    ? context.palette.mutedForeground
                    : null,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                player.role.label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 14),
              ),
              Text(
                (player.word ?? '—').toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: context.palette.mutedForeground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
