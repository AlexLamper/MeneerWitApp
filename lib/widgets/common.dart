import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../storage/app_storage.dart';
import '../theme.dart';

extension ThemeAccess on BuildContext {
  ColorScheme get scheme => Theme.of(this).colorScheme;
  MwPalette get palette => Theme.of(this).extension<MwPalette>()!;
}

/// Subtle gradient background + centered, phone-width content column.
class MwBackground extends StatelessWidget {
  const MwBackground({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final dark = scheme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.surface,
            Color.alphaBlend(
              scheme.primary.withValues(alpha: dark ? 0.10 : 0.06),
              scheme.surface,
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(20),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.select<AppState, ThemeMode>((s) => s.themeMode);
    final icon = switch (mode) {
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
      ThemeMode.system => Icons.brightness_auto_outlined,
    };
    return IconButton(
      tooltip: 'Thema wisselen',
      icon: Icon(icon),
      onPressed: () => context.read<AppState>().cycleTheme(),
    );
  }
}

/// Brand title "Meneer Wit" with the gradient/indigo accent on "Wit".
class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key, this.fontSize = 44});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Geist',
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.5,
          color: context.scheme.onSurface,
        ),
        children: [
          const TextSpan(text: 'Meneer '),
          TextSpan(
            text: 'Wit',
            style: TextStyle(color: context.scheme.primary),
          ),
        ],
      ),
    );
  }
}

/// A small pill chip used for stats / tags.
class InfoPill extends StatelessWidget {
  const InfoPill({super.key, required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: context.palette.muted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: context.palette.mutedForeground),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: context.palette.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
