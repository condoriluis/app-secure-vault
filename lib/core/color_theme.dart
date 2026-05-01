import 'package:flutter/material.dart';

class ColorThemeData {
  final String id;
  final String name;
  final Color lightPrimary;
  final Color lightSecondary;
  final Color lightAccent;
  final Color darkPrimary;
  final Color darkSecondary;
  final Color darkAccent;

  const ColorThemeData({
    required this.id,
    required this.name,
    required this.lightPrimary,
    required this.lightSecondary,
    required this.lightAccent,
    required this.darkPrimary,
    required this.darkSecondary,
    required this.darkAccent,
  });

  Color getPrimary(Brightness brightness) {
    return brightness == Brightness.dark ? darkPrimary : lightPrimary;
  }

  Color getSecondary(Brightness brightness) {
    return brightness == Brightness.dark ? darkSecondary : lightSecondary;
  }

  Color getAccent(Brightness brightness) {
    return brightness == Brightness.dark ? darkAccent : lightAccent;
  }
}

/// Predefined professional color themes
class ColorThemes {
  static const blackNight = ColorThemeData(
    id: 'black_night',
    name: 'Black Night',
    lightPrimary: Color(0xFF2C2C2C),
    lightSecondary: Color(0xFF3A3A3A),
    lightAccent: Color(0xFF4A4A4A),
    darkPrimary: Color(0xFF9E9E9E),
    darkSecondary: Color(0xFF616161),
    darkAccent: Color(0xFF757575),
  );

  static const blueOcean = ColorThemeData(
    id: 'blue_ocean',
    name: 'Blue Ocean',
    lightPrimary: Color(0xFF2563EB),
    lightSecondary: Color(0xFF3B82F6),
    lightAccent: Color(0xFF60A5FA),
    darkPrimary: Color(0xFF0EA5E9),
    darkSecondary: Color(0xFF0284C7),
    darkAccent: Color(0xFF38BDF8),
  );

  static const purpleDream = ColorThemeData(
    id: 'purple_dream',
    name: 'Purple Dream',
    lightPrimary: Color(0xFF9333EA),
    lightSecondary: Color(0xFFA855F7),
    lightAccent: Color(0xFFC084FC),
    darkPrimary: Color(0xFFA78BFA),
    darkSecondary: Color(0xFF8B5CF6),
    darkAccent: Color(0xFFC4B5FD),
  );

  static const emeraldForest = ColorThemeData(
    id: 'emerald_forest',
    name: 'Emerald Forest',
    lightPrimary: Color(0xFF059669),
    lightSecondary: Color(0xFF10B981),
    lightAccent: Color(0xFF34D399),
    darkPrimary: Color(0xFF10B981),
    darkSecondary: Color(0xFF059669),
    darkAccent: Color(0xFF6EE7B7),
  );

  static const sunsetOrange = ColorThemeData(
    id: 'sunset_orange',
    name: 'Sunset Orange',
    lightPrimary: Color(0xFFEA580C),
    lightSecondary: Color(0xFFF97316),
    lightAccent: Color(0xFFFB923C),
    darkPrimary: Color(0xFFFB923C),
    darkSecondary: Color(0xFFF97316),
    darkAccent: Color(0xFFFDBA74),
  );

  static const roseGold = ColorThemeData(
    id: 'rose_gold',
    name: 'Rose Gold',
    lightPrimary: Color(0xFFE11D48),
    lightSecondary: Color(0xFFF43F5E),
    lightAccent: Color(0xFFFB7185),
    darkPrimary: Color(0xFFFB7185),
    darkSecondary: Color(0xFFF43F5E),
    darkAccent: Color(0xFFFDA4AF),
  );

  static const midnight = ColorThemeData(
    id: 'midnight',
    name: 'Midnight',
    lightPrimary: Color(0xFF4338CA),
    lightSecondary: Color(0xFF4F46E5),
    lightAccent: Color(0xFF6366F1),
    darkPrimary: Color(0xFF818CF8),
    darkSecondary: Color(0xFF6366F1),
    darkAccent: Color(0xFFA5B4FC),
  );

  static const matrixHacker = ColorThemeData(
    id: 'matrix_hacker',
    name: 'Matrix Hacker',
    lightPrimary: Color(0xFF00A86B),
    lightSecondary: Color(0xFF00C781),
    lightAccent: Color(0xFF00E396),
    darkPrimary: Color(0xFF00FF41),
    darkSecondary: Color(0xFF00D936),
    darkAccent: Color(0xFF39FF14),
  );

  static const List<ColorThemeData> all = [
    blackNight,
    blueOcean,
    purpleDream,
    emeraldForest,
    sunsetOrange,
    roseGold,
    midnight,
    matrixHacker,
  ];

  static ColorThemeData getById(String id) {
    return all.firstWhere((theme) => theme.id == id, orElse: () => blackNight);
  }
}
