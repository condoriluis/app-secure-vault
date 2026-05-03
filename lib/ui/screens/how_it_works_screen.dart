import 'package:flutter/material.dart';

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    final steps = [
      (
        Icons.key_rounded,
        'Clave Maestra',
        'Al configurar la app, creas una Clave Maestra única. '
            'Esta clave nunca sale de tu dispositivo y es la única forma de descifrar tus datos.',
        primaryColor,
      ),
      (
        Icons.lock_rounded,
        'Cifrado AES-256',
        'Cada entrada se cifra individualmente usando AES-256-GCM, '
            'el estándar usado por gobiernos y bancos. Sin tu clave, los datos son ilegibles.',
        Colors.green.shade400,
      ),
      (
        Icons.fingerprint_rounded,
        'Autenticación',
        'Accede con biometría (huella / rostro) o PIN de 4 dígitos. '
            'Ambos métodos desbloquean tu Clave Maestra de forma segura.',
        Colors.blue.shade400,
      ),
      (
        Icons.category_rounded,
        'Tipos de Bóveda',
        'Organiza tus datos en 5 categorías: Login, Tarjeta de Crédito, '
            'Nota Segura (con editor enriquecido), Identidad y TOTP/2FA.',
        Colors.orange.shade400,
      ),
      (
        Icons.cloud_done_rounded,
        'Zero-Knowledge Backup',
        'Los respaldos se exportan ya cifrados. Nadie — ni la app, ni servidores — '
            'puede leer tus datos. Solo tú tienes la clave.',
        Colors.teal.shade400,
      ),
      (
        Icons.timer_off_rounded,
        'Bloqueo Automático',
        'Configura un tiempo de inactividad (inmediato, 10 seg, 1 min, 5 min o 10 min). '
            'La app se bloquea sola al salir o al cumplirse el tiempo.',
        Colors.purple.shade400,
      ),
    ];

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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Cómo funciona',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor.withOpacity(0.15), primaryColor.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_rounded, color: primaryColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Secure Vault es 100% local. Ningún dato tuyo llega a ningún servidor.',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...steps.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: s.$4.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: s.$4.withOpacity(0.4)),
                          ),
                          child: Icon(s.$1, color: s.$4, size: 22),
                        ),
                        if (i < steps.length - 1)
                          Container(
                            width: 2,
                            height: 28,
                            color: isDark
                                ? Colors.white12
                                : Colors.grey.shade200,
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.$2,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.$3,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
