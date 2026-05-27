import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../storage/app_storage.dart';
import '../widgets/common.dart';
import 'options_screen.dart';

const _maxPlayers = 10;
const _minPlayers = 3;

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final List<String> _names = [];
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final name = raw.trim();
    if (name.isEmpty) return;
    if (_names.length >= _maxPlayers) {
      setState(() => _error = 'Maximaal $_maxPlayers spelers.');
      return;
    }
    if (_names.any((n) => n.toLowerCase() == name.toLowerCase())) {
      setState(() => _error = 'Deze naam is al gekozen! Kies een andere naam.');
      return;
    }
    setState(() {
      _names.add(name);
      _error = null;
      _controller.clear();
    });
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final known = context
        .watch<AppState>()
        .knownPlayerNames
        .where((n) => !_names.any((x) => x.toLowerCase() == n.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Spelers')),
      body: MwBackground(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      hintText: 'Naam van speler',
                    ),
                    onSubmitted: _add,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(56, 56),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () => _add(_controller.text),
                    child: const Icon(Icons.add, size: 28),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: context.scheme.error, fontSize: 13),
              ),
            ],
            if (known.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                'Of kies een bekende speler',
                style: TextStyle(
                  fontSize: 13,
                  color: context.palette.mutedForeground,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final n in known)
                    ActionChip(
                      label: Text(n),
                      onPressed: () => _add(n),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            Text(
              'Spelers (${_names.length})',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _names.isEmpty
                  ? Center(
                      child: Text(
                        'Voeg minimaal $_minPlayers spelers toe om te spelen.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.palette.mutedForeground),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _names.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: context.scheme.primary,
                            foregroundColor: context.scheme.onPrimary,
                            child: Text('${i + 1}'),
                          ),
                          title: Text(
                            _names[i],
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _names.removeAt(i)),
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _names.length >= _minPlayers
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OptionsScreen(names: _names),
                        ),
                      )
                  : null,
              child: const Text('Verder'),
            ),
          ],
        ),
      ),
    );
  }
}
