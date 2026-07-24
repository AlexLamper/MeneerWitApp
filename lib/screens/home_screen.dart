import 'package:flutter/material.dart';

import '../widgets/common.dart';
import 'config_screen.dart';
import 'explanation_screen.dart';
import 'leaderboard_screen.dart';
import 'rules_screen.dart';

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
              child: ThemeToggleCircle(),
            ),
            const Spacer(),
            // Logo to the LEFT of the title (both compact), mirroring the site.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                BrandLogo(size: 60),
                SizedBox(width: 16),
                Flexible(child: BrandTitle(fontSize: 38)),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'De gratis Nederlandse versie van Undercover & Mister White - met onbeperkte woorden.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.4,
                color: context.palette.mutedForeground,
              ),
            ),
            const SizedBox(height: 18),
            // Compact badges so all three fit on one row.
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InfoPill(text: '100% Gratis', icon: Icons.auto_awesome, compact: true),
                SizedBox(width: 8),
                InfoPill(text: '3-10 spelers', icon: Icons.group_outlined, compact: true),
                SizedBox(width: 8),
                InfoPill(text: 'Geen account', icon: Icons.lock_open_outlined, compact: true),
              ],
            ),
            const Spacer(),
            // Speel Nu with a coloured glow, slightly taller.
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: context.scheme.primary.withValues(alpha: 0.55),
                    blurRadius: 32,
                    spreadRadius: 1,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SizedBox(
                height: 64,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded, size: 26),
                  label: const Text('Speel Nu'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ConfigScreen()),
                  ),
                ),
              ),
            ),
            const Spacer(),
            _BottomNav(),
            const SizedBox(height: 8),
            Text(
              'Versie 1.0.4 • Meneer Wit - Door Alex Lamper',
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
}

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.palette.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.fact_check_outlined,
            label: 'Regels',
            onTap: () => _go(context, const RulesScreen()),
          ),
          _NavItem(
            icon: Icons.help_outline,
            label: 'Uitleg',
            onTap: () => _go(context, const ExplanationScreen()),
          ),
          _NavItem(
            icon: Icons.emoji_events_outlined,
            label: 'Ranglijst',
            onTap: () => _go(context, const LeaderboardScreen()),
          ),
        ],
      ),
    );
  }

  void _go(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: context.scheme.onSurface),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: context.palette.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
