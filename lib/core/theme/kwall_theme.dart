import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Google Material 3 Expressive Design System
/// 3 base neutral tones + 1 expressive accent
class KwallTheme {
  // 3 Base Neutral Colors
  static const Color background = Color(0xFF0F1218);
  static const Color surface = Color(0xFF181C24);
  static const Color surfaceContainer = Color(0xFF222734);
  static const Color surfaceElevated = Color(0xFF2A3142);
  static const Color border = Color(0xFF2E3648);

  // 1 Expressive Primary Accent
  static const Color accent = Color(0xFF10B981); // Expressive Emerald Mint
  static const Color accentLight = Color(0xFF34D399);

  // Subtle Semantic Indicators
  static const Color expenseRed = Color(0xFFF43F5E);
  static const Color incomeGreen = Color(0xFF10B981);
  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color warningAmber = Color(0xFFF59E0B);

  // Clean Text Colors
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static TextStyle get fontTitle {
    try {
      return GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      );
    } catch (_) {
      return const TextStyle(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      );
    }
  }

  static TextStyle get fontBody {
    try {
      return GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
      );
    } catch (_) {
      return const TextStyle(
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
      );
    }
  }

  static TextStyle get fontDisplay {
    try {
      return GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      );
    } catch (_) {
      return const TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      );
    }
  }

  static ThemeData get expressiveTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: accent,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        onPrimary: Colors.black,
        secondary: accentLight,
        surface: surface,
        onSurface: textPrimary,
        surfaceContainer: surfaceContainer,
        error: expenseRed,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: border, width: 1.0),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 6,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: border, width: 1.0),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: fontTitle.copyWith(
          color: textPrimary,
          fontSize: 20,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: accent.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return fontBody.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: accent);
          }
          return fontBody.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary);
        }),
      ),
    );
  }

  static String formatCurrency(double amount, [String currency = '\$']) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    final formatted = formatter.format(amount.abs());
    if (amount < 0) {
      return '-$currency$formatted';
    }
    return '$currency$formatted';
  }
}
