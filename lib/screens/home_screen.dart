import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';
import 'config_screen.dart';
import 'explanation_screen.dart';
import 'leaderboard_screen.dart';
import 'rules_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: MwBackground(
        padding: EdgeInsets.zero,
        bottom: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // `flex flex-col items-center justify-center h-full p-6 text-center`
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ---- Branding block (`mb-16`) ----
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        BrandLogo(size: 48),
                        SizedBox(width: 16),
                        Flexible(child: BrandTitle(fontSize: 36)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'De gratis Nederlandse versie van Undercover & Mister White - met onbeperkte woorden.',
                      textAlign: TextAlign.center,
                      style: MwText.t(
                        14,
                        weight: MwText.medium,
                        tracking: 0.025,
                        color: p.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        InfoPill(text: '100% Gratis', icon: Icons.auto_awesome),
                        InfoPill(text: '3-10 spelers', icon: Icons.group),
                        InfoPill(text: 'Geen account', icon: Icons.lock_open),
                      ],
                    ),
                    const SizedBox(height: 64),
                    // ---- Action block (`w-full max-w-xs`) ----
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: MwButton(
                              label: 'Speel Nu',
                              icon: Icons.chevron_right,
                              // `shadow-xl shadow-primary/25`
                              shadows: mwShadowXl(p.primary, 0.25),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const ConfigScreen()),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Versie 1.0.4 • Meneer Wit - Door Alex Lamper'
                                .toUpperCase(),
                            textAlign: TextAlign.center,
                            style: MwText.t(
                              10,
                              weight: MwText.bold,
                              tracking: 0.1,
                              color: p.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // `fixed top-4 right-4 z-50`
            const Positioned(top: 16, right: 16, child: ThemeToggleCircle()),
            // `fixed bottom-0 left-0 right-0`
            const Positioned(left: 0, right: 0, bottom: 0, child: _BottomNav()),
          ],
        ),
      ),
    );
  }
}

/// `p-4 bg-background/80 backdrop-blur-2xl border-t border-border/40
/// flex justify-around items-center shadow-[0_-8px_30px_rgba(0,0,0,0.06)]`
class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: p.background.withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(color: p.border.withValues(alpha: 0.4)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 30,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.menu_book_outlined,
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
            ),
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

/// `flex flex-col items-center gap-1` with a `w-10 h-10 rounded-xl bg-secondary`
/// icon tile.
class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      borderRadius: BorderRadius.circular(MwRadius.xl),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: p.secondary,
                borderRadius: BorderRadius.circular(MwRadius.xl),
                boxShadow: mwShadowSm(),
              ),
              child: Icon(icon, size: 20, color: p.secondaryForeground),
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: MwText.t(
                10,
                weight: MwText.bold,
                tracking: 0.1,
                color: p.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
