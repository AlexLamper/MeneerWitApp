import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/word_repository.dart';
import '../game/game_controller.dart';
import '../models/game_models.dart';
import '../storage/app_storage.dart';
import '../widgets/common.dart';
import 'game_screen.dart';

/// "Spelconfiguratie" — set player count, role distribution, category, custom
/// words and the Mister White hint. Names are entered later, per-player.
class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  int _count = 3;
  late GameSettings _settings;
  final _burgerWord = TextEditingController();
  final _underWord = TextEditingController();

  int get _burgers => _count - _settings.undercoverCount - _settings.mrWhiteCount;

  @override
  void initState() {
    super.initState();
    _settings = context.read<AppState>().loadSettings();
    final cats = WordRepository.instance.categories;
    if (!cats.contains(_settings.category)) {
      _settings.category = cats.isNotEmpty ? cats.first : 'Algemeen';
    }
    // Make sure the loaded settings fit the default player count.
    _clampRoles();
  }

  @override
  void dispose() {
    _burgerWord.dispose();
    _underWord.dispose();
    super.dispose();
  }

  void _clampRoles() {
    final maxInfiltrators = _count - 2;
    if (_settings.undercoverCount + _settings.mrWhiteCount > maxInfiltrators) {
      _settings.mrWhiteCount =
          (maxInfiltrators - _settings.undercoverCount).clamp(0, maxInfiltrators);
      if (_settings.undercoverCount > maxInfiltrators) {
        _settings.undercoverCount = maxInfiltrators.clamp(0, maxInfiltrators);
        _settings.mrWhiteCount = 0;
      }
    }
  }

  void _setCount(int v) {
    setState(() {
      _count = v.clamp(3, 10);
      _clampRoles();
    });
  }

  void _start() {
    final useCustom =
        _burgerWord.text.trim().isNotEmpty && _underWord.text.trim().isNotEmpty;
    _settings.useCustomWords = useCustom;
    final custom = useCustom
        ? [WordPair(_burgerWord.text.trim(), _underWord.text.trim())]
        : <WordPair>[];

    final error = _settings.validate(_count);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    context.read<AppState>().saveSettings(_settings);
    context.read<GameController>().configureGame(
          count: _count,
          gameSettings: _settings,
          custom: custom,
        );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cats = WordRepository.instance.categories;
    final maxInfiltrators = _count - 2;

    return Scaffold(
      body: MwBackground(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top bar.
            Row(
              children: [
                MwCircleButton(
                  icon: Icons.arrow_back,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Spelconfiguratie',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                ),
                const ThemeToggleCircle(),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  // ----- Player count -----
                  const SectionLabel('Aantal spelers'),
                  const SizedBox(height: 6),
                  Text(
                    '$_count spelers',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      activeTrackColor: context.scheme.primary,
                      inactiveTrackColor: context.scheme.onSurface
                          .withValues(alpha: 0.18),
                      thumbColor: context.scheme.primary,
                      overlayColor:
                          context.scheme.primary.withValues(alpha: 0.15),
                    ),
                    child: Slider(
                      value: _count.toDouble(),
                      min: 3,
                      max: 10,
                      divisions: 7,
                      label: '$_count',
                      onChanged: (v) => _setCount(v.round()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // ----- Roles -----
                  const SectionLabel('Rolverdeling'),
                  const SizedBox(height: 8),
                  _RoleRow(
                    label: 'Burgers',
                    sub: 'Hebben het woord',
                    value: _burgers,
                    color: context.scheme.onSurface,
                    onMinus: _burgers > 2 ? () => _setCount(_count - 1) : null,
                    onPlus: _count < 10 ? () => _setCount(_count + 1) : null,
                  ),
                  const SizedBox(height: 10),
                  _RoleRow(
                    label: 'Undercovers',
                    sub: 'Hebben een ander woord',
                    value: _settings.undercoverCount,
                    color: context.scheme.onSurface,
                    onMinus: _settings.undercoverCount > 0
                        ? () => setState(() => _settings.undercoverCount--)
                        : null,
                    onPlus: _settings.undercoverCount + _settings.mrWhiteCount <
                            maxInfiltrators
                        ? () => setState(() => _settings.undercoverCount++)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  _RoleRow(
                    label: 'Mister White',
                    sub: 'Heeft geen woord',
                    value: _settings.mrWhiteCount,
                    color: context.scheme.onSurface,
                    onMinus: _settings.mrWhiteCount > 0
                        ? () => setState(() => _settings.mrWhiteCount--)
                        : null,
                    onPlus: _settings.undercoverCount + _settings.mrWhiteCount <
                            maxInfiltrators
                        ? () => setState(() => _settings.mrWhiteCount++)
                        : null,
                  ),
                  const SizedBox(height: 18),
                  // ----- Category -----
                  const SectionLabel('Woord categorie'),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _settings.category,
                          items: [
                            for (final c in cats)
                              DropdownMenuItem(value: c, child: Text(c)),
                          ],
                          onChanged: (v) => setState(
                            () => _settings.category = v ?? 'Algemeen',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // ----- Custom words -----
                  const SectionLabel('Eigen woorden (optioneel)'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _burgerWord,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(hintText: 'Burger'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _underWord,
                          onChanged: (_) => setState(() {}),
                          decoration:
                              const InputDecoration(hintText: 'Undercover'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // ----- Mister White hint -----
                  const SectionLabel('Mister White hint'),
                  const SizedBox(height: 8),
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
                ],
              ),
            ),
            const SizedBox(height: 10),
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

class _RoleRow extends StatelessWidget {
  const _RoleRow({
    required this.label,
    required this.sub,
    required this.value,
    required this.color,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String sub;
  final int value;
  final Color color;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

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
                          fontSize: 12,
                          color: context.palette.mutedForeground)),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: onMinus,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 34,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
            IconButton.filledTonal(
              onPressed: onPlus,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}
