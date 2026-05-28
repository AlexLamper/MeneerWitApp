import 'package:flutter/material.dart';

import '../widgets/common.dart';
import 'explanation_screen.dart';
import 'leaderboard_screen.dart';
import 'rules_screen.dart';
import 'setup_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MwBackground(
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerRight,
              child: ThemeToggleButton(),
            ),
            const Spacer(),
            Image.asset('assets/branding/logo.png', width: 96, height: 96),
            const SizedBox(height: 20),
            const BrandTitle(),
            const SizedBox(height: 14),
            Text(
              'De gratis Nederlandse versie van Undercover & Mister White - met onbeperkte woorden.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: context.palette.mutedForeground,
              ),
            ),
            const SizedBox(height: 18),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                InfoPill(text: '100% Gratis', icon: Icons.auto_awesome),
                InfoPill(text: '3-10 spelers', icon: Icons.group_outlined),
                InfoPill(text: 'Geen account', icon: Icons.lock_open_outlined),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow_rounded, size: 26),
              label: const Text('Speel Nu'),
              onPressed: () => _go(context, const SetupScreen()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _go(context, const RulesScreen()),
                    child: const Text('Regels'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _go(context, const ExplanationScreen()),
                    child: const Text('Uitleg'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.emoji_events_outlined),
              label: const Text('Ranglijst'),
              onPressed: () => _go(context, const LeaderboardScreen()),
            ),
            const SizedBox(height: 24),
            Text(
              'Versie 1.0.1 • Meneer Wit - Door Alex Lamper',
              style: TextStyle(
                fontSize: 11,
                color: context.palette.mutedForeground.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}
