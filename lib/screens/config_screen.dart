import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/word_repository.dart';
import '../game/game_controller.dart';
import '../models/game_models.dart';
import '../storage/app_storage.dart';
import '../theme.dart';
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
    final p = context.palette;
    final cats = WordRepository.instance.categories;
    final maxInfiltrators = _count - 2;

    return Scaffold(
      body: MwBackground(
        // `flex flex-col h-full p-4`
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MwHeader(
              title: 'Spelconfiguratie',
              onBack: () => Navigator.of(context).pop(),
              actions: const [ThemeToggleCircle()],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(right: 8),
                children: [
                  // ----- Player count -----
                  const SectionLabel('Aantal spelers'),
                  const SizedBox(height: 4),
                  Text(
                    '$_count spelers',
                    style: MwText.t(30, weight: MwText.bold),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _count.toDouble(),
                    min: 3,
                    max: 10,
                    divisions: 7,
                    onChanged: (v) => _setCount(v.round()),
                  ),
                  const SizedBox(height: 12),
                  // ----- Roles -----
                  const SectionLabel('Rolverdeling'),
                  const SizedBox(height: 8),
                  _RoleRow(
                    label: 'Burgers',
                    sub: 'Hebben het woord',
                    value: _burgers,
                    onMinus: _burgers > 2 ? () => _setCount(_count - 1) : null,
                    onPlus: _count < 10 ? () => _setCount(_count + 1) : null,
                  ),
                  const SizedBox(height: 8),
                  _RoleRow(
                    label: 'Undercovers',
                    sub: 'Hebben een ander woord',
                    value: _settings.undercoverCount,
                    onMinus: _settings.undercoverCount > 0
                        ? () => setState(() => _settings.undercoverCount--)
                        : null,
                    onPlus: _settings.undercoverCount + _settings.mrWhiteCount <
                            maxInfiltrators
                        ? () => setState(() => _settings.undercoverCount++)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  _RoleRow(
                    label: 'Mister White',
                    sub: 'Heeft geen woord',
                    value: _settings.mrWhiteCount,
                    onMinus: _settings.mrWhiteCount > 0
                        ? () => setState(() => _settings.mrWhiteCount--)
                        : null,
                    onPlus: _settings.undercoverCount + _settings.mrWhiteCount <
                            maxInfiltrators
                        ? () => setState(() => _settings.mrWhiteCount++)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  // ----- Category -----
                  const SectionLabel('Woord categorie'),
                  const SizedBox(height: 8),
                  MwSelect<String>(
                    value: _settings.category,
                    items: cats,
                    labelOf: (c) => c,
                    onChanged: (v) => setState(
                      () => _settings.category = v ?? 'Algemeen',
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ----- Custom words -----
                  const SectionLabel('Eigen woorden (optioneel)'),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _burgerWord,
                          onChanged: (_) => setState(() {}),
                          style: MwText.t(14,
                              weight: MwText.bold, color: p.foreground),
                          decoration: const InputDecoration(hintText: 'Burger'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _underWord,
                          onChanged: (_) => setState(() {}),
                          style: MwText.t(14,
                              weight: MwText.bold, color: p.foreground),
                          decoration:
                              const InputDecoration(hintText: 'Undercover'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // ----- Mister White hint -----
                  const SectionLabel('Mister White hint'),
                  const SizedBox(height: 6),
                  MwToggleRow(
                    title: 'Hint voor Mister White',
                    subtitle: _settings.misterWhiteHintEnabled
                        ? 'Aan: Mister White ziet de categorie van het woord'
                        : 'Uit: standaard gameplay zonder hint',
                    value: _settings.misterWhiteHintEnabled,
                    onChanged: (v) =>
                        setState(() => _settings.misterWhiteHintEnabled = v),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // `mt-2 w-full py-3 bg-primary rounded-xl font-bold text-lg`
            MwButton(
              label: 'Start spel',
              icon: Icons.chevron_right,
              height: 52,
              radius: MwRadius.xl,
              onTap: _start,
            ),
          ],
        ),
      ),
    );
  }
}

/// `flex items-center justify-between p-2 bg-secondary rounded-xl`
class _RoleRow extends StatelessWidget {
  const _RoleRow({
    required this.label,
    required this.sub,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String sub;
  final int value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: p.secondary,
        borderRadius: BorderRadius.circular(MwRadius.xl),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: MwText.t(12,
                      weight: MwText.bold, color: p.secondaryForeground),
                ),
                Text(sub, style: MwText.t(10, color: p.mutedForeground)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          MwStepperButton(icon: Icons.remove, onTap: onMinus),
          const SizedBox(width: 8),
          SizedBox(
            width: 20,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: MwText.t(16,
                  weight: MwText.bold, color: p.secondaryForeground),
            ),
          ),
          const SizedBox(width: 8),
          MwStepperButton(icon: Icons.add, onTap: onPlus),
        ],
      ),
    );
  }
}
