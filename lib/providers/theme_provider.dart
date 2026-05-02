import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secure_vault/core/color_theme.dart';

class ThemeState {
  final ThemeMode themeMode;
  final String colorThemeId;

  const ThemeState({required this.themeMode, required this.colorThemeId});

  ThemeState copyWith({ThemeMode? themeMode, String? colorThemeId}) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      colorThemeId: colorThemeId ?? this.colorThemeId,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier()
    : super(
        const ThemeState(
          themeMode: ThemeMode.system,
          colorThemeId: 'slate_lead',
        ),
      ) {
    _loadTheme();
  }

  static const _themeModeKey = 'theme_mode';
  static const _colorThemeKey = 'color_theme_id';

  /// Get current color theme data
  ColorThemeData get colorTheme => ColorThemes.getById(state.colorThemeId);

  void toggleTheme() {
    if (state.themeMode == ThemeMode.system) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      state = state.copyWith(
        themeMode: brightness == Brightness.dark
            ? ThemeMode.light
            : ThemeMode.dark,
      );
    } else {
      state = state.copyWith(
        themeMode: state.themeMode == ThemeMode.light
            ? ThemeMode.dark
            : ThemeMode.light,
      );
    }
    _saveTheme();
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _saveTheme();
  }

  void setColorTheme(String themeId) {
    state = state.copyWith(colorThemeId: themeId);
    _saveTheme();
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, state.themeMode.index);
    await prefs.setString(_colorThemeKey, state.colorThemeId);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    final themeModeIndex = prefs.getInt(_themeModeKey);
    final colorThemeId = prefs.getString(_colorThemeKey);

    ThemeMode? loadedThemeMode;
    if (themeModeIndex != null &&
        themeModeIndex >= 0 &&
        themeModeIndex < ThemeMode.values.length) {
      loadedThemeMode = ThemeMode.values[themeModeIndex];
    }

    state = ThemeState(
      themeMode: loadedThemeMode ?? ThemeMode.system,
      colorThemeId: colorThemeId ?? 'black_night',
    );
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});
