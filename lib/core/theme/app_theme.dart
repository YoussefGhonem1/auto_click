import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.tajawalTextTheme(),
      useMaterial3: true,
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.tajawalTextTheme(),
      useMaterial3: true,
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class AppColors {
  // Theme-aware color methods
  static Color getSuccessColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return colorScheme.brightness == Brightness.light
        ? Colors.green
        : Colors.greenAccent;
  }

  static Color getErrorColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return colorScheme.brightness == Brightness.light
        ? Colors.red
        : Colors.redAccent;
  }

  static Color getWarningColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return colorScheme.brightness == Brightness.light
        ? Colors.orange
        : Colors.orangeAccent;
  }

  static Color getInfoColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return colorScheme.brightness == Brightness.light
        ? Colors.blue
        : Colors.blueAccent;
  }

  static Color getDeviceColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return colorScheme.brightness == Brightness.light
        ? Colors.green.shade700
        : Colors.greenAccent;
  }

  static Color getGestureColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return colorScheme.brightness == Brightness.light
        ? Colors.purple.shade700
        : Colors.purpleAccent;
  }

  static Color getReactionColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return colorScheme.brightness == Brightness.light
        ? Colors.red
        : Colors.redAccent;
  }

  static Color getCommunicationColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return colorScheme.brightness == Brightness.light
        ? Colors.blue
        : Colors.blueAccent;
  }

  static Color getBackgroundColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return colorScheme.brightness == Brightness.light
        ? Colors.grey.shade50
        : const Color(0xFF121212);
  }

  // Status colors with theme awareness
  static Color getStatusColor(String status, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = colorScheme.brightness == Brightness.light;

    switch (status.toLowerCase()) {
      case 'pending':
        return isLight ? Colors.orange : Colors.orangeAccent;
      case 'assigned':
        return isLight ? Colors.blue : Colors.blueAccent;
      case 'in_progress':
        return isLight ? Colors.purple : Colors.purpleAccent;
      case 'completed':
        return isLight ? Colors.green : Colors.greenAccent;
      case 'failed':
        return isLight ? Colors.red : Colors.redAccent;
      default:
        return colorScheme.onSurface;
    }
  }

  // Connection status colors
  static Color getConnectedColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return colorScheme.brightness == Brightness.light
        ? Colors.green
        : Colors.greenAccent;
  }

  static Color getDisconnectedColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return colorScheme.brightness == Brightness.light
        ? Colors.red
        : Colors.redAccent;
  }

  // Background colors for status indicators
  static Color getConnectedBackgroundColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return colorScheme.brightness == Brightness.light
        ? Colors.green.shade50
        : Colors.green.withOpacity(0.1);
  }

  static Color getDisconnectedBackgroundColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return colorScheme.brightness == Brightness.light
        ? Colors.red.shade50
        : Colors.red.withOpacity(0.1);
  }

  // Border colors for status indicators
  static Color getConnectedBorderColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return colorScheme.brightness == Brightness.light
        ? Colors.green.shade200
        : Colors.green.withOpacity(0.3);
  }

  static Color getDisconnectedBorderColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return colorScheme.brightness == Brightness.light
        ? Colors.red.shade200
        : Colors.red.withOpacity(0.3);
  }
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static TextStyle subtitle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextStyle(
      fontSize: 14,
      color: colorScheme.onSurface.withOpacity(0.7),
    );
  }

  static TextStyle caption(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextStyle(
      fontSize: 12,
      color: colorScheme.onSurface.withOpacity(0.6),
    );
  }
}
