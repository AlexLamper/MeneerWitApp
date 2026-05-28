import 'package:flutter/material.dart';

import '../widgets/common.dart';

class ExplanationScreen extends StatelessWidget {
  const ExplanationScreen({super.key});

  static const _steps = [
    (
      'Voeg spelers toe',
      'Voeg 3 tot 10 spelers toe en stel het aantal Undercovers en Mister Whites in.',
    ),
    (
      'Bekijk je kaart',
      'Geef het apparaat door. Iedereen bekijkt in het geheim zijn kaart. Zorg dat niemand meekijkt!',
    ),
    (
      'Geef hints',
      'Om de beurt geeft iedereen één woord als hint dat bij zijn woord past - maar niet te duidelijk!',
    ),
    (
      'Stem',
      'Na een ronde stemt iedereen op wie ze denken dat een indringer is. De speler met de meeste stemmen wordt geëlimineerd.',
    ),
    (
      'Mister White raadt',
      'Wordt Mister White betrapt? Dan mag hij het woord van de Burgers raden om alsnog te winnen.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Uitleg')),
      body: MwBackground(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: ListView.separated(
          itemCount: _steps.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final (title, body) = _steps[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: context.scheme.primary,
                      foregroundColor: context.scheme.onPrimary,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            body,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: context.palette.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
