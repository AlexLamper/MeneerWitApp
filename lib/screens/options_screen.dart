import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/word_repository.dart';
import '../game/game_controller.dart';
import '../models/game_models.dart';
import '../storage/app_storage.dart';
import '../widgets/common.dart';
import 'game_screen.dart';

class OptionsScreen extends StatefulWidget {
  const OptionsScreen({super.key, required this.names});

  final List<String> names;

  @override
  State<OptionsScreen> createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  late GameSettings _settings;
  final _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _settings = context.read<AppState>().loadSettings();
    final cats = WordRepository.instance.categories;
    if (!cats.contains(_settings.category)) {
      _settings.category = cats.isNotEmpty ? cats.first : 'Algemeen';
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  List<WordPair> _parseCustom() {
    final pairs = <WordPair>[];
    for (final line in _customController.text.split('\n')) {
      final parts = line.split(',').map((e) => e.trim()).toList();
      if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        pairs.add(WordPair(parts[0], parts[1]));
      }
    }
    return pairs;
  }

  void _start() {
    final total = widget.names.length;
    final error = _settings.validate(total);
    final custom = _settings.useCustomWords ? _parseCustom() : <WordPair>[];
    if (_settings.useCustomWords && custom.isEmpty) {
      _snack('Voeg minimaal één eigen woordpaar toe (burger, undercover).');
      return;
    }
    if (error != null) {
      _snack(error);
      return;
    }
    context.read<AppState>().saveSettings(_settings);
    context.read<GameController>().startGame(
          names: widget.names,
          gameSettings: _settings,
          custom: custom,
        );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.names.length;
    final burgers = _settings.burgerCount(total);
    final cats = WordRepository.instance.categories;

    return Scaffold(
      appBar: AppBar(title: const Text('Opties')),
      body: MwBackground(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                children: [
                  _RolesSummary(
                    burgers: burgers,
                    undercover: _settings.undercoverCount,
                    misterWhite: _settings.mrWhiteCount,
                  ),
                  const SizedBox(height: 16),
                  _StepperTile(
                    label: 'Undercovers',
                    sub: 'Krijgen een lijkend woord',
                    value: _settings.undercoverCount,
                    min: 0,
                    max: total - 2,
                    onChanged: (v) =>
                        setState(() => _settings.undercoverCount = v),
                  ),
                  const SizedBox(height: 10),
                  _StepperTile(
                    label: 'Mister Whites',
                    sub: 'Krijgen geen woord',
                    value: _settings.mrWhiteCount,
                    min: 0,
                    max: total - 2,
                    onChanged: (v) =>
                        setState(() => _settings.mrWhiteCount = v),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: SwitchListTile(
                      value: _settings.misterWhiteHintEnabled,
                      onChanged: (v) =>
                          setState(() => _settings.misterWhiteHintEnabled = v),
                      title: const Text('Hint voor Mister White'),
                      subtitle: Text(
                        _settings.misterWhiteHintEnabled
                            ? 'Aan: Mister White ziet de categorie van het woord'
                            : 'Uit: standaard gameplay zonder hint',
                        style: TextStyle(
                          color: context.palette.mutedForeground,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Kies woord categorie',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: context.palette.mutedForeground,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _settings.category,
                          items: [
                            for (final c in cats)
                              DropdownMenuItem(value: c, child: Text(c)),
                          ],
                          onChanged: _settings.useCustomWords
                              ? null
                              : (v) => setState(
                                    () => _settings.category = v ?? 'Algemeen',
                                  ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: SwitchListTile(
                      value: _settings.useCustomWords,
                      onChanged: (v) =>
                          setState(() => _settings.useCustomWords = v),
                      title: const Text('Eigen Woorden (Optioneel)'),
                      subtitle: Text(
                        'Gebruik je eigen woordparen i.p.v. een categorie',
                        style: TextStyle(
                          color: context.palette.mutedForeground,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                  if (_settings.useCustomWords) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _customController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText:
                            'Eén paar per regel:\nappel, peer\nfiets, scooter',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start spel'),
              onPressed: _start,
            ),
          ],
        ),
      ),
    );
  }
}

class _RolesSummary extends StatelessWidget {
  const _RolesSummary({
    required this.burgers,
    required this.undercover,
    required this.misterWhite,
  });

  final int burgers;
  final int undercover;
  final int misterWhite;

  @override
  Widget build(BuildContext context) {
    final invalid = burgers < 2;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat(context, '$burgers', 'Burgers',
                invalid ? context.scheme.error : context.scheme.primary),
            _stat(context, '$undercover', 'Undercover',
                context.palette.mutedForeground),
            _stat(context, '$misterWhite', 'Mister White',
                context.palette.mutedForeground),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: context.palette.mutedForeground,
          ),
        ),
      ],
    );
  }
}

class _StepperTile extends StatelessWidget {
  const _StepperTile({
    required this.label,
    required this.sub,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final String sub;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(sub,
                      style: TextStyle(
                          fontSize: 12, color: context.palette.mutedForeground)),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: value > min ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 34,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            IconButton.filledTonal(
              onPressed: value < max ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}
