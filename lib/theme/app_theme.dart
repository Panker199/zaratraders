import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Dark palette ──
  static const Color background   = Color(0xFF0f0f0f);
  static const Color sidebar      = Color(0xFF161616);
  static const Color surfaceColor = Color(0xFF1e1e1e);
  static const Color surfaceHover = Color(0xFF282828);
  static const Color accent       = Color(0xFF60cdff);
  static const Color accentSoft   = Color(0x1A60cdff);
  static const Color textPrimary  = Color(0xFFf0f0f0);
  static const Color textMuted    = Color(0xFF8a8a8a);
  static const Color borderColor  = Color(0x18FFFFFF);
  static const Color cardBorder   = Color(0x12FFFFFF);
  static const Color success      = Color(0xFF4CAF50);
  static const Color warning      = Color(0xFFFF9800);
  static const Color danger       = Color(0xFFEF5350);

  // ── Light palette ──
  static const Color lightBg        = Color(0xFFF4F6F8);
  static const Color lightSurface   = Colors.white;
  static const Color lightText      = Color(0xFF1A1D21);
  static const Color lightMuted     = Color(0xFF7B8794);
  static const Color lightBorder    = Color(0xFFE2E8F0);
  static const Color lightAccent    = Color(0xFF0088CC);
  static const Color lightAccentSoft = Color(0x0D0088CC);

  // ──────────────────────── LIGHT THEME ────────────────────────
  static ThemeData get lightTheme {
    final cs = ColorScheme.light(
      primary: lightAccent,
      onPrimary: Colors.white,
      secondary: lightAccent,
      onSecondary: Colors.white,
      surface: lightSurface,
      onSurface: lightText,
      onSurfaceVariant: lightMuted,
      error: const Color(0xFFD32F2F),
      onError: Colors.white,
      outline: lightBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: cs,
      scaffoldBackgroundColor: lightBg,

      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineLarge:  GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: lightText, letterSpacing: -0.5),
        headlineMedium: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: lightText, letterSpacing: -0.3),
        headlineSmall:  GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: lightText),
        titleLarge:     GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: lightText),
        titleMedium:    GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: lightText),
        titleSmall:     GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: lightText),
        bodyLarge:      GoogleFonts.inter(fontSize: 16, color: lightText),
        bodyMedium:     GoogleFonts.inter(fontSize: 14, color: lightText),
        bodySmall:      GoogleFonts.inter(fontSize: 12, color: lightMuted),
        labelLarge:     GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: lightText),
        labelSmall:     GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: lightMuted),
      ),

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: lightSurface,
        foregroundColor: lightText,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: lightText),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: lightBorder, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        color: lightSurface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: lightAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightAccent,
          side: BorderSide(color: lightAccent.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightBg,
        hintStyle: GoogleFonts.inter(color: lightMuted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        indicatorColor: lightAccent.withValues(alpha: 0.10),
        backgroundColor: lightSurface.withValues(alpha: 0.95),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: lightMuted),
        ),
      ),

      dividerTheme: DividerThemeData(thickness: 1, color: lightBorder, space: 1),

      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: lightBg,
        labelStyle: GoogleFonts.inter(color: lightText, fontSize: 12),
        side: BorderSide(color: lightBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: lightText,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(color: lightAccent),

      iconTheme: const IconThemeData(color: lightText, size: 22),

      splashFactory: InkSparkle.splashFactory,
    );
  }

  // ──────────────────────── DARK THEME ────────────────────────
  static ThemeData get darkTheme {
    final cs = ColorScheme.dark(
      primary: accent,
      onPrimary: Colors.black,
      secondary: accent,
      onSecondary: Colors.black,
      surface: surfaceColor,
      onSurface: textPrimary,
      onSurfaceVariant: textMuted,
      error: const Color(0xFFcf6679),
      onError: Colors.black,
      outline: borderColor,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,
      scaffoldBackgroundColor: background,

      textTheme: GoogleFonts.barlowTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ).copyWith(
        headlineLarge:  GoogleFonts.barlowCondensed(fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.5),
        headlineMedium: GoogleFonts.barlowCondensed(fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary),
        headlineSmall:  GoogleFonts.barlow(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        titleLarge:     GoogleFonts.barlow(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium:    GoogleFonts.barlow(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
        titleSmall:     GoogleFonts.barlow(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge:      GoogleFonts.barlow(fontSize: 16, color: textPrimary),
        bodyMedium:     GoogleFonts.barlow(fontSize: 14, color: textPrimary),
        bodySmall:      GoogleFonts.barlow(fontSize: 12, color: textMuted),
        labelLarge:     GoogleFonts.barlow(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
        labelSmall:     GoogleFonts.barlow(fontSize: 11, fontWeight: FontWeight.w500, color: textMuted),
      ),

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: sidebar,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.barlow(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: cardBorder, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.barlow(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: accent.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: GoogleFonts.barlow(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHover,
        hintStyle: GoogleFonts.barlow(color: textMuted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        indicatorColor: accent.withValues(alpha: 0.15),
        backgroundColor: sidebar.withValues(alpha: 0.95),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.barlow(fontSize: 11, fontWeight: FontWeight.w500, color: textMuted),
        ),
      ),

      dividerTheme: const DividerThemeData(thickness: 1, color: borderColor, space: 1),

      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 12,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceHover,
        labelStyle: GoogleFonts.barlow(color: textPrimary, fontSize: 12),
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceHover,
        contentTextStyle: GoogleFonts.barlow(color: textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(color: accent),

      iconTheme: const IconThemeData(color: textPrimary, size: 22),

      splashFactory: InkSparkle.splashFactory,
    );
  }
}
