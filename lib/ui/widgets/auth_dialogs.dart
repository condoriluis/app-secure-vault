import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secure_vault/services/auth_service.dart';
import 'package:secure_vault/providers/security_provider.dart';
import 'package:secure_vault/ui/widgets/snackbar_message.dart';

class AuthDialogUtils {
  static Future<bool> requestAuth(BuildContext context, WidgetRef ref) async {
    final authService = ref.read(authServiceProvider);

    if (await authService.hasBiometrics()) {
      ref.read(securityProvider.notifier).setBypassingAutoLock(true);
      final success = await authService.loginWithBiometrics();
      if (success) return true;
    }

    if (!context.mounted) return false;

    if (await authService.hasPin()) {
      final pin = await showDialog<String>(
        context: context,
        builder: (context) => const PinVerifyDialog(),
      );

      if (pin != null) {
        final success = await authService.loginWithPin(pin);
        if (success) return true;

        if (context.mounted) {
          showCustomSnackBar(
            context,
            'PIN Incorrecto',
            backgroundColor: Colors.red,
          );
        }
      } else {
        return false;
      }
    }

    if (!context.mounted) return false;

    final password = await showDialog<String>(
      context: context,
      builder: (context) => const PasswordVerifyDialog(),
    );

    if (password != null) {
      final success = await authService.login(password);
      if (success) return true;

      if (context.mounted) {
        showCustomSnackBar(
          context,
          'Contraseña Incorrecta',
          backgroundColor: Colors.red,
        );
      }
    }

    return false;
  }
}

class PinVerifyDialog extends StatefulWidget {
  const PinVerifyDialog({super.key});

  @override
  State<PinVerifyDialog> createState() => _PinVerifyDialogState();
}

class _PinVerifyDialogState extends State<PinVerifyDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return AlertDialog(
      backgroundColor: isDark
          ? theme.colorScheme.surface.withOpacity(0.95)
          : theme.dialogTheme.backgroundColor,
      title: Text(
        'Verificar PIN',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
          fontSize: 20,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark
              ? primaryColor.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontFamily: 'JetBrainsMono',
              letterSpacing: 16,
              color: textColor,
            ),
            decoration: InputDecoration(
              hintText: '••••',
              counterText: '',
              border: InputBorder.none,
              hintStyle: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.3),
                letterSpacing: 16,
              ),
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.all(16),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Verificar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class PasswordVerifyDialog extends StatefulWidget {
  const PasswordVerifyDialog({super.key});

  @override
  State<PasswordVerifyDialog> createState() => _PasswordVerifyDialogState();
}

class _PasswordVerifyDialogState extends State<PasswordVerifyDialog> {
  final _controller = TextEditingController();
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return AlertDialog(
      backgroundColor: isDark
          ? theme.colorScheme.surface.withOpacity(0.95)
          : theme.dialogTheme.backgroundColor,
      title: Text(
        'Verificar Identidad',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
          fontSize: 20,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark
              ? primaryColor.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      content: TextField(
        controller: _controller,
        obscureText: _isObscured,
        style: TextStyle(color: textColor, fontFamily: 'JetBrainsMono'),
        decoration: InputDecoration(
          labelText: 'Contraseña maestra',
          labelStyle: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onBackground.withOpacity(0.7),
            fontFamily: 'JetBrainsMono',
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
          suffixIcon: IconButton(
            icon: Icon(_isObscured ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _isObscured = !_isObscured),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.all(16),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Verificar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
