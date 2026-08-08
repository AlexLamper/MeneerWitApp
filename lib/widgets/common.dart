import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../storage/app_storage.dart';
import '../theme.dart';

extension ThemeAccess on BuildContext {
  ColorScheme get scheme => Theme.of(this).colorScheme;
  MwPalette get palette => Theme.of(this).extension<MwPalette>()!;
}

// ---------------------------------------------------------------------------
// Tailwind box shadows
// ---------------------------------------------------------------------------

/// `shadow-sm`
List<BoxShadow> mwShadowSm([Color c = Colors.black]) => [
      BoxShadow(color: c.withValues(alpha: 0.1), blurRadius: 3, offset: const Offset(0, 1)),
      BoxShadow(
          color: c.withValues(alpha: 0.1),
          blurRadius: 2,
          spreadRadius: -1,
          offset: const Offset(0, 1)),
    ];

/// `shadow-md`
List<BoxShadow> mwShadowMd([Color c = Colors.black]) => [
      BoxShadow(
          color: c.withValues(alpha: 0.1),
          blurRadius: 6,
          spreadRadius: -1,
          offset: const Offset(0, 4)),
      BoxShadow(
          color: c.withValues(alpha: 0.1),
          blurRadius: 4,
          spreadRadius: -2,
          offset: const Offset(0, 2)),
    ];

/// `shadow-lg`
List<BoxShadow> mwShadowLg([Color c = Colors.black, double a = 0.1]) => [
      BoxShadow(
          color: c.withValues(alpha: a),
          blurRadius: 15,
          spreadRadius: -3,
          offset: const Offset(0, 10)),
      BoxShadow(
          color: c.withValues(alpha: a),
          blurRadius: 6,
          spreadRadius: -4,
          offset: const Offset(0, 4)),
    ];

/// `shadow-xl` (optionally tinted, e.g. `shadow-primary/25`)
List<BoxShadow> mwShadowXl([Color c = Colors.black, double a = 0.1]) => [
      BoxShadow(
          color: c.withValues(alpha: a),
          blurRadius: 25,
          spreadRadius: -5,
          offset: const Offset(0, 20)),
      BoxShadow(
          color: c.withValues(alpha: a),
          blurRadius: 10,
          spreadRadius: -6,
          offset: const Offset(0, 8)),
    ];

/// `shadow-2xl`
List<BoxShadow> mwShadow2Xl([Color c = Colors.black, double a = 0.25]) => [
      BoxShadow(
          color: c.withValues(alpha: a),
          blurRadius: 50,
          spreadRadius: -12,
          offset: const Offset(0, 25)),
    ];

// ---------------------------------------------------------------------------
// Page shell
// ---------------------------------------------------------------------------

/// The site's page shell: `body` background plus its radial glow
/// (`radial-gradient(140% 60% at 50% -10%, …)`), with the content column
/// capped at `md:max-w-md` (28rem).
class MwBackground extends StatelessWidget {
  const MwBackground({
    super.key,
    required this.child,
    this.padding,
    this.top = true,
    this.bottom = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool top;
  final bool bottom;

  /// `md:max-w-md` — 28rem.
  static const maxWidth = 448.0;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.palette.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _BodyGlow(),
          SafeArea(
            top: top,
            bottom: bottom,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(24),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `body { background-image: radial-gradient(<rx> 60% at 50% -10%, glow 0%, transparent <stop>) }`
///
/// Flutter's [RadialGradient] is circular, so the ellipse is built by painting
/// a circle in a square the size of the vertical radius and stretching it
/// horizontally.
class _BodyGlow extends StatelessWidget {
  const _BodyGlow();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final rx = p.glowRadiusX * w;
        final ry = 0.60 * h;
        final centerX = 0.5 * w;
        final centerY = -0.10 * h;
        return ClipRect(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: centerX - ry,
                top: centerY - ry,
                width: 2 * ry,
                height: 2 * ry,
                child: Transform.scale(
                  scaleX: ry == 0 ? 1 : rx / ry,
                  scaleY: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        radius: 0.5,
                        colors: [p.glow, p.glow.withValues(alpha: 0)],
                        stops: [0, p.glowStop],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Text helpers
// ---------------------------------------------------------------------------

/// `bg-clip-text text-transparent bg-gradient-to-br from-foreground to-foreground/60`
class MwGradientText extends StatelessWidget {
  const MwGradientText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final fg = context.palette.foreground;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [fg, fg.withValues(alpha: 0.6)],
      ).createShader(bounds),
      child: Text(
        text,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        style: style.copyWith(color: Colors.white),
      ),
    );
  }
}

/// Brand title — `text-4xl font-black tracking-tighter` with the foreground
/// gradient.
class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key, this.fontSize = 36});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return MwGradientText(
      'Meneer Wit',
      textAlign: TextAlign.center,
      style: MwText.t(fontSize, weight: MwText.black, tracking: -0.05),
    );
  }
}

/// `text-[10px] font-bold uppercase tracking-widest text-muted-foreground`
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.size = 10});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: MwText.t(
        size,
        weight: MwText.bold,
        tracking: 0.1,
        color: context.palette.mutedForeground,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small chrome
// ---------------------------------------------------------------------------

/// App logo — `w-12 h-12 rounded-2xl shadow-xl`, plus the dark-mode
/// `ring-2 ring-white/15 ring-offset-2 ring-offset-background`.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final logo = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MwRadius.x2),
        boxShadow: p.isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.75),
                  blurRadius: 40,
                  spreadRadius: -6,
                  offset: const Offset(0, 12),
                ),
              ]
            : mwShadowXl(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset('assets/branding/logo.png', fit: BoxFit.cover),
    );
    if (!p.isDark) return logo;
    // ring-offset-2 = 2px of background, then a 2px white/15 ring.
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MwRadius.x2 + 4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
      ),
      child: logo,
    );
  }
}

/// `w-10 h-10 rounded-full bg-secondary text-secondary-foreground`
class MwCircleButton extends StatelessWidget {
  const MwCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.iconSize = 20,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: tooltip ?? '',
      child: SizedBox(
        width: 40,
        height: 40,
        child: Material(
          color: p.secondary,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Center(
              child: Icon(icon, size: iconSize, color: p.secondaryForeground),
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
  Widget build(BuildContext context) => const ThemeToggleCircle();
}

/// The site's fixed top-right theme switch.
class ThemeToggleCircle extends StatelessWidget {
  const ThemeToggleCircle({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.select<AppState, ThemeMode>((s) => s.themeMode);
    return MwCircleButton(
      tooltip: 'Thema wisselen',
      iconSize: 19.2, // h-[1.2rem]
      icon: mode == ThemeMode.dark
          ? Icons.dark_mode_outlined
          : Icons.light_mode_outlined,
      onPressed: () => context.read<AppState>().cycleTheme(),
    );
  }
}

/// Screen header — `flex items-center gap-4` with the round back button and a
/// gradient `font-black` heading.
class MwHeader extends StatelessWidget {
  const MwHeader({
    super.key,
    required this.title,
    this.onBack,
    this.actions = const [],
    this.fontSize = 20,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null) ...[
          MwCircleButton(
            icon: Icons.arrow_back_ios_new_rounded,
            iconSize: 16,
            onPressed: onBack!,
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: MwGradientText(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MwText.t(fontSize, weight: MwText.black),
          ),
        ),
        for (final a in actions) ...[const SizedBox(width: 8), a],
      ],
    );
  }
}

/// `text-[11px] font-semibold px-2.5 py-1 rounded-full bg-secondary
/// border border-border/60 text-muted-foreground`, with a primary-tinted
/// leading glyph.
class InfoPill extends StatelessWidget {
  const InfoPill({
    super.key,
    required this.text,
    this.icon,
    this.compact = true,
  });

  final String text;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: p.secondary,
        borderRadius: BorderRadius.circular(MwRadius.full),
        border: Border.all(color: p.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: p.primary),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: MwText.t(
              11,
              weight: MwText.semibold,
              color: p.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Buttons
// ---------------------------------------------------------------------------

enum MwButtonVariant { primary, secondary, destructive, muted }

/// Full-width button matching the site's `py-* bg-* rounded-* font-bold`
/// pattern. [height] is the resolved `padding-y * 2 + line-height`.
class MwButton extends StatelessWidget {
  const MwButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.variant = MwButtonVariant.primary,
    this.height = 60,
    this.fontSize = 18,
    this.radius = MwRadius.x2,
    this.bordered = false,
    this.shadow = true,
    this.shadows,
    this.iconSize = 20,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final MwButtonVariant variant;
  final double height;
  final double fontSize;
  final double radius;
  final bool bordered;
  final bool shadow;

  /// Overrides the default `shadow-lg` on primary buttons.
  final List<BoxShadow>? shadows;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (Color bg, Color fg) = switch (variant) {
      MwButtonVariant.primary => (p.primary, p.primaryForeground),
      MwButtonVariant.destructive => (p.destructive, p.destructiveForeground),
      MwButtonVariant.secondary ||
      MwButtonVariant.muted =>
        (p.secondary, p.secondaryForeground),
    };
    final enabled = onTap != null;
    final radiusGeom = BorderRadius.circular(radius);

    return Opacity(
      opacity: enabled ? 1 : 0.3,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: radiusGeom,
          boxShadow: shadows ??
              (shadow && variant == MwButtonVariant.primary
                  ? mwShadowLg()
                  : null),
        ),
        child: Material(
          color: bg,
          borderRadius: radiusGeom,
          child: InkWell(
            borderRadius: radiusGeom,
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: radiusGeom,
                border:
                    bordered ? Border.all(color: p.border, width: 2) : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MwText.t(fontSize,
                          weight: MwText.bold, color: fg),
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: iconSize, color: fg),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Stacked dialog button — `w-full py-4 rounded-2xl font-bold text-xl`.
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
    return MwButton(
      label: label,
      onTap: onTap,
      variant: variant,
      height: 60,
      fontSize: 20,
      radius: MwRadius.x2,
    );
  }
}

// ---------------------------------------------------------------------------
// Form controls
// ---------------------------------------------------------------------------

/// `w-12 h-6 rounded-full` track with an `absolute top-1 w-4 h-4 bg-background
/// rounded-full shadow-sm` knob.
class MwToggle extends StatelessWidget {
  const MwToggle({super.key, required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: 48,
      height: 24,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: value
                    ? p.primary
                    : p.mutedForeground.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(MwRadius.full),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            top: 4,
            left: value ? 28 : 4,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: p.background,
                shape: BoxShape.circle,
                boxShadow: mwShadowSm(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A tappable `p-3 bg-secondary rounded-xl` row with a title, sub-line and a
/// trailing [MwToggle].
class MwToggleRow extends StatelessWidget {
  const MwToggleRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.secondary,
      borderRadius: BorderRadius.circular(MwRadius.xl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: MwText.t(12,
                          weight: MwText.bold, color: p.secondaryForeground),
                    ),
                    Text(
                      subtitle,
                      style: MwText.t(10, color: p.mutedForeground),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              MwToggle(value: value),
            ],
          ),
        ),
      ),
    );
  }
}

/// `w-7 h-7 rounded-full border-2 border-border flex items-center
/// justify-center font-bold`
class MwStepperButton extends StatelessWidget {
  const MwStepperButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.3,
      child: SizedBox(
        width: 28,
        height: 28,
        child: Material(
          color: Colors.transparent,
          shape: CircleBorder(side: BorderSide(color: p.border, width: 2)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: Icon(icon, size: 14, color: p.secondaryForeground),
            ),
          ),
        ),
      ),
    );
  }
}

/// `rounded-xl border-2 border-border bg-secondary py-3 pl-3 pr-10 text-sm
/// font-bold shadow-sm` with the `chevron-down` affordance.
class MwSelect<T> extends StatelessWidget {
  const MwSelect({
    super.key,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      // py-3 (12) + text-sm line-height (20) + 2px borders = 48.
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: p.secondary,
        borderRadius: BorderRadius.circular(MwRadius.xl),
        border: Border.all(color: p.border, width: 2),
        boxShadow: mwShadowSm(),
      ),
      padding: const EdgeInsets.only(left: 12, right: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          borderRadius: BorderRadius.circular(MwRadius.xl),
          dropdownColor: p.popover,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              size: 20, color: p.mutedForeground),
          style: MwText.t(14, weight: MwText.bold, color: p.foreground),
          items: [
            for (final item in items)
              DropdownMenuItem<T>(value: item, child: Text(labelOf(item))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialogs
// ---------------------------------------------------------------------------

/// Modal shell — `bg-card rounded-[2.5rem] p-8 max-w-md w-full text-center
/// shadow-2xl border border-border`, over a `bg-background/80 backdrop-blur-md`
/// scrim.
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
    final p = context.palette;
    return Dialog(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MwRadius.modal),
        side: BorderSide(color: p.border),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: MwBackground.maxWidth),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: MwText.t(24, weight: MwText.bold, color: p.cardForeground),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: MwText.t(16, color: p.mutedForeground),
              ),
            ],
            if (content != null) ...[
              const SizedBox(height: 24),
              content!,
            ],
            const SizedBox(height: 32),
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

/// Shows a modal over the site's blurred scrim.
Future<T?> showMwDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final p = context.palette;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (ctx, a1, a2) => builder(ctx),
    transitionBuilder: (ctx, anim, _, child) {
      return FadeTransition(
        opacity: anim,
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: ColoredBox(color: p.background.withValues(alpha: 0.8)),
              ),
            ),
            child,
          ],
        ),
      );
    },
  );
}

/// Confirm dialog. Returns true on confirm.
Future<bool> showMwConfirm(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmText,
  String cancelText = 'Annuleren',
  bool destructive = false,
}) async {
  final ok = await showMwDialog<bool>(
    context,
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
          variant: MwButtonVariant.secondary,
          onTap: () => Navigator.pop(context, false),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Confirmation shown before abandoning a running game.
Future<bool> confirmQuitGame(BuildContext context) => showMwConfirm(
      context,
      title: 'Spel stoppen?',
      message:
          'Weet je zeker dat je wilt stoppen? De huidige ronde gaat verloren.',
      confirmText: 'Stoppen',
      destructive: true,
    );
