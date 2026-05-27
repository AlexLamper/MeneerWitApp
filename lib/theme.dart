import 'package:flutter/material.dart';

Color _hsl(double h, double s, double l) =>
    HSLColor.fromAHSL(1.0, h, s / 100, l / 100).toColor();

/// Extra design tokens that don't fit in [ColorScheme], mirrored from
/// meneerwit.com (shadcn/Tailwind HSL tokens).
@immutable
class MwPalette extends ThemeExtension<MwPalette> {
  const MwPalette({
    required this.card,
    required this.cardForeground,
    required this.border,
    required this.muted,
    required this.mutedForeground,
    required this.gold,
    required this.bronze,
    required this.silver,
  });

  final Color card;
  final Color cardForeground;
  final Color border;
  final Color muted;
  final Color mutedForeground;
  final Color gold;
  final Color bronze;
  final Color silver;

  @override
  MwPalette copyWith({
    Color? card,
    Color? cardForeground,
    Color? border,
    Color? muted,
    Color? mutedForeground,
    Color? gold,
    Color? bronze,
    Color? silver,
  }) =>
      MwPalette(
        card: card ?? this.card,
        cardForeground: cardForeground ?? this.cardForeground,
        border: border ?? this.border,
        muted: muted ?? this.muted,
        mutedForeground: mutedForeground ?? this.mutedForeground,
        gold: gold ?? this.gold,
        bronze: bronze ?? this.bronze,
        silver: silver ?? this.silver,
      );

  @override
  MwPalette lerp(ThemeExtension<MwPalette>? other, double t) {
    if (other is! MwPalette) return this;
    return MwPalette(
      card: Color.lerp(card, other.card, t)!,
      cardForeground: Color.lerp(cardForeground, other.cardForeground, t)!,
      border: Color.lerp(border, other.border, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      bronze: Color.lerp(bronze, other.bronze, t)!,
      silver: Color.lerp(silver, other.silver, t)!,
    );
  }
}

class AppTheme {
  static const _gold = Color(0xFFEDB200);
  static const _bronze = Color(0xFFCD7F32);
  static const _silver = Color(0xFFC0C8D4);

  static ThemeData light() {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: _hsl(239, 84, 63),
      onPrimary: _hsl(0, 0, 100),
      secondary: _hsl(220, 20, 93),
      onSecondary: _hsl(224, 71, 10),
      error: _hsl(0, 84, 60),
      onError: _hsl(0, 0, 100),
      surface: _hsl(0, 0, 98),
      onSurface: _hsl(224, 71, 4),
    );
    const palette = MwPalette(
      card: Color(0xFFFFFFFF),
      cardForeground: Color(0xFF0A0E1A),
      border: Color(0xFFDBDFE6),
      muted: Color(0xFFE8EAEF),
      mutedForeground: Color(0xFF6B7280),
      gold: _gold,
      bronze: _bronze,
      silver: _silver,
    );
    return _build(scheme, palette);
  }

  static ThemeData dark() {
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _hsl(239, 84, 72),
      onPrimary: _hsl(224, 71, 4),
      secondary: _hsl(215, 28, 12),
      onSecondary: _hsl(210, 40, 98),
      error: _hsl(0, 62, 45),
      onError: _hsl(210, 40, 98),
      surface: _hsl(224, 71, 4),
      onSurface: _hsl(210, 40, 98),
    );
    final palette = MwPalette(
      card: _hsl(222, 47, 7),
      cardForeground: _hsl(210, 40, 98),
      border: _hsl(215, 28, 16),
      muted: _hsl(215, 28, 12),
      mutedForeground: _hsl(215, 20, 65),
      gold: _gold,
      bronze: _bronze,
      silver: _silver,
    );
    return _build(scheme, palette);
  }

  static ThemeData _build(ColorScheme scheme, MwPalette palette) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: 'Geist',
      extensions: [palette],
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        color: palette.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: palette.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            fontFamily: 'Geist',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size.fromHeight(56),
          side: BorderSide(color: palette.border),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Geist',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
    );
  }
}
