import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secure_vault/core/color_theme.dart';
import 'package:secure_vault/providers/theme_provider.dart';
import 'package:secure_vault/services/auth_service.dart';
import 'package:secure_vault/services/backup_service.dart';
import 'package:secure_vault/ui/widgets/app_bar.dart';
import 'package:secure_vault/ui/widgets/snackbar_message.dart';
import 'package:secure_vault/ui/screens/home_screen.dart'
    show vaultListProvider;
import 'package:secure_vault/providers/security_provider.dart';
import 'package:secure_vault/ui/screens/auth_check_screen.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;
  bool _hasPin = false;
  bool _hasBiometrics = false;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    final authService = ref.read(authServiceProvider);
    final hasPin = await authService.hasPin();
    final hasBiometrics = await authService.hasBiometrics();
    if (mounted) {
      setState(() {
        _hasPin = hasPin;
        _hasBiometrics = hasBiometrics;
      });
    }
  }

  Future<void> _togglePin(bool value) async {
    final authService = ref.read(authServiceProvider);
    if (value) {
      String pin = '';
      final success = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final theme = Theme.of(ctx);
          final primaryColor = theme.colorScheme.primary;
          final isDark = theme.brightness == Brightness.dark;
          return StatefulBuilder(
            builder: (ctx, setDialogState) {
              return Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: isDark ? theme.colorScheme.surface : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: isDark
                        ? Border.all(color: primaryColor.withOpacity(0.3))
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pin_rounded, size: 40, color: primaryColor),
                      const SizedBox(height: 12),
                      Text(
                        'Configurar PIN',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ingresa un PIN de 4 dígitos',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (i) {
                          final filled = i < pin.length;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: filled ? primaryColor : Colors.transparent,
                              border: Border.all(
                                color: filled
                                    ? primaryColor
                                    : theme.colorScheme.onSurface.withOpacity(
                                        0.3,
                                      ),
                                width: 2,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 4,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          letterSpacing: 20,
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'JetBrainsMono',
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.15,
                              ),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: primaryColor,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.shade50,
                        ),
                        onChanged: (v) {
                          setDialogState(() => pin = v);
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.15),
                                  ),
                                ),
                              ),
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(
                                'Cancelar',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              onPressed: pin.length == 4
                                  ? () => Navigator.pop(ctx, true)
                                  : null,
                              child: const Text(
                                'Guardar',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );

      if (success == true && pin.length == 4) {
        await authService.enablePin(pin);
        await _loadSecuritySettings();
        if (mounted) {
          showCustomSnackBar(
            context,
            'PIN activado correctamente',
            backgroundColor: Colors.green,
          );
        }
      }
    } else {
      await authService.disablePin();
      await _loadSecuritySettings();
      if (mounted) {
        showCustomSnackBar(
          context,
          'PIN desactivado',
          backgroundColor: Colors.orange,
        );
      }
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    final authService = ref.read(authServiceProvider);
    try {
      if (value) {
        await authService.enableBiometrics();
        if (mounted) {
          showCustomSnackBar(
            context,
            'Biometría activada',
            backgroundColor: Colors.green,
          );
        }
      } else {
        await authService.disableBiometrics();
        if (mounted) {
          showCustomSnackBar(
            context,
            'Biometría desactivada',
            backgroundColor: Colors.orange,
          );
        }
      }
      await _loadSecuritySettings();
    } catch (e) {
      if (mounted) showCustomSnackBar(context, 'Error con biometría: $e');
    }
  }

  Future<void> _exportVault() async {
    if (_isLoading) return;

    final entries = ref.read(vaultListProvider).value ?? [];
    if (entries.isEmpty) {
      if (mounted) {
        showCustomSnackBar(
          context,
          'Debe existir al menos un registro en la bóveda para poder exportar.',
          backgroundColor: Colors.orange.shade800,
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final backupService = ref.read(backupServiceProvider);
      final filePath = await backupService.exportVault();

      if (!mounted) return;
      final result = await SharePlus.instance.share(
        ShareParams(files: [XFile(filePath)], text: 'Mi Respaldo de Vault'),
      );

      if (result.status == ShareResultStatus.success) {
        if (!mounted) return;
        showCustomSnackBar(context, 'Bóveda exportada exitosamente.');
      }
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(context, 'Error al exportar: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _importVault() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final fp.FilePickerResult? result = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['vault', 'json'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final backupService = ref.read(backupServiceProvider);

        int count;
        try {
          count = await backupService.importVault(path);
        } catch (e) {
          if (e.toString().contains("SALT_INCOMPATIBLE")) {
            if (mounted) setState(() => _isLoading = false);
            final backupPassword = await _showRecoveryPasswordDialog();
            if (backupPassword == null || backupPassword.isEmpty) return;

            if (mounted) setState(() => _isLoading = true);
            count = await backupService.importVault(
              path,
              password: backupPassword,
            );
          } else {
            rethrow;
          }
        }

        if (!mounted) return;
        ref.invalidate(vaultListProvider);
        showCustomSnackBar(
          context,
          '¡Éxito! Se importaron $count entradas nuevas.',
          backgroundColor: Colors.green.shade700,
          durationSeconds: 4,
        );
      }
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceAll("Exception: ", "");

      Color snackColor = Colors.red.shade700;
      if (errorMsg.contains("Formato") ||
          errorMsg.contains("no es un backup") ||
          errorMsg.contains("reconocido")) {
        snackColor = Colors.orange.shade800;
      }

      showCustomSnackBar(
        context,
        errorMsg,
        backgroundColor: snackColor,
        durationSeconds: 5,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _showRecoveryPasswordDialog() async {
    final TextEditingController controller = TextEditingController();
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isInputEmpty = controller.text.trim().isEmpty;

          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: isDark
                  ? BorderSide(color: primaryColor.withOpacity(0.3), width: 1.5)
                  : BorderSide.none,
            ),
            title: Row(
              children: [
                const Icon(Icons.security_rounded, color: Colors.amber),
                const SizedBox(width: 12),
                const Text('Recuperación'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Este respaldo tiene un Master Salt distinto al de tu sesión actual.',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Para recuperarlo, ingresa la Clave Maestra que usabas cuando creaste este respaldo:',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  obscureText: true,
                  autofocus: true,
                  onChanged: (value) => setDialogState(() {}),
                  style: const TextStyle(fontFamily: 'JetBrainsMono'),
                  decoration: InputDecoration(
                    labelText: 'Clave Maestra del Respaldo',
                    labelStyle: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 13,
                    ),
                    hintText: 'Clave maestra antiguo',
                    hintStyle: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.lock_reset_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nota: Tus registros actuales no se verán afectados.',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isInputEmpty
                        ? [Colors.grey, Colors.grey.shade400]
                        : [primaryColor, primaryColor.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isInputEmpty
                      ? null
                      : [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: FilledButton.icon(
                  onPressed: isInputEmpty
                      ? null
                      : () => Navigator.pop(context, controller.text),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    disabledForegroundColor: isDark
                        ? Colors.white30
                        : Colors.black26,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.history_rounded, size: 20),
                  label: const Text(
                    'Recuperar Datos',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _resetApp() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: isDark
              ? BorderSide(color: Colors.red.withOpacity(0.3), width: 1.5)
              : BorderSide.none,
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
            const SizedBox(width: 12),
            const Text('Zona de Peligro'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¿Estás seguro de que deseas restablecer la aplicación?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'Esta acción es IRREVERSIBLE. Se eliminarán permanentemente:\n\n'
              '• Todos tus registros y contraseñas\n'
              '• Tu Clave Maestra y Master Salt\n'
              '• Tu PIN y configuración Biométrica\n'
              '• Tus preferencias de tema',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [Colors.red.shade600, Colors.red.shade800],
                    ),
                  ),
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Restablecer Todo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await ref.read(authServiceProvider).resetAllData();
        ref.invalidate(vaultListProvider);

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthCheckScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          showCustomSnackBar(
            context,
            'Error al restablecer: $e',
            backgroundColor: Colors.red,
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final themeState = ref.watch(themeProvider);

    return Container(
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
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            decoration: isDark
                ? BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryColor.withOpacity(0.08),
                        primaryColor.withOpacity(0.15),
                        primaryColor.withOpacity(0.35),
                        theme.colorScheme.secondary.withOpacity(0.25),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                  )
                : null,
            child: MyAppBar(
              isAuthenticated: ref.watch(authServiceProvider).isAuthenticated,
              appLockCallback: () {
                ref.read(authServiceProvider).logout();
              },
              title: 'Configuración',
            ),
          ),
        ),
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(14),
              children: [
                _buildSectionTitle('Apariencia', theme),
                Card(
                  elevation: 0,
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          isDark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: isDark ? primaryColor : Colors.amber,
                        ),
                        title: const Text(
                          'Modo Oscuro',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Switch(
                          value:
                              themeState.themeMode == ThemeMode.dark ||
                              (themeState.themeMode == ThemeMode.system &&
                                  isDark),
                          onChanged: (_) =>
                              ref.read(themeProvider.notifier).toggleTheme(),
                          activeColor: primaryColor,
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.shade200,
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.color_lens_rounded,
                          color: primaryColor,
                        ),
                        title: const Text(
                          'Paleta de Colores',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ColorThemes.all.map((colorTheme) {
                              final isSelected =
                                  themeState.colorThemeId == colorTheme.id;
                              return GestureDetector(
                                onTap: () => ref
                                    .read(themeProvider.notifier)
                                    .setColorTheme(colorTheme.id),
                                child: Container(
                                  margin: const EdgeInsets.only(
                                    right: 8,
                                    top: 8,
                                    bottom: 8,
                                  ),
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: colorTheme.getPrimary(
                                      theme.brightness,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? theme.colorScheme.onSurface
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Icon(
                                          Icons.check,
                                          size: 20,
                                          color: theme.colorScheme.onPrimary,
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                _buildSectionTitle('Seguridad', theme),
                Card(
                  elevation: 0,
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.pin_rounded, color: primaryColor),
                        title: const Text(
                          'PIN de Seguridad',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text('Acceso rápido con 4 dígitos'),
                        trailing: Switch(
                          value: _hasPin,
                          onChanged: _togglePin,
                          activeColor: primaryColor,
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.shade200,
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.fingerprint_rounded,
                          color: primaryColor,
                        ),
                        title: const Text(
                          'Biometría',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text('Desbloqueo con huella o rostro'),
                        trailing: Switch(
                          value: _hasBiometrics,
                          onChanged: _toggleBiometrics,
                          activeColor: primaryColor,
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.shade200,
                      ),
                      ListTile(
                        leading: Icon(Icons.timer_rounded, color: primaryColor),
                        title: const Text(
                          'Bloqueo Automático',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Bloquear al salir: ${ref.watch(securityProvider).autoLockTimeout.label}',
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: isDark ? Colors.white60 : Colors.black45,
                        ),
                        onTap: () => _showAutoLockSelector(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                _buildSectionTitle(
                  'Respaldo en la Nube (Zero-Knowledge)',
                  theme,
                ),
                Card(
                  elevation: 0,
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.upload_file_rounded,
                            color: primaryColor,
                          ),
                        ),
                        title: const Text(
                          'Exportar Bóveda',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'Crea un archivo cifrado con todas tus contraseñas.',
                        ),
                        onTap: _isLoading ? null : _exportVault,
                      ),
                      Divider(
                        height: 1,
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.shade200,
                      ),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.download_rounded,
                            color: Colors.green,
                          ),
                        ),
                        title: const Text(
                          'Importar Bóveda',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'Restaura tus contraseñas desde un archivo.',
                        ),
                        onTap: _isLoading ? null : _importVault,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.security_rounded,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tus respaldos están cifrados militarmente. Nadie puede leer tus contraseñas sin tu Clave Maestra.',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('Zona de Peligro', theme),
                Card(
                  elevation: 0,
                  color: isDark
                      ? Colors.red.withOpacity(0.05)
                      : Colors.red.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark
                          ? Colors.red.withOpacity(0.2)
                          : Colors.red.shade100,
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete_forever_rounded,
                        color: Colors.red.shade600,
                      ),
                    ),
                    title: Text(
                      'Restablecer Aplicación',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    subtitle: const Text(
                      'Borra todos los datos y comienza desde cero.',
                    ),
                    onTap: _isLoading ? null : _resetApp,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4, top: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showAutoLockSelector(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final currentTimeout = ref.read(securityProvider).autoLockTimeout;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tiempo de Bloqueo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ...AutoLockTimeout.values.map((timeout) {
              final isSelected = currentTimeout == timeout;
              return ListTile(
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: isSelected ? primaryColor : Colors.grey,
                ),
                title: Text(
                  timeout.label,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? primaryColor
                        : theme.colorScheme.onSurface,
                  ),
                ),
                onTap: () {
                  ref
                      .read(securityProvider.notifier)
                      .setAutoLockTimeout(timeout);
                  Navigator.pop(context);
                },
              );
            }).toList(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
