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
    final icon = mode == ThemeMode.dark
        ? Icons.dark_mode_outlined
        : Icons.light_mode_outlined;
    return IconButton(
      tooltip: 'Thema wisselen',
      icon: Icon(icon),
      onPressed: () => context.read<AppState>().cycleTheme(),
    );
  }
}

/// App logo: rounded square with a subtle border so it stays visible in dark
/// mode, mirroring meneerwit.com. Larger corner radius than a plain image.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = context.scheme.brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E1A),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.5 : 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset('assets/branding/logo.png', fit: BoxFit.cover),
    );
  }
}

/// Small circular icon button used in top bars (theme / quit / etc.).
class MwCircleButton extends StatelessWidget {
  const MwCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: context.palette.muted,
        shape: CircleBorder(side: BorderSide(color: context.palette.border)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: context.scheme.onSurface),
          ),
        ),
      ),
    );
  }
}

/// Theme toggle as a circular button (matches the in-game top bar style).
class ThemeToggleCircle extends StatelessWidget {
  const ThemeToggleCircle({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.select<AppState, ThemeMode>((s) => s.themeMode);
    return MwCircleButton(
      tooltip: 'Thema wisselen',
      icon: mode == ThemeMode.dark
          ? Icons.dark_mode_outlined
          : Icons.light_mode_outlined,
      onPressed: () => context.read<AppState>().cycleTheme(),
    );
  }
}

/// Destructive red used by confirm dialogs (matches meneerwit.com).
const kMwDestructive = Color(0xFFEF4343);

enum MwButtonVariant { primary, destructive, muted }

/// Large, full-width stacked dialog button.
class MwDialogButton extends StatelessWidget {
  const MwDialogButton({
    super.key,
    required this.label,
    required this.onTap,
    this.variant = MwButtonVariant.primary,
  });

  final String label;
  final VoidCallback onTap;
  final MwButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    switch (variant) {
      case MwButtonVariant.primary:
        bg = context.scheme.primary;
        fg = context.scheme.onPrimary;
      case MwButtonVariant.destructive:
        bg = kMwDestructive;
        fg = Colors.white;
      case MwButtonVariant.muted:
        bg = context.palette.muted;
        fg = context.scheme.onSurface;
    }
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared dialog shell: dark rounded card, bold centered title, centered
/// message and full-width stacked action buttons (meneerwit.com style).
class MwDialog extends StatelessWidget {
  const MwDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    required this.actions,
  });

  final String title;
  final String? message;
  final Widget? content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.palette.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: context.palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: context.palette.mutedForeground,
                ),
              ),
            ],
            if (content != null) ...[
              const SizedBox(height: 18),
              content!,
            ],
            const SizedBox(height: 24),
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              actions[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Confirm dialog using the shared style. Returns true on confirm.
Future<bool> showMwConfirm(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmText,
  String cancelText = 'Annuleren',
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => MwDialog(
      title: title,
      message: message,
      actions: [
        MwDialogButton(
          label: confirmText,
          variant: destructive
              ? MwButtonVariant.destructive
              : MwButtonVariant.primary,
          onTap: () => Navigator.pop(context, true),
        ),
        MwDialogButton(
          label: cancelText,
          variant: MwButtonVariant.muted,
          onTap: () => Navigator.pop(context, false),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Confirmation dialog shown before abandoning a running game.
Future<bool> confirmQuitGame(BuildContext context) => showMwConfirm(
      context,
      title: 'Spel stoppen?',
      message: 'Weet je zeker dat je wilt stoppen? De huidige ronde gaat verloren.',
      confirmText: 'Stoppen',
      destructive: true,
    );

/// Uppercase, letter-spaced section label used across config / game screens.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.3,
        color: context.palette.mutedForeground,
      ),
    );
  }
}

/// Brand title "Meneer Wit" with the gradient/indigo accent on "Wit".
class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key, this.fontSize = 44});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final dark = context.scheme.brightness == Brightness.dark;
    // Light: black -> gray. Dark: white -> slightly gray. Left to right.
    final colors = dark
        ? const [Color(0xFFFFFFFF), Color(0xFFC2C9D6)]
        : const [Color(0xFF0A0E1A), Color(0xFF6B7280)];
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: colors,
      ).createShader(bounds),
      child: Text(
        'Meneer Wit',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Geist',
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.5,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// A small pill chip used for stats / tags.
class InfoPill extends StatelessWidget {
  const InfoPill({super.key, required this.text, this.icon, this.compact = false});

  final String text;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 12,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: context.palette.muted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon,
                size: compact ? 12 : 14,
                color: context.palette.mutedForeground),
            SizedBox(width: compact ? 4 : 6),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: compact ? 11 : 12.5,
              fontWeight: FontWeight.w600,
              color: context.palette.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
