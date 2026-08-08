import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/game_controller.dart';
import '../models/game_models.dart';
import '../theme.dart';
import '../widgets/common.dart';

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
            body: Stack(
              fit: StackFit.expand,
              children: [
                MwBackground(
                  padding: EdgeInsets.zero,
                  child: _buildPhase(context, game),
                ),
                // `fixed top-4 right-4 z-50 flex gap-2 items-center`
                const Positioned(top: 16, right: 16, child: _TopControls()),
              ],
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

/// Theme switch + quit, pinned to the top-right like the site's controls.
class _TopControls extends StatelessWidget {
  const _TopControls();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ThemeToggleCircle(),
          const SizedBox(width: 8),
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
      ),
    );
  }
}

/// `h2 text-2xl font-black mb-2 bg-clip-text … from-foreground to-foreground/60`
class _PhaseTitle extends StatelessWidget {
  const _PhaseTitle(this.text, {this.fontSize = 24});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return MwGradientText(
      text,
      style: MwText.t(fontSize, weight: MwText.black),
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
    if (!game.currentNameIsPlaceholder) {
      _nameCtrl.text = game.currentRevealPlayer.name;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameController>();
    // `flex flex-col h-full p-4 items-center justify-center text-center`
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _stage == _RevealStage.name
          ? _nameEntry(context, game)
          : _CardStage(onDone: game.nextReveal),
    );
  }

  Widget _nameEntry(BuildContext context, GameController game) {
    final p = context.palette;
    final index = game.revealIndex;
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          // `w-full max-w-xs`
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const _PhaseTitle('Geef de telefoon aan', fontSize: 20),
              const SizedBox(height: 8),
              Text(
                'Speler ${index + 1}',
                style: MwText.t(30, weight: MwText.black),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: SectionLabel('Voer je naam in'),
                ),
              ),
              const SizedBox(height: 8),
              // `w-full p-3 bg-secondary rounded-2xl text-center font-bold
              //  text-lg border-2 border-border focus:border-primary`
              TextField(
                controller: _nameCtrl,
                textAlign: TextAlign.center,
                textInputAction: TextInputAction.done,
                style: MwText.t(18, weight: MwText.bold, color: p.foreground),
                decoration: InputDecoration(
                  hintText: 'Je naam...',
                  hintStyle:
                      MwText.t(18, weight: MwText.bold, color: p.mutedForeground),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(MwRadius.x2),
                    borderSide: BorderSide(color: p.border, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(MwRadius.x2),
                    borderSide: BorderSide(color: p.border, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(MwRadius.x2),
                    borderSide: BorderSide(color: p.primary, width: 2),
                  ),
                ),
                onSubmitted: (_) => _confirmName(game),
              ),
              const SizedBox(height: 24),
              MwButton(
                label: 'Bekijk kaart',
                height: 52,
                onTap: () => _confirmName(game),
              ),
            ],
          ),
        ),
      ),
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
  // `transition-transform duration-700`
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
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

    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionLabel('Kaart ${game.revealIndex + 1} / $total'),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  if (_flip.isAnimating || _revealed) return;
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
                              child: _CardBack(
                                  player: player, hint: game.misterWhiteHint),
                            )
                          : const _CardFront(),
                    );
                  },
                ),
              ),
              // `mb-8` between the card and the button.
              const SizedBox(height: 32),
              AnimatedBuilder(
                animation: _flip,
                builder: (context, child) => IgnorePointer(
                  ignoring: !_flip.isCompleted,
                  child: Opacity(
                    opacity: _flip.isCompleted ? 1 : 0,
                    child: child,
                  ),
                ),
                // `w-full py-4 bg-secondary rounded-2xl font-bold text-lg
                //  border-2 border-border`
                child: MwButton(
                  label: game.isLastReveal
                      ? 'Verberg & start ronde'
                      : 'Verberg & geef door',
                  variant: MwButtonVariant.secondary,
                  bordered: true,
                  onTap: widget.onDone,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `aspect-3/4 rounded-[2.5rem] shadow-2xl border-2 border-border/60
/// bg-gradient-to-br from-slate-100 to-slate-200 (dark: zinc-800 → zinc-900)`
class _CardFront extends StatelessWidget {
  const _CardFront();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [p.cardFaceFrom, p.cardFaceTo],
          ),
          borderRadius: BorderRadius.circular(MwRadius.modal),
          border: Border.all(color: p.border.withValues(alpha: 0.6), width: 2),
          boxShadow: mwShadow2Xl(),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: p.foreground.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Text(
                '?',
                style: MwText.t(36,
                    weight: MwText.black, color: p.foreground),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tik om te onthullen',
              textAlign: TextAlign.center,
              style:
                  MwText.t(24, weight: MwText.black, color: p.foreground),
            ),
            const SizedBox(height: 8),
            Text(
              'Zorg dat niemand meekijkt!',
              textAlign: TextAlign.center,
              style: MwText.t(14, color: p.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}

/// `bg-card rounded-[2.5rem] shadow-2xl p-8 border-2 border-border`
class _CardBack extends StatelessWidget {
  const _CardBack({required this.player, required this.hint});

  final Player player;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isMisterWhite = player.role == Role.misterWhite;
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(MwRadius.modal),
          border: Border.all(color: p.border, width: 2),
          boxShadow: mwShadow2Xl(),
        ),
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isMisterWhite) ...[
              _CardLabel('Jouw Rol'),
              const SizedBox(height: 16),
              Text(
                'Mister White',
                style: MwText.t(30,
                    weight: MwText.black, color: p.cardForeground),
              ),
              const SizedBox(height: 32),
              Container(width: 64, height: 1, color: p.border),
              const SizedBox(height: 32),
            ],
            _CardLabel('Jouw Woord'),
            const SizedBox(height: 16),
            Text(
              isMisterWhite ? '???' : (player.word ?? '???'),
              textAlign: TextAlign.center,
              style: MwText.t(
                36,
                weight: MwText.black,
                tracking: -0.025,
                color: p.cardForeground,
              ),
            ),
            if (isMisterWhite) ...[
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Column(
                  children: [
                    Text(
                      'Je hebt geen woord. Luister goed naar de hints van anderen en probeer niet op te vallen!',
                      textAlign: TextAlign.center,
                      style: MwText.t(10,
                          height: 1.625, color: p.mutedForeground),
                    ),
                    if (hint != null) ...[
                      const SizedBox(height: 12),
                      // `rounded-lg border border-primary/30 bg-primary/10 px-3 py-2`
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: p.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(MwRadius.lg),
                          border: Border.all(
                              color: p.primary.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'HINT',
                              style: MwText.t(9,
                                  weight: MwText.black,
                                  tracking: 0.05,
                                  color: p.primary),
                            ),
                            Text(
                              hint!,
                              style: MwText.t(11,
                                  weight: MwText.bold,
                                  color: p.cardForeground),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// `text-xs font-bold uppercase tracking-[0.2em] text-muted-foreground`
class _CardLabel extends StatelessWidget {
  const _CardLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: MwText.t(
        12,
        weight: MwText.bold,
        tracking: 0.2,
        color: context.palette.mutedForeground,
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
    final p = context.palette;
    final game = context.read<GameController>();
    final order = game.hintOrder;
    final starter = game.startingPlayer ?? order.first;
    final turnOf = {for (var i = 0; i < order.length; i++) order[i].id: i + 1};

    // `flex flex-col h-full p-4 pt-8 overflow-hidden`
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PhaseTitle('Omschrijf-fase'),
          const SizedBox(height: 8),
          Text(
            _peek
                ? 'Selecteer je eigen kaart om je woord te zien.'
                : 'Beschrijf je woord nu met één woord of zin, in de volgorde van de nummers!',
            style: MwText.t(14, color: p.mutedForeground),
          ),
          const SizedBox(height: 16),
          if (!_peek) ...[
            _TurnOrderCard(order: order, starter: starter),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: GridView(
              clipBehavior: Clip.none,
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 0),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                mainAxisExtent: 64,
              ),
              children: [
                for (final pl in order)
                  _DescribePlayerCard(
                    player: pl,
                    turn: turnOf[pl.id] ?? 0,
                    isStarter: pl.id == starter.id,
                    peek: _peek,
                    onTap: _peek ? () => _showWord(context, pl) : null,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // `w-full py-4 bg-primary rounded-2xl font-bold text-xl`
          MwButton(
            label: 'Ga naar stemmen',
            icon: Icons.chevron_right,
            fontSize: 20,
            onTap: game.startVoting,
          ),
          const SizedBox(height: 16),
          _Toolbar(
            peek: _peek,
            onWoorden: () => _newWords(context, game),
            onOpties: () => _openSettings(context),
            onSpelerPlus: () => _addPlayer(context, game),
            onBekijk: () => setState(() => _peek = !_peek),
          ),
        ],
      ),
    );
  }

  void _showWord(BuildContext context, Player p) {
    showMwDialog(
      context,
      builder: (context) => MwDialog(
        title: p.name,
        message: p.word == null
            ? 'Jij bent Mister White — je hebt geen woord.'
            : 'Jouw woord is "${p.word}".',
        actions: [
          MwDialogButton(
            label: 'Sluiten',
            variant: MwButtonVariant.secondary,
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
    showMwDialog(context, builder: (_) => const _SettingsDialog());
  }

  Future<void> _addPlayer(BuildContext context, GameController game) async {
    final ctrl = TextEditingController();
    final name = await showMwDialog<String>(
      context,
      builder: (context) => MwDialog(
        title: 'Speler toevoegen',
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textAlign: TextAlign.center,
          style: MwText.t(18,
              weight: MwText.bold, color: context.palette.foreground),
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
            variant: MwButtonVariant.secondary,
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

/// `p-3 rounded-2xl border border-primary/30 bg-primary/10`
class _TurnOrderCard extends StatelessWidget {
  const _TurnOrderCard({required this.order, required this.starter});

  final List<Player> order;
  final Player starter;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(MwRadius.x2),
        border: Border.all(color: p.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BEURTVOLGORDE',
            style: MwText.t(10,
                weight: MwText.black, tracking: 0.1, color: p.primary),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: MwText.t(12,
                  weight: MwText.semibold, color: p.foreground),
              children: [
                TextSpan(
                  text: 'Start bij ${starter.name}',
                  style: MwText.t(12,
                      weight: MwText.black, color: p.foreground),
                ),
                const TextSpan(
                    text: ' en ga daarna verder volgens de nummers.'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < order.length; i++)
                _OrderChip(
                  number: i + 1,
                  name: order[i].name,
                  highlight: i == 0,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `inline-flex items-center gap-2 rounded-full px-3 py-1.5 text-[10px]
/// font-bold border`
class _OrderChip extends StatelessWidget {
  const _OrderChip({
    required this.number,
    required this.name,
    required this.highlight,
  });

  final int number;
  final String name;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = highlight ? p.primaryForeground : p.foreground;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: highlight ? p.primary : p.card,
        borderRadius: BorderRadius.circular(MwRadius.full),
        border: Border.all(color: highlight ? p.primary : p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: highlight
                  ? p.primaryForeground.withValues(alpha: 0.2)
                  : p.secondary,
              shape: BoxShape.circle,
            ),
            child: Text('$number',
                style: MwText.t(10, weight: MwText.bold, color: fg)),
          ),
          const SizedBox(width: 8),
          Text(name, style: MwText.t(10, weight: MwText.bold, color: fg)),
          if (highlight) ...[
            const SizedBox(width: 8),
            Text('START',
                style: MwText.t(10,
                    weight: MwText.bold, tracking: 0.025, color: fg)),
          ],
        ],
      ),
    );
  }
}

/// `pl-2 pr-2 py-3 rounded-xl border-2 … flex flex-row items-center text-left`
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
    final p = context.palette;
    final highlight = peek || isStarter;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: p.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MwRadius.xl),
            side: BorderSide(
              color: highlight ? p.primary : p.border,
              width: 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person_outline,
                        size: 20, color: p.mutedForeground),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          player.name,
                          overflow: TextOverflow.ellipsis,
                          style: MwText.t(14,
                              weight: MwText.bold,
                              height: 1.25,
                              color: p.cardForeground),
                        ),
                        Text(
                          (isStarter ? 'Start Speler' : 'Actief').toUpperCase(),
                          style: MwText.t(10,
                              weight: MwText.medium,
                              tracking: 0.05,
                              color: p.mutedForeground),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // `absolute -top-2 -right-2 w-6 h-6 bg-primary rounded-full
        //  text-xs font-black shadow-md border-2 border-background`
        Positioned(
          top: -8,
          right: -8,
          child: Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.primary,
              shape: BoxShape.circle,
              border: Border.all(color: p.background, width: 2),
              boxShadow: mwShadowMd(),
            ),
            child: Text(
              '$turn',
              style: MwText.t(12,
                  weight: MwText.black, color: p.primaryForeground),
            ),
          ),
        ),
      ],
    );
  }
}

/// `flex justify-between items-center gap-2 p-2 bg-secondary/50 rounded-2xl`
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
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: p.secondary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(MwRadius.x2),
      ),
      child: Row(
        children: [
          _ToolItem(icon: Icons.autorenew, label: 'Woorden', onTap: onWoorden),
          const SizedBox(width: 8),
          _ToolItem(
              icon: Icons.settings_outlined, label: 'Opties', onTap: onOpties),
          const SizedBox(width: 8),
          _ToolItem(
              icon: Icons.person_add_alt, label: 'Speler+', onTap: onSpelerPlus),
          const SizedBox(width: 8),
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

/// `flex-1 flex flex-col items-center justify-center p-2 rounded-xl`
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
    final p = context.palette;
    final fg = active ? p.primaryForeground : p.mutedForeground;
    return Expanded(
      child: Material(
        color: active ? p.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(MwRadius.xl),
        child: InkWell(
          borderRadius: BorderRadius.circular(MwRadius.xl),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24, color: fg),
                const SizedBox(height: 4),
                Text(
                  label.toUpperCase(),
                  style: MwText.t(10, weight: MwText.bold, color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// In-game settings modal ("Instellingen").
class _SettingsDialog extends StatelessWidget {
  const _SettingsDialog();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return MwDialog(
      title: 'Instellingen',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // `flex items-center justify-between p-4 bg-secondary rounded-2xl`
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.secondary,
              borderRadius: BorderRadius.circular(MwRadius.x2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Thema',
                    style: MwText.t(16,
                        weight: MwText.bold, color: p.secondaryForeground),
                  ),
                ),
                const ThemeToggleCircle(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'VERSIE 1.0.5 • MENEER WIT - DOOR ALEX LAMPER',
            textAlign: TextAlign.center,
            style: MwText.t(10,
                weight: MwText.bold,
                tracking: 0.1,
                color: p.mutedForeground),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PhaseTitle('${player.name} - bekijk je kaart', fontSize: 20),
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
    final p = context.palette;
    final game = context.read<GameController>();
    final alive = game.alivePlayers;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PhaseTitle('Wie is verdacht?'),
          const SizedBox(height: 8),
          Text(
            'Klik op een speler om te stemmen. De speler met de meeste stemmen wordt geëlimineerd.',
            style: MwText.t(14, color: p.mutedForeground),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView(
              clipBehavior: Clip.none,
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 0),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                mainAxisExtent: 64,
              ),
              children: [
                for (final pl in alive)
                  _VoteCard(
                      name: pl.name, onTap: () => _confirm(context, game, pl)),
              ],
            ),
          ),
        ],
      ),
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

/// `pl-2 pr-2 py-3 rounded-xl border-2 border-border bg-card shadow-sm`
class _VoteCard extends StatelessWidget {
  const _VoteCard({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MwRadius.xl),
        boxShadow: mwShadowSm(),
      ),
      child: Material(
        color: p.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MwRadius.xl),
          side: BorderSide(color: p.border, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.fingerprint,
                      size: 20, color: p.primaryForeground),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: MwText.t(14,
                            weight: MwText.bold,
                            height: 1.25,
                            color: p.cardForeground),
                      ),
                      Text(
                        'STEMMEN',
                        style: MwText.t(10,
                            weight: MwText.medium,
                            tracking: 0.05,
                            color: p.mutedForeground),
                      ),
                    ],
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

// ---------------------------------------------------------------------------
// Elimination reveal ("X was... ROL")
// ---------------------------------------------------------------------------
class _EliminationView extends StatelessWidget {
  const _EliminationView();

  @override
  Widget build(BuildContext context) {
    final pal = context.palette;
    final game = context.read<GameController>();
    final p = game.lastEliminated!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SingleChildScrollView(
          // `bg-card rounded-[2.5rem] p-8 text-center shadow-2xl border`
          child: Container(
            decoration: BoxDecoration(
              color: pal.card,
              borderRadius: BorderRadius.circular(MwRadius.modal),
              border: Border.all(color: pal.border),
              boxShadow: mwShadow2Xl(),
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${p.name} was...',
                  textAlign: TextAlign.center,
                  style: MwText.t(24,
                      weight: MwText.bold, color: pal.cardForeground),
                ),
                const SizedBox(height: 8),
                // `p-6 bg-secondary rounded-2xl`
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: pal.secondary,
                    borderRadius: BorderRadius.circular(MwRadius.x2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'ROL',
                        style: MwText.t(14,
                            weight: MwText.bold,
                            tracking: 0.1,
                            color: pal.mutedForeground),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p.role.label,
                        textAlign: TextAlign.center,
                        style: MwText.t(36,
                            weight: MwText.black,
                            color: pal.secondaryForeground),
                      ),
                    ],
                  ),
                ),
                if (game.mrWhiteGuessedWrong) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Het woord was niet "${game.mrWhiteGuessAttempt}".',
                    textAlign: TextAlign.center,
                    style: MwText.t(14, color: pal.mutedForeground),
                  ),
                ] else if (p.word != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Woord: ${p.word}',
                    textAlign: TextAlign.center,
                    style: MwText.t(14, color: pal.mutedForeground),
                  ),
                ],
                const SizedBox(height: 32),
                MwButton(
                  label: 'Doorgaan',
                  fontSize: 20,
                  onTap: game.resolveAfterElimination,
                ),
              ],
            ),
          ),
        ),
      ),
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
    final pal = context.palette;
    final game = context.read<GameController>();
    final p = game.lastEliminated!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          // `absolute top-12 text-sm font-bold uppercase tracking-[0.3em]`
          Positioned(
            top: 24,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.5,
              child: Text(
                'ONTMASKERD!',
                textAlign: TextAlign.center,
                style: MwText.t(14,
                    weight: MwText.bold,
                    tracking: 0.3,
                    color: pal.foreground),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${p.name} was Mister White!',
                      textAlign: TextAlign.center,
                      style: MwText.t(48,
                          weight: MwText.black, color: pal.foreground),
                    ),
                    const SizedBox(height: 16),
                    Opacity(
                      opacity: 0.7,
                      child: Text(
                        'Je kunt nog winnen! Raad het woord van de Burgers:',
                        textAlign: TextAlign.center,
                        style: MwText.t(20, color: pal.foreground),
                      ),
                    ),
                    const SizedBox(height: 48),
                    // `p-6 bg-secondary rounded-3xl text-center font-bold
                    //  text-2xl border-2 border-border`
                    TextField(
                      controller: _controller,
                      textAlign: TextAlign.center,
                      textInputAction: TextInputAction.done,
                      style: MwText.t(24,
                          weight: MwText.bold, color: pal.foreground),
                      decoration: InputDecoration(
                        hintText: 'Typ het woord...',
                        hintStyle: MwText.t(24,
                            weight: MwText.bold, color: pal.mutedForeground),
                        contentPadding: const EdgeInsets.all(24),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(MwRadius.x3),
                          borderSide: BorderSide(color: pal.border, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(MwRadius.x3),
                          borderSide: BorderSide(color: pal.border, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(MwRadius.x3),
                          borderSide: BorderSide(color: pal.primary, width: 2),
                        ),
                      ),
                      onSubmitted: game.submitMisterWhiteGuess,
                    ),
                    const SizedBox(height: 32),
                    MwButton(
                      label: 'Bevestig Woord',
                      height: 68,
                      fontSize: 20,
                      shadows: mwShadow2Xl(),
                      onTap: () =>
                          game.submitMisterWhiteGuess(_controller.text),
                    ),
                    const SizedBox(height: 32),
                    TextButton(
                      onPressed: game.skipMisterWhiteGuess,
                      child: Text(
                        'Ik weet het niet',
                        style: MwText.t(16,
                            weight: MwText.bold,
                            color: pal.mutedForeground),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
    final p = context.palette;
    final game = context.read<GameController>();
    final winner = game.winner!;
    return Stack(
      children: [
        Padding(
          // `flex flex-col h-full p-6 items-center justify-center text-center`
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'EINDE SPEL',
                textAlign: TextAlign.center,
                style: MwText.t(14,
                    weight: MwText.bold,
                    tracking: 0.3,
                    color: p.mutedForeground),
              ),
              const SizedBox(height: 16),
              MwGradientText(
                winner.title,
                textAlign: TextAlign.center,
                style: MwText.t(48, weight: MwText.black, height: 1.25),
              ),
              const SizedBox(height: 8),
              Text(
                'Het woord was "${game.wordPair.burger}"',
                textAlign: TextAlign.center,
                style: MwText.t(14, color: p.mutedForeground),
              ),
              const SizedBox(height: 32),
              // `flex justify-between text-[10px] font-bold uppercase
              //  tracking-widest text-muted-foreground px-4 mb-2`
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SectionLabel('Speler'),
                    SectionLabel('Rol & Woord'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // `max-h-[40vh] overflow-y-auto pr-2`
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.4,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(right: 8),
                    itemCount: game.players.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) =>
                        _ResultCard(player: game.players[i]),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MwButton(
                      label: 'Opnieuw spelen',
                      icon: Icons.chevron_right,
                      height: 68,
                      fontSize: 20,
                      onTap: game.nextRound,
                    ),
                    const SizedBox(height: 16),
                    MwButton(
                      label: 'Terug naar start',
                      variant: MwButtonVariant.secondary,
                      onTap: () =>
                          Navigator.of(context).popUntil((r) => r.isFirst),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
            // `confetti` default palette used by the site.
            colors: const [
              Color(0xFF26CCFF),
              Color(0xFFA25AFD),
              Color(0xFFFF5E7E),
              Color(0xFF88FF5A),
              Color(0xFFFCFF42),
              Color(0xFFFFA62D),
              Color(0xFFFF36FF),
            ],
          ),
        ),
      ],
    );
  }
}

/// `flex justify-between items-center p-4 rounded-2xl bg-secondary`
class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Opacity(
      opacity: player.isEliminated ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.secondary,
          borderRadius: BorderRadius.circular(MwRadius.x2),
        ),
        child: Row(
          children: [
            if (player.isEliminated) ...[
              const Text('💀', style: TextStyle(fontSize: 12, height: 1)),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                player.name,
                overflow: TextOverflow.ellipsis,
                style: MwText.t(16,
                    weight: MwText.bold, color: p.secondaryForeground),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  player.role.label,
                  style: MwText.t(14,
                      weight: MwText.black, color: p.secondaryForeground),
                ),
                if (player.word != null)
                  Text(
                    player.word!.toUpperCase(),
                    style: MwText.t(10,
                        weight: MwText.medium,
                        tracking: 0.05,
                        color: p.mutedForeground),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
