import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomColors extends ThemeExtension<CustomColors> {
  final Color? blueText;
  final Color? blueBg;
  final Color? greenText;
  final Color? greenBg;
  final Color? orangeText;
  final Color? orangeBg;
  final Color? purpleText;
  final Color? purpleBg;
  final Color? redText;
  final Color? redBg;

  const CustomColors({
    this.blueText,
    this.blueBg,
    this.greenText,
    this.greenBg,
    this.orangeText,
    this.orangeBg,
    this.purpleText,
    this.purpleBg,
    this.redText,
    this.redBg,
  });

  @override
  CustomColors copyWith({
    Color? blueText, Color? blueBg,
    Color? greenText, Color? greenBg,
    Color? orangeText, Color? orangeBg,
    Color? purpleText, Color? purpleBg,
    Color? redText, Color? redBg,
  }) {
    return CustomColors(
      blueText: blueText ?? this.blueText,
      blueBg: blueBg ?? this.blueBg,
      greenText: greenText ?? this.greenText,
      greenBg: greenBg ?? this.greenBg,
      orangeText: orangeText ?? this.orangeText,
      orangeBg: orangeBg ?? this.orangeBg,
      purpleText: purpleText ?? this.purpleText,
      purpleBg: purpleBg ?? this.purpleBg,
      redText: redText ?? this.redText,
      redBg: redBg ?? this.redBg,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) return this;
    return CustomColors(
      blueText: Color.lerp(blueText, other.blueText, t),
      blueBg: Color.lerp(blueBg, other.blueBg, t),
      greenText: Color.lerp(greenText, other.greenText, t),
      greenBg: Color.lerp(greenBg, other.greenBg, t),
      orangeText: Color.lerp(orangeText, other.orangeText, t),
      orangeBg: Color.lerp(orangeBg, other.orangeBg, t),
      purpleText: Color.lerp(purpleText, other.purpleText, t),
      purpleBg: Color.lerp(purpleBg, other.purpleBg, t),
      redText: Color.lerp(redText, other.redText, t),
      redBg: Color.lerp(redBg, other.redBg, t),
    );
  }
}

class AppThemes {
  // === SVĚTLÝ REŽIM ===
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF0056D2),
    scaffoldBackgroundColor: const Color(0xFFF5F7FA), // Světlé pozadí mimo karty
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF0056D2),
      primaryContainer: Color(0xFFEFF6FF), // Světle modrá
      surface: Colors.white,           // Barva karet a kontejnerů
      onSurface: Color(0xFF111827),    // Hlavní text
      secondary: Color(0xFF6B7280),    // Podružný text / Ikony
      outline: Color(0xFFE5E7EB),      // Okraje karet
      outlineVariant: Color(0xFFE5E7EB), // Varianta pro okraje a děliče
      error: Color(0xFFDC2626),        // Červená pro chyby
      errorContainer: Color(0xFFFEF2F2), // Světle červená
    ),
    extensions: const <ThemeExtension<dynamic>>[
      CustomColors(
        blueText: Color(0xFF0056D2),
        blueBg: Color(0xFFEFF6FF),
        greenText: Color(0xFF059669),
        greenBg: Color(0xFFECFDF5),
        orangeText: Color(0xFFD97706),
        orangeBg: Color(0xFFFFFBEB),
        purpleText: Color(0xFF7C3AED),
        purpleBg: Color(0xFFF5F3FF),
        redText: Color(0xFFDC2626),
        redBg: Color(0xFFFEF2F2),
      ),
    ],
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF111827),
      elevation: 0,
    ),
  );

  // === TMAVÝ REŽIM ===
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF3B82F6), // Trochu světlejší modrá pro lepší kontrast v dark mode
    scaffoldBackgroundColor: const Color(0xFF121212), // Velmi tmavé pozadí
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF3B82F6),
      primaryContainer: Color(0xFF1E3A8A), // Tmavší modrá
      surface: Color(0xFF1E1E1E),      // Barva karet (mírně světlejší než pozadí)
      onSurface: Color(0xFFF9FAFB),    // Hlavní text
      secondary: Color(0xFF9CA3AF),    // Podružný text / Ikony
      outline: Color(0xFF374151),      // Okraje karet
      outlineVariant: Color(0xFF374151), // Varianta pro okraje a děliče
      error: Color(0xFFEF4444),        // Červená pro chyby
      errorContainer: Color(0xFF7F1D1D), // Tmavší červená
    ),
    extensions: const <ThemeExtension<dynamic>>[
      CustomColors(
        blueText: Color(0xFF60A5FA),
        blueBg: Color(0xFF28323F), // Zjemněná modrá
        greenText: Color(0xFF10B981),
        greenBg: Color(0xFF1C352D), // Zjemněná zelená
        orangeText: Color(0xFFF59E0B),
        orangeBg: Color(0xFF3E311B), // Zjemněná oranžová
        purpleText: Color(0xFFA78BFA),
        purpleBg: Color(0xFF322E3F), // Zjemněná fialová
        redText: Color(0xFFEF4444),
        redBg: Color(0xFF3D2323), // Zjemněná červená
      ),
    ],
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Color(0xFFF9FAFB),
      elevation: 0,
    ),
  );
}
