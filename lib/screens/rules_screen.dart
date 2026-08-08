import 'package:flutter/material.dart';

import '../models/game_models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// "Spelregels" — mirrors the rules modal on meneerwit.com.
class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

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
              title: 'Spelregels',
              fontSize: 24,
              onBack: () => Navigator.of(context).pop(),
              actions: const [ThemeToggleCircle()],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(right: 4),
                children: [
                  Text(
                    'Meneer Wit is een spel van misleiding en deductie. Er zijn drie rollen:',
                    style: MwText.t(14, color: p.mutedForeground),
                  ),
                  const SizedBox(height: 24),
                  const _Heading('De Rollen'),
                  const SizedBox(height: 8),
                  const _RoleCardInfo(role: Role.burger),
                  const SizedBox(height: 8),
                  const _RoleCardInfo(role: Role.undercover),
                  const SizedBox(height: 8),
                  const _RoleCardInfo(role: Role.misterWhite),
                  const SizedBox(height: 24),
                  const _Section(
                    title: 'Doel van het spel',
                    body:
                        'De Burgers proberen de indringers te ontmaskeren. De Undercovers en Mister White proberen onopgemerkt te blijven. Mister White kan ook winnen door het geheime woord te raden.',
                  ),
                  const _Section(
                    title: 'Wie wint?',
                    body:
                        '• Burgers winnen als alle Undercovers én Mister Whites zijn uitgeschakeld.\n'
                        '• Infiltranten winnen zodra er nog maar één Burger over is.\n'
                        '• Mister White wint direct als hij na ontmaskering het woord van de Burgers correct raadt.',
                  ),
                  const _Section(
                    title: 'Mister White Hint',
                    body:
                        'Als Mister White wordt betrapt, krijgt hij nog één kans om het woord van de Burgers te raden en alsnog te winnen!',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // `mt-6 w-full py-3 bg-primary rounded-2xl font-bold`
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

/// `font-bold text-foreground uppercase tracking-wider text-xs`
class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: MwText.t(
        12,
        weight: MwText.bold,
        tracking: 0.05,
        color: context.palette.foreground,
      ),
    );
  }
}

/// `p-3 bg-secondary rounded-2xl`
class _RoleCardInfo extends StatelessWidget {
  const _RoleCardInfo({required this.role});

  final Role role;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final emoji = switch (role) {
      Role.burger => '🍔',
      Role.undercover => '🕵️',
      Role.misterWhite => '⚪',
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.secondary,
        borderRadius: BorderRadius.circular(MwRadius.x2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$emoji ${role.label}',
            style: MwText.t(14,
                weight: MwText.bold, color: p.secondaryForeground),
          ),
          Text(
            role.description,
            style: MwText.t(12, color: p.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Heading(title),
          const SizedBox(height: 8),
          Text(
            body,
            style: MwText.t(14, color: context.palette.mutedForeground),
          ),
        ],
      ),
    );
  }
}
