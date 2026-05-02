import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _appVersion = '1.0.2';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

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
        color: isDark ? null : theme.colorScheme.background,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Acerca de',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 14),
              // App Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isDark
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryColor.withOpacity(0.8),
                            primaryColor.withOpacity(0.4),
                          ],
                        )
                      : null,
                  color: isDark ? null : primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              // App Name
              Text(
                'Secure Vault',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onBackground,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 0),
              // Version
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            Colors.white.withOpacity(0.15),
                            Colors.white.withOpacity(0.05),
                          ]
                        : [Colors.white, Colors.grey.shade50],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    isDark
                        ? BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        : BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                  ],
                ),
                child: Text(
                  'Versión $_appVersion',
                  style: TextStyle(
                    fontFamily: "JetBrainsMono",
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            Colors.white.withOpacity(0.15),
                            Colors.white.withOpacity(0.05),
                          ]
                        : [Colors.white, Colors.grey.shade50],
                  ),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    isDark
                        ? BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        : BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                  ],
                ),
                child: Text(
                  'Bóveda personal con cifrado AES-256. Guarda contraseñas, tarjetas, notas, identidades y códigos 2FA. Acceso biométrico, bloqueo automático y respaldo seguro — todo Zero-Knowledge.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: theme.colorScheme.onSurface.withOpacity(0.9),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _buildFeatureCard(
                Icons.security_rounded,
                'Encriptación AES-256',
                'Tus datos están protegidos con encriptación de nivel militar',
                Colors.green.shade400,
                theme,
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                Icons.fingerprint_rounded,
                'Autenticación Biométrica',
                'Accede de forma segura con huella dactilar o reconocimiento facial',
                Colors.blue.shade400,
                theme,
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                Icons.backup_rounded,
                'Backup y Restauración',
                'Realiza copias de seguridad y restaura tus datos cuando lo necesites',
                Colors.orange.shade400,
                theme,
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                Icons.edit_note_rounded,
                'Editor de Notas Seguras',
                'Notas con formato enriquecido: negrita, cursiva, colores y más',
                Colors.purple.shade400,
                theme,
              ),
              const SizedBox(height: 14),
              // Tipos de bóveda
              _buildVaultTypesCard(theme, isDark, primaryColor),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            Colors.white.withOpacity(0.15),
                            Colors.white.withOpacity(0.05),
                          ]
                        : [Colors.white, Colors.grey.shade50],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    isDark
                        ? BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        : BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Protegido con encriptación AES-256',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVaultTypesCard(
    ThemeData theme,
    bool isDark,
    Color primaryColor,
  ) {
    final types = [
      (
        Icons.lock_rounded,
        'Login',
        'Credenciales de sitios web y apps',
        Colors.blue.shade400,
      ),
      (
        Icons.credit_card_rounded,
        'Tarjeta de Crédito',
        'Tarjetas bancarias y de débito',
        Colors.deepOrange.shade400,
      ),
      (
        Icons.sticky_note_2_rounded,
        'Nota Segura',
        'Notas privadas con editor enriquecido',
        Colors.purple.shade400,
      ),
      (
        Icons.badge_rounded,
        'Identidad',
        'DNI, pasaporte y documentos de ID',
        Colors.teal.shade400,
      ),
      (
        Icons.qr_code_rounded,
        'TOTP / 2FA',
        'Códigos de autenticación de dos factores',
        Colors.amber.shade600,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)]
              : [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          isDark
              ? BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              : BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.category_rounded,
                  size: 20,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Tipos de Bóveda',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...types.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: t.$4.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(t.$1, size: 18, color: t.$4),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.$2,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          t.$3,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    IconData icon,
    String title,
    String description,
    Color color,
    ThemeData theme,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)]
              : [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          isDark
              ? BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              : BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
