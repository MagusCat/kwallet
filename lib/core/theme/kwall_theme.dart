import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class KwallTheme {
  static const Color background = Color(0xFF090B10);
  static const Color surface = Color(0xFF121520);
  static const Color surfaceCard = Color(0xFF191E2D);
  static const Color surfaceCardHighlight = Color(0xFF22293E);
  static const Color border = Color(0xFF2A324B);
  static const Color borderBright = Color(0xFF3F4A6E);

  // Game HUD Accents
  static const Color neonGreen = Color(0xFF00FF9D); // Health / Income / OK
  static const Color plasmaPink = Color(0xFFFF3366); // Expense / Warning / Danger
  static const Color electricCyan = Color(0xFF00D2FF); // Mana / Bank / Transfer
  static const Color cyberGold = Color(0xFFFFB800); // Vault / Quests / EXP
  static const Color arcadePurple = Color(0xFF9D4EDD); // Magic / Special
  static const Color textMuted = Color(0xFF8692A6);
  static const Color textBright = Color(0xFFF0F4F8);

  static TextStyle get gameFont {
    try {
      return GoogleFonts.vt323(
        letterSpacing: 1.5,
        fontWeight: FontWeight.bold,
      );
    } catch (_) {
      return const TextStyle(
        fontFamily: 'monospace',
        letterSpacing: 1.5,
        fontWeight: FontWeight.bold,
      );
    }
  }

  static TextStyle get hudHeaderFont {
    try {
      return GoogleFonts.spaceGrotesk(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      );
    } catch (_) {
      return const TextStyle(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      );
    }
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: neonGreen,
      colorScheme: const ColorScheme.dark(
        primary: neonGreen,
        secondary: electricCyan,
        surface: surface,
        error: plasmaPink,
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: border, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: borderBright, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: hudHeaderFont.copyWith(
          color: textBright,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
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
