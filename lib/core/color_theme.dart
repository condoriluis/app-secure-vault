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

class ColorThemes {
  static const slateLead = ColorThemeData(
    id: 'slate_lead',
    name: 'Plomo Pizarra',
    lightPrimary: Color(0xFF475569),
    lightSecondary: Color(0xFF64748B),
    lightAccent: Color(0xFF94A3B8),
    darkPrimary: Color(0xFFCBD5E1),
    darkSecondary: Color(0xFF94A3B8),
    darkAccent: Color(0xFFE2E8F0),
  );

  static const burgundyRed = ColorThemeData(
    id: 'burgundy_red',
    name: 'Rojo Granate',
    lightPrimary: Color(0xFF991B1B),
    lightSecondary: Color(0xFFB91C1C),
    lightAccent: Color(0xFFEF4444),
    darkPrimary: Color(0xFFF87171),
    darkSecondary: Color(0xFFEF4444),
    darkAccent: Color(0xFFFECACA),
  );

  static const blueOcean = ColorThemeData(
    id: 'blue_ocean',
    name: 'Azul Profesional',
    lightPrimary: Color(0xFF2563EB),
    lightSecondary: Color(0xFF3B82F6),
    lightAccent: Color(0xFF60A5FA),
    darkPrimary: Color(0xFF93C5FD),
    darkSecondary: Color(0xFF60A5FA),
    darkAccent: Color(0xFFBFDBFE),
  );

  static const premiumGold = ColorThemeData(
    id: 'premium_gold',
    name: 'Oro Premium',
    lightPrimary: Color(0xFFB45309),
    lightSecondary: Color(0xFFD97706),
    lightAccent: Color(0xFFF59E0B),
    darkPrimary: Color(0xFFFBBF24),
    darkSecondary: Color(0xFFF59E0B),
    darkAccent: Color(0xFFFEF3C7),
  );

  static const midnightIndigo = ColorThemeData(
    id: 'midnight_indigo',
    name: 'Índigo Medianoche',
    lightPrimary: Color(0xFF4338CA),
    lightSecondary: Color(0xFF4F46E5),
    lightAccent: Color(0xFF6366F1),
    darkPrimary: Color(0xFFA5B4FC),
    darkSecondary: Color(0xFF818CF8),
    darkAccent: Color(0xFFC7D2FE),
  );

  static const matrix = ColorThemeData(
    id: 'matrix',
    name: 'Matrix',
    lightPrimary: Color(0xFF15803D),
    lightSecondary: Color(0xFF166534),
    lightAccent: Color(0xFF22C55E),
    darkPrimary: Color(0xFF22C55E),
    darkSecondary: Color(0xFF166534),
    darkAccent: Color(0xFF86EFAC),
  );

  static const carbonTech = ColorThemeData(
    id: 'carbon_tech',
    name: 'Negro Carbono',
    lightPrimary: Color(0xFF18181B),
    lightSecondary: Color(0xFF27272A),
    lightAccent: Color(0xFF3F3F46),
    darkPrimary: Color(0xFFE4E4E7),
    darkSecondary: Color(0xFFA1A1AA),
    darkAccent: Color(0xFF71717A),
  );

  static const cyberTeal = ColorThemeData(
    id: 'cyber_teal',
    name: 'Turquesa Cibernético',
    lightPrimary: Color(0xFF0D9488),
    lightSecondary: Color(0xFF14B8A6),
    lightAccent: Color(0xFF5EEAD4),
    darkPrimary: Color(0xFF99F6E4),
    darkSecondary: Color(0xFF5EEAD4),
    darkAccent: Color(0xFFCCFBF1),
  );

  static const List<ColorThemeData> all = [
    slateLead,
    burgundyRed,
    blueOcean,
    premiumGold,
    midnightIndigo,
    matrix,
    carbonTech,
    cyberTeal,
  ];

  static ColorThemeData getById(String id) {
    return all.firstWhere((theme) => theme.id == id, orElse: () => slateLead);
  }
}
