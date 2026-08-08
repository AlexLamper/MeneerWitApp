import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';

/// "Uitleg" — mirrors the onboarding modal on meneerwit.com.
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
    final p = context.palette;
    return Scaffold(
      body: MwBackground(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MwHeader(
              title: 'Uitleg',
              fontSize: 24,
              onBack: () => Navigator.of(context).pop(),
              actions: const [ThemeToggleCircle()],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(right: 4),
                itemCount: _steps.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, i) {
                  final (title, body) = _steps[i];
                  // `bg-secondary p-3 rounded-xl`
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: p.secondary,
                      borderRadius: BorderRadius.circular(MwRadius.xl),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: p.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${i + 1}',
                            style: MwText.t(14,
                                weight: MwText.bold,
                                color: p.primaryForeground),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: MwText.t(16,
                                    weight: MwText.bold,
                                    color: p.secondaryForeground),
                              ),
                              Text(
                                body,
                                style:
                                    MwText.t(14, color: p.mutedForeground),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            MwButton(
              label: 'Begrepen!',
              height: 48,
              fontSize: 16,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
