import 'package:flutter/material.dart';

import '../models/game_models.dart';
import '../widgets/common.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Regels')),
      body: MwBackground(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: ListView(
          children: [
            Text(
              'Meneer Wit is een spel van misleiding en deductie. Er zijn drie rollen:',
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: context.palette.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            _RoleCardInfo(role: Role.burger),
            const SizedBox(height: 10),
            _RoleCardInfo(role: Role.undercover),
            const SizedBox(height: 10),
            _RoleCardInfo(role: Role.misterWhite),
            const SizedBox(height: 24),
            const _Section(
              title: 'Doel van het spel',
              body:
                  'De Burgers proberen de indringers te ontmaskeren. De Undercovers en Mister White proberen onopgemerkt te blijven. Mister White kan ook winnen door het geheime woord te raden.',
            ),
            _Section(
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
    );
  }
}

class _RoleCardInfo extends StatelessWidget {
  const _RoleCardInfo({required this.role});

  final Role role;

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      Role.burger => context.scheme.primary,
      Role.undercover => const Color(0xFFF59E0B),
      Role.misterWhite => context.palette.mutedForeground,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role.description,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
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
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: context.palette.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
