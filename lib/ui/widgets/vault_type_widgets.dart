import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otp/otp.dart';

class CreditCardWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isVisible;

  const CreditCardWidget({
    super.key,
    required this.data,
    this.isVisible = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final number = data['number'] ?? '**** **** **** ****';
    final holder = data['holder'] ?? 'CARD HOLDER';
    final expiry = data['expiry'] ?? 'MM/YY';
    final cvv = data['cvv'] ?? '***';
    final brand = data['brand'] ?? 'Visa';

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.8),
            theme.colorScheme.secondary.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Gloss effect
            Positioned(
              top: -100,
              left: -100,
              child: Transform.rotate(
                angle: -0.5,
                child: Container(
                  width: 300,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.contactless,
                        color: Colors.white.withOpacity(0.8),
                        size: 30,
                      ),
                      Text(
                        brand.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.sim_card_outlined,
                        color: Colors.white.withOpacity(0.5),
                        size: 35,
                      ),
                    ],
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      isVisible ? number : _maskCardNumber(number),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4,
                        fontFamily: 'JetBrainsMono',
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.6),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CARD HOLDER',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            holder.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EXPIRES',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            expiry,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (isVisible)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CVV',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 10,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              isVisible ? cvv : '***',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _maskCardNumber(String number) {
    if (number.length < 4) return "****";
    final last4 = number.substring(number.length - 4);
    return "**** **** **** $last4";
  }
}

class TOTPWidget extends StatefulWidget {
  final String secret;
  final bool isVisible;

  const TOTPWidget({super.key, required this.secret, this.isVisible = false});

  @override
  State<TOTPWidget> createState() => _TOTPWidgetState();
}

class _TOTPWidgetState extends State<TOTPWidget> {
  String _code = "000000";
  double _progress = 1.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _updateCode();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCode();
    });
  }

  void _updateCode() {
    if (widget.secret.isEmpty) return;
    try {
      String secret = widget.secret.trim();

      if (secret.startsWith('otpauth://')) {
        final uri = Uri.parse(secret);
        secret = uri.queryParameters['secret'] ?? secret;
      }

      secret = secret.replaceAll(' ', '').toUpperCase();

      final now = DateTime.now().millisecondsSinceEpoch;
      final code = OTP.generateTOTPCodeString(
        secret,
        now,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );

      final seconds = (now / 1000).floor() % 30;

      setState(() {
        _code = code;
        _progress = (30 - seconds) / 30;
      });
    } catch (e) {
      setState(() {
        _code = "ERROR";
        _progress = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        if (widget.isVisible && _code != "ERROR") {
          Clipboard.setData(ClipboardData(text: _code));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Código copiado al portapapeles'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: theme.colorScheme.primary,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _code.length; i++) ...[
                    if (i == 3) const SizedBox(width: 15),
                    Container(
                      width: 40,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.isVisible ? _code[i] : '•',
                        style: TextStyle(
                          fontSize: widget.isVisible ? 28 : 36,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          fontFamily: 'JetBrainsMono',
                        ),
                      ),
                    ),
                    if (i < _code.length - 1 && i != 2)
                      const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: theme.colorScheme.outline.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(
                _progress < 0.2 ? Colors.red : theme.colorScheme.primary,
              ),
            ),
            if (widget.isVisible && _code != "ERROR") ...[
              const SizedBox(height: 8),
              Text(
                'TOCA PARA COPIAR',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary.withOpacity(0.6),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class IdentityWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isVisible;

  const IdentityWidget({super.key, required this.data, this.isVisible = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final name = data['full_name'] ?? 'NOMBRE COMPLETO';
    final number = isVisible
        ? (data['number'] ?? '00000000')
        : _maskValue(data['number'] ?? '00000000');
    final type = data['id_type'] ?? 'IDENTIDAD';
    final expiry = data['expiry'] ?? '00/00/0000';
    final country = data['country'] ?? 'PAÍS';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2C3E50), const Color(0xFF000000)]
              : [const Color(0xFFE0EAFC), const Color(0xFFCFDEF3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.15) : Colors.white,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              top: -150,
              left: -100,
              child: Transform.rotate(
                angle: -0.4,
                child: Container(
                  width: 500,
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.5),
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.0),
                      ],
                      stops: const [0.2, 0.45, 0.5, 0.55, 0.8],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: -20,
              child: Transform.rotate(
                angle: 0.5,
                child: Container(
                  width: 400,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 60,
                            height: 75,
                            decoration: BoxDecoration(
                              color:
                                  (isDark
                                          ? Colors.white
                                          : theme.colorScheme.primary)
                                      .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    (isDark
                                            ? Colors.white
                                            : theme.colorScheme.primary)
                                        .withOpacity(0.2),
                              ),
                            ),
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color:
                                  (isDark
                                          ? Colors.white
                                          : theme.colorScheme.primary)
                                      .withOpacity(0.4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 65,
                            child: Text(
                              type.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color:
                                    (isDark
                                            ? Colors.white
                                            : theme.colorScheme.primary)
                                        .withOpacity(0.8),
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCardLabel(
                              isDark,
                              theme,
                              'NOMBRE Y APELLIDOS',
                            ),
                            Text(
                              name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.2),
                                    offset: const Offset(0, 1),
                                    blurRadius: 1,
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            _buildCardLabel(
                              isDark,
                              theme,
                              'NÚMERO DE DOCUMENTO',
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                number,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? Colors.white
                                      : theme.colorScheme.primary,
                                  fontFamily: 'JetBrainsMono',
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.2),
                                      offset: const Offset(0, 1),
                                      blurRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFooterItem(isDark, theme, 'PAÍS', country),
                      _buildFooterItem(
                        isDark,
                        theme,
                        'VENCIMIENTO',
                        expiry,
                        isEnd: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardLabel(bool isDark, ThemeData theme, String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 9,
        color: (isDark ? Colors.white : theme.colorScheme.onSurface)
            .withOpacity(0.5),
        letterSpacing: 1,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFooterItem(
    bool isDark,
    ThemeData theme,
    String label,
    String value, {
    bool isEnd = false,
  }) {
    return Column(
      crossAxisAlignment: isEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        _buildCardLabel(isDark, theme, label),
        const SizedBox(height: 2),
        Text(
          value.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  String _maskValue(String value) {
    if (value.length <= 4) return "****";
    return "****${value.substring(value.length - 4)}";
  }
}
