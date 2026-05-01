import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secure_vault/ui/screens/about_screen.dart';
import 'package:secure_vault/ui/screens/home_screen.dart';
import 'package:secure_vault/ui/screens/settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: isDark
            ? theme.colorScheme.surface
            : theme.colorScheme.surface,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withOpacity(0.08),
                    primaryColor.withOpacity(0.15),
                    primaryColor.withOpacity(0.35),
                    theme.colorScheme.secondary.withOpacity(0.25),
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                )
              : null,
          color: isDark ? null : theme.colorScheme.background,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: IndexedStack(
            index: _currentIndex,
            children: const [HomeScreen(), SettingsScreen(), AboutScreen()],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surface
                  : theme.colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : primaryColor.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
              border: isDark
                  ? Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.05),
                        width: 1,
                      ),
                    )
                  : null,
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: _onBottomNavTapped,
                backgroundColor: Colors.transparent,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: primaryColor,
                unselectedItemColor: theme.colorScheme.onSurface.withOpacity(
                  0.5,
                ),
                selectedFontSize: 12,
                unselectedFontSize: 11,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(
                      _currentIndex == 0
                          ? Icons.home_rounded
                          : Icons.home_outlined,
                    ),
                    label: 'Inicio',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(
                      _currentIndex == 1
                          ? Icons.settings_rounded
                          : Icons.settings_outlined,
                    ),
                    label: 'Configuración',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(
                      _currentIndex == 2
                          ? Icons.info_rounded
                          : Icons.info_outlined,
                    ),
                    label: 'Acerca de',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
