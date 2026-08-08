import 'package:flutter/material.dart';

Color _hsl(double h, double s, double l) =>
    HSLColor.fromAHSL(1.0, h, s / 100, l / 100).toColor();

/// Design tokens copied 1:1 from meneerwit.com.
///
/// The site is a Tailwind/shadcn app whose palette lives in two CSS blocks:
/// `:root` (light) and `.dark`. Every value below is the exact HSL triple from
/// that stylesheet, so colours match the web build pixel for pixel.
@immutable
class MwPalette extends ThemeExtension<MwPalette> {
  const MwPalette({
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.popover,
    required this.popoverForeground,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.destructiveForeground,
    required this.border,
    required this.input,
    required this.ring,
    required this.glow,
    required this.glowRadiusX,
    required this.glowStop,
    required this.cardFaceFrom,
    required this.cardFaceTo,
    required this.isDark,
  });

  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color popover;
  final Color popoverForeground;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color destructiveForeground;
  final Color border;
  final Color input;
  final Color ring;

  /// `body { background-image: radial-gradient(... at 50% -10%) }`.
  final Color glow;
  final double glowRadiusX; // 140% (light) / 120% (dark) of the viewport width
  final double glowStop; // colour stop where the glow reaches transparent

  /// Flip-card front: `from-slate-100 to-slate-200` / `dark:from-zinc-800
  /// dark:to-zinc-900`.
  final Color cardFaceFrom;
  final Color cardFaceTo;

  final bool isDark;

  // ---- Fixed Tailwind palette entries used by the leaderboard. -------------
  static const yellow500 = Color(0xFFEAB308);
  static const yellow600 = Color(0xFFCA8A04);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const bronze = Color(0xFFCD7F32);
  static const green500 = Color(0xFF22C55E);

  /// Podium colours, kept under their old names for call sites.
  Color get gold => yellow500;
  Color get silver => slate400;

  @override
  MwPalette copyWith({
    Color? background,
    Color? foreground,
    Color? card,
    Color? cardForeground,
    Color? popover,
    Color? popoverForeground,
    Color? primary,
    Color? primaryForeground,
    Color? secondary,
    Color? secondaryForeground,
    Color? muted,
    Color? mutedForeground,
    Color? accent,
    Color? accentForeground,
    Color? destructive,
    Color? destructiveForeground,
    Color? border,
    Color? input,
    Color? ring,
    Color? glow,
    double? glowRadiusX,
    double? glowStop,
    Color? cardFaceFrom,
    Color? cardFaceTo,
    bool? isDark,
  }) =>
      MwPalette(
        background: background ?? this.background,
        foreground: foreground ?? this.foreground,
        card: card ?? this.card,
        cardForeground: cardForeground ?? this.cardForeground,
        popover: popover ?? this.popover,
        popoverForeground: popoverForeground ?? this.popoverForeground,
        primary: primary ?? this.primary,
        primaryForeground: primaryForeground ?? this.primaryForeground,
        secondary: secondary ?? this.secondary,
        secondaryForeground: secondaryForeground ?? this.secondaryForeground,
        muted: muted ?? this.muted,
        mutedForeground: mutedForeground ?? this.mutedForeground,
        accent: accent ?? this.accent,
        accentForeground: accentForeground ?? this.accentForeground,
        destructive: destructive ?? this.destructive,
        destructiveForeground:
            destructiveForeground ?? this.destructiveForeground,
        border: border ?? this.border,
        input: input ?? this.input,
        ring: ring ?? this.ring,
        glow: glow ?? this.glow,
        glowRadiusX: glowRadiusX ?? this.glowRadiusX,
        glowStop: glowStop ?? this.glowStop,
        cardFaceFrom: cardFaceFrom ?? this.cardFaceFrom,
        cardFaceTo: cardFaceTo ?? this.cardFaceTo,
        isDark: isDark ?? this.isDark,
      );

  // The site swaps themes instantly (`disableTransitionOnChange`), so a hard
  // switch at the halfway point mirrors it.
  @override
  MwPalette lerp(ThemeExtension<MwPalette>? other, double t) {
    if (other is! MwPalette) return this;
    return t < 0.5 ? this : other;
  }
}

/// Tailwind type scale (16px root) as used across meneerwit.com.
///
/// `size` is the `text-*` value, `height` the matching line-height ratio and
/// `letterSpacing` the `tracking-*` value converted from `em` to logical px.
class MwText {
  const MwText._();

  // Tailwind font weights.
  static const medium = FontWeight.w500;
  static const semibold = FontWeight.w600;
  static const bold = FontWeight.w700;
  static const black = FontWeight.w900;

  // Tailwind line-height ratios for the fixed sizes. Anything else (the
  // arbitrary `text-[10px]`-style sizes) inherits the 1.5 root line-height.
  static double _lineHeight(double size) => switch (size) {
        12 => 16 / 12, // text-xs
        14 => 20 / 14, // text-sm
        16 => 24 / 16, // text-base
        18 => 28 / 18, // text-lg
        20 => 28 / 20, // text-xl
        24 => 32 / 24, // text-2xl
        30 => 36 / 30, // text-3xl
        36 => 40 / 36, // text-4xl
        48 => 1.0, // text-5xl
        _ => 1.5,
      };

  /// A Tailwind text style. [tracking] is expressed in `em`, matching the
  /// `tracking-*` utilities (widest = 0.1em, [0.2em], …).
  static TextStyle t(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color? color,
    double tracking = 0,
    double? height,
  }) =>
      TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: tracking * size,
        height: height ?? _lineHeight(size),
      );
}

/// Tailwind border radii (`rounded-*`).
class MwRadius {
  const MwRadius._();

  static const lg = 8.0; // rounded-lg
  static const xl = 12.0; // rounded-xl
  static const x2 = 16.0; // rounded-2xl
  static const x3 = 24.0; // rounded-3xl
  static const x4 = 32.0; // rounded-4xl / rounded-[2rem]
  static const modal = 40.0; // rounded-[2.5rem]
  static const full = 9999.0;
}

class AppTheme {
  static ThemeData light() {
    final palette = MwPalette(
      background: _hsl(0, 0, 98),
      foreground: _hsl(224, 71, 4),
      card: _hsl(0, 0, 100),
      cardForeground: _hsl(224, 71, 4),
      popover: _hsl(0, 0, 100),
      popoverForeground: _hsl(224, 71, 4),
      primary: _hsl(239, 84, 63),
      primaryForeground: _hsl(0, 0, 100),
      secondary: _hsl(220, 20, 93),
      secondaryForeground: _hsl(224, 71, 10),
      muted: _hsl(220, 20, 93),
      mutedForeground: _hsl(220, 9, 46),
      accent: _hsl(239, 84, 95),
      accentForeground: _hsl(239, 84, 30),
      destructive: _hsl(0, 84, 60),
      destructiveForeground: _hsl(0, 0, 100),
      border: _hsl(220, 15, 88),
      input: _hsl(220, 15, 88),
      ring: _hsl(239, 84, 63),
      glow: const Color(0xFFD1D2FA),
      glowRadiusX: 1.40,
      glowStop: 0.65,
      cardFaceFrom: const Color(0xFFF1F5F9), // slate-100
      cardFaceTo: const Color(0xFFE2E8F0), // slate-200
      isDark: false,
    );
    return _build(palette, Brightness.light);
  }

  static ThemeData dark() {
    final palette = MwPalette(
      background: _hsl(224, 71, 4),
      foreground: _hsl(210, 40, 98),
      card: _hsl(222, 47, 7),
      cardForeground: _hsl(210, 40, 98),
      popover: _hsl(224, 71, 4),
      popoverForeground: _hsl(210, 40, 98),
      primary: _hsl(239, 84, 72),
      primaryForeground: _hsl(224, 71, 4),
      secondary: _hsl(215, 28, 12),
      secondaryForeground: _hsl(210, 40, 98),
      muted: _hsl(215, 28, 12),
      mutedForeground: _hsl(215, 20, 65),
      accent: _hsl(215, 28, 12),
      accentForeground: _hsl(210, 40, 98),
      destructive: _hsl(0, 62, 30),
      destructiveForeground: _hsl(210, 40, 98),
      border: _hsl(215, 28, 16),
      input: _hsl(215, 28, 16),
      ring: _hsl(239, 84, 72),
      glow: const Color(0xFF171845),
      glowRadiusX: 1.20,
      glowStop: 0.70,
      cardFaceFrom: const Color(0xFF27272A), // zinc-800
      cardFaceTo: const Color(0xFF18181B), // zinc-900
      isDark: true,
    );
    return _build(palette, Brightness.dark);
  }

  static ThemeData _build(MwPalette p, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.primary,
      onPrimary: p.primaryForeground,
      secondary: p.secondary,
      onSecondary: p.secondaryForeground,
      error: p.destructive,
      onError: p.destructiveForeground,
      surface: p.background,
      onSurface: p.foreground,
      surfaceContainerHighest: p.muted,
      outline: p.border,
      outlineVariant: p.border,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      fontFamily: 'Geist',
      splashFactory: InkRipple.splashFactory,
      extensions: [p],
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: p.foreground,
        displayColor: p.foreground,
      ),
      canvasColor: p.popover,
      dividerTheme: DividerThemeData(color: p.border, space: 1, thickness: 1),
      iconTheme: IconThemeData(color: p.foreground),
      cardTheme: CardThemeData(
        color: p.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MwRadius.x2),
          side: BorderSide(color: p.border),
        ),
      ),
      // `py-4 … text-lg rounded-2xl` on the site: 16 + 28 + 16 = 60px tall.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.primaryForeground,
          disabledBackgroundColor: p.primary.withValues(alpha: 0.3),
          disabledForegroundColor: p.primaryForeground.withValues(alpha: 0.3),
          elevation: 0,
          minimumSize: const Size.fromHeight(60),
          padding: EdgeInsets.zero,
          textStyle: MwText.t(18, weight: MwText.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MwRadius.x2),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: p.secondary,
          foregroundColor: p.secondaryForeground,
          minimumSize: const Size.fromHeight(60),
          padding: EdgeInsets.zero,
          side: BorderSide.none,
          textStyle: MwText.t(18, weight: MwText.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MwRadius.x2),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.mutedForeground,
          textStyle: MwText.t(16, weight: MwText.bold),
        ),
      ),
      // `bg-secondary p-3 rounded-xl text-sm font-bold focus:ring-2
      // focus:ring-primary` — no resting border, a primary ring on focus.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        isDense: true,
        fillColor: p.secondary,
        hintStyle: MwText.t(14, weight: MwText.bold, color: p.mutedForeground),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MwRadius.xl),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MwRadius.xl),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MwRadius.xl),
          borderSide: BorderSide(color: p.primary, width: 2),
        ),
      ),
      // `.custom-slider` — a flat 12px `bg-secondary` track with a 28px
      // primary thumb; the track is not split into active/inactive.
      sliderTheme: SliderThemeData(
        trackHeight: 12,
        activeTrackColor: p.secondary,
        inactiveTrackColor: p.secondary,
        thumbColor: p.primary,
        activeTickMarkColor: Colors.transparent,
        inactiveTickMarkColor: Colors.transparent,
        overlayColor: p.primary.withValues(alpha: 0.12),
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 14,
          elevation: 2,
          pressedElevation: 2,
        ),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
        trackShape: const RoundedRectSliderTrackShape(),
        showValueIndicator: ShowValueIndicator.never,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MwRadius.modal),
          side: BorderSide(color: p.border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.card,
        contentTextStyle:
            MwText.t(14, weight: MwText.semibold, color: p.foreground),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MwRadius.x2),
          side: BorderSide(color: p.border),
        ),
      ),
    );
  }
}
