import 'package:flutter/material.dart';

/// Système de design G-Caisse — inspiré Max It (Orange Cameroun)
class AppTheme {
  // ── Couleurs ─────────────────────────────────────────────
  static const Color primary      = Color(0xFFFF7900);
  static const Color primaryDark  = Color(0xFFE06500);
  static const Color dark         = Color(0xFF0D0D0D);
  static const Color darkCard     = Color(0xFF1A1A1A);
  static const Color darkSurface  = Color(0xFF242424);
  static const Color light        = Color(0xFFF5F6F8);
  static const Color textDark     = Color(0xFF0D0D0D);
  static const Color textLight    = Color(0xFFFFFFFF);
  static const Color textMuted    = Color(0xFF8A8A8A);
  static const Color success      = Color(0xFF22C55E);
  static const Color error        = Color(0xFFEF4444);
  static const Color warning      = Color(0xFFF59E0B);

  // ── Dégradés ─────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF7900), Color(0xFFFF9A3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Rayons ───────────────────────────────────────────────
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;

  // ── Ombres ───────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4)),
  ];
  static List<BoxShadow> get primaryShadow => [
    BoxShadow(color: primary.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8)),
  ];

  // ── Décoration champs ────────────────────────────────────
  static InputDecoration fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
    bool isDark = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? const Color(0xFF555555) : const Color(0xFFBBBBBB),
        fontSize: 15,
      ),
      prefixIcon: Icon(icon, color: isDark ? textMuted : const Color(0xFFAAAAAA), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: isDark ? darkSurface : light,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: isDark ? const Color(0xFF333333) : const Color(0xFFEEEEEE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: error, width: 1.5),
      ),
    );
  }

  // ── Bouton principal ─────────────────────────────────────
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: Colors.white,
    elevation: 0,
    shadowColor: Colors.transparent,
    minimumSize: const Size(double.infinity, 56),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
  );

  // ── ThemeData Flutter ────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: primary,
    scaffoldBackgroundColor: light,
    colorScheme: const ColorScheme.light(primary: primary, secondary: primaryDark),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: textDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textDark),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: primary,
      unselectedItemColor: textMuted,
      backgroundColor: Colors.white,
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: primary,
    scaffoldBackgroundColor: dark,
    colorScheme: const ColorScheme.dark(primary: primary, secondary: primaryDark),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkCard,
      foregroundColor: textLight,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textLight),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: primary,
      unselectedItemColor: textMuted,
      backgroundColor: darkCard,
    ),
  );
}
