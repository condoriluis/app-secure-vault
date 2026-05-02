import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:secure_vault/core/color_theme.dart';
import 'package:secure_vault/models/vault_entry.dart';
import 'package:secure_vault/providers/theme_provider.dart';
import 'package:secure_vault/services/auth_service.dart';
import 'package:secure_vault/ui/screens/about_screen.dart';
import 'package:secure_vault/ui/screens/auth_check_screen.dart';
import 'package:secure_vault/ui/screens/home_screen.dart';
import 'package:secure_vault/ui/screens/how_it_works_screen.dart';
import 'package:secure_vault/ui/screens/settings_screen.dart';
import 'package:secure_vault/ui/screens/trash_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = info.version;
        });
      }
    } catch (_) {
      _appVersion = '1.3.0';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _appLock() {
    ref.read(authServiceProvider).logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthCheckScreen()),
      (route) => false,
    );
  }

  void _openSettings() {
    Navigator.of(context).pop();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  void _openTrash() {
    Navigator.of(context).pop();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TrashScreen()));
  }

  void _openAbout() {
    Navigator.of(context).pop();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AboutScreen()));
  }

  void _openHowItWorks() {
    Navigator.of(context).pop();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const HowItWorksScreen()));
  }

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withOpacity(isDark ? 0.4 : 0.15),
                    primaryColor.withOpacity(isDark ? 0.15 : 0.05),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryColor.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.shield_rounded,
                      color: primaryColor,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Secure Vault',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_appVersion.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'v$_appVersion',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'JetBrainsMono',
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _buildVaultStats(context, ref),
                ],
              ),
            ),
            const SizedBox(height: 4),
            _drawerItem(
              context,
              icon: Icons.settings_rounded,
              label: 'Configuración',
              onTap: _openSettings,
            ),
            _drawerItem(
              context,
              icon: Icons.delete_outline_rounded,
              label: 'Papelera',
              onTap: _openTrash,
            ),
            _drawerItem(
              context,
              icon: Icons.help_outline_rounded,
              label: 'Cómo funciona',
              onTap: _openHowItWorks,
            ),
            _drawerItem(
              context,
              icon: Icons.info_outline_rounded,
              label: 'Acerca de',
              onTap: _openAbout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaultStats(BuildContext context, WidgetRef ref) {
    final vaultListAsync = ref.watch(vaultListProvider);
    final theme = Theme.of(context);

    return vaultListAsync.when(
      data: (entries) {
        final logins = entries.where((e) => e.type == VaultType.login).length;
        final cards = entries
            .where((e) => e.type == VaultType.creditCard)
            .length;
        final notes = entries
            .where((e) => e.type == VaultType.secureNote)
            .length;
        final identities = entries
            .where((e) => e.type == VaultType.identity)
            .length;
        final totps = entries.where((e) => e.type == VaultType.totp).length;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _statItem(
                  theme,
                  Icons.login_rounded,
                  logins,
                  'Logins',
                  Colors.blue.shade400,
                ),
                _statDivider(theme),
                _statItem(
                  theme,
                  Icons.credit_card_rounded,
                  cards,
                  'Tarjetas',
                  Colors.orange.shade400,
                ),
                _statDivider(theme),
                _statItem(
                  theme,
                  Icons.note_alt_rounded,
                  notes,
                  'Notas',
                  Colors.green.shade400,
                ),
                _statDivider(theme),
                _statItem(
                  theme,
                  Icons.badge_rounded,
                  identities,
                  'IDs',
                  Colors.purple.shade400,
                ),
                _statDivider(theme),
                _statItem(
                  theme,
                  Icons.vpn_key_rounded,
                  totps,
                  '2FA',
                  Colors.red.shade400,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Text(
                'Total: ${entries.length} elementos protegidos',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _statItem(
    ThemeData theme,
    IconData icon,
    int count,
    String label,
    Color color,
  ) {
    return Tooltip(
      message: '$count $label',
      child: Column(
        children: [
          Icon(icon, size: 18, color: color.withOpacity(0.8)),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider(ThemeData theme) {
    return Container(
      height: 20,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: theme.colorScheme.onSurface.withOpacity(0.1),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: effectiveColor, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: effectiveColor,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
      horizontalTitleGap: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final searchQuery = ref.watch(searchQueryProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: theme.colorScheme.surface,
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
          color: isDark ? null : theme.colorScheme.surface,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          drawer: _buildDrawer(context),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            toolbarHeight: 60,
            titleSpacing: 16,
            title: Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surface.withOpacity(0.8)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : primaryColor.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Hamburger
                  Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu_rounded, size: 22),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                      color: primaryColor,
                      tooltip: 'Menú',
                    ),
                  ),
                  // Search bar
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar en bóveda...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.45),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        isDense: true,
                        suffixIcon: searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  ref
                                      .read(searchQueryProvider.notifier)
                                      .set('');
                                },
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                              )
                            : null,
                      ),
                      onChanged: (v) =>
                          ref.read(searchQueryProvider.notifier).set(v),
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                    ),
                  ),
                  // Lock
                  IconButton(
                    icon: Icon(
                      ref.watch(authServiceProvider).isAuthenticated
                          ? Icons.lock_open_rounded
                          : Icons.lock_outline_rounded,
                      color: Colors.amber.shade700,
                      size: 22,
                    ),
                    onPressed: _appLock,
                    tooltip: 'Bloquear',
                  ),
                ],
              ),
            ),
          ),
          body: const HomeScreen(),
          floatingActionButton: _buildFloatingThemeSwitcher(context, ref),
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        ),
      ),
    );
  }

  Widget _buildFloatingThemeSwitcher(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return FloatingActionButton.small(
      onPressed: () => _showAppearanceDialog(context, ref),
      heroTag: 'theme_switcher',
      backgroundColor: theme.colorScheme.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Icon(
        Icons.palette_rounded,
        color: theme.colorScheme.primary,
        size: 20,
      ),
    );
  }

  void _showAppearanceDialog(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeNotifier = ref.read(themeProvider.notifier);
    final themeState = ref.watch(themeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            Icon(Icons.palette_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Personalización', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Modo Oscuro', style: TextStyle(fontSize: 14)),
              trailing: Switch(
                value: isDark,
                onChanged: (_) {
                  themeNotifier.toggleTheme();
                  Navigator.pop(context);
                },
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Paleta de Colores',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              width: double.maxFinite,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: ColorThemes.all.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final colorTheme = ColorThemes.all[index];
                  final isSelected = themeState.colorThemeId == colorTheme.id;
                  final primary = colorTheme.getPrimary(
                    isDark ? Brightness.dark : Brightness.light,
                  );

                  return GestureDetector(
                    onTap: () {
                      themeNotifier.setColorTheme(colorTheme.id);
                      Navigator.pop(context);
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? primary : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: primary.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                            ],
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          colorTheme.name.split(' ').first,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
