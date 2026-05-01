import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secure_vault/services/auth_service.dart';
import 'package:secure_vault/ui/screens/main_screen.dart';
import 'package:secure_vault/ui/widgets/snackbar_message.dart';

class AnimatedLoginScreen extends ConsumerStatefulWidget {
  const AnimatedLoginScreen({super.key});

  @override
  ConsumerState<AnimatedLoginScreen> createState() =>
      _AnimatedLoginScreenState();
}

class _AnimatedLoginScreenState extends ConsumerState<AnimatedLoginScreen>
    with TickerProviderStateMixin {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isObscured = true;
  bool _hasPin = false;
  bool _hasBiometrics = false;

  // Animation Controllers
  late AnimationController _logoController;
  late AnimationController _contentController;
  late AnimationController _pulseController;

  // Animations
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _pulseAnimation;

  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _titleSlideAnimation;

  late Animation<double> _subtitleFadeAnimation;
  late Animation<Offset> _subtitleSlideAnimation;

  late Animation<double> _fieldFadeAnimation;
  late Animation<Offset> _fieldSlideAnimation;

  late Animation<double> _buttonFadeAnimation;
  late Animation<Offset> _buttonSlideAnimation;

  late Animation<double> _optionsFadeAnimation;
  late Animation<Offset> _optionsSlideAnimation;

  @override
  void initState() {
    super.initState();
    _checkAuthMethods();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Logo animation controller (800ms)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Content animation controller (1200ms)
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Pulse animation controller (continuous)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Logo animations
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    _logoRotationAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Title animations (starts at 200ms)
    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.15, 0.45, curve: Curves.easeOut),
      ),
    );

    _titleSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _contentController,
            curve: const Interval(0.15, 0.45, curve: Curves.easeOutCubic),
          ),
        );

    // Subtitle animations (starts at 400ms)
    _subtitleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.30, 0.55, curve: Curves.easeOut),
      ),
    );

    _subtitleSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _contentController,
            curve: const Interval(0.30, 0.55, curve: Curves.easeOutCubic),
          ),
        );

    // Field animations (starts at 600ms)
    _fieldFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.45, 0.70, curve: Curves.easeOut),
      ),
    );

    _fieldSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _contentController,
            curve: const Interval(0.45, 0.70, curve: Curves.easeOutCubic),
          ),
        );

    // Button animations (starts at 800ms)
    _buttonFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.60, 0.85, curve: Curves.easeOut),
      ),
    );

    _buttonSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _contentController,
            curve: const Interval(0.60, 0.85, curve: Curves.easeOutCubic),
          ),
        );

    // Options animations (starts at 1000ms)
    _optionsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
      ),
    );

    _optionsSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _contentController,
            curve: const Interval(0.75, 1.0, curve: Curves.easeOutCubic),
          ),
        );
  }

  void _startAnimations() {
    _logoController.forward();
    _contentController.forward();
  }

  Future<void> _checkAuthMethods() async {
    final auth = ref.read(authServiceProvider);
    final hasPin = await auth.hasPin();
    final hasBio = await auth.hasBiometrics();
    if (mounted) {
      setState(() {
        _hasPin = hasPin;
        _hasBiometrics = hasBio;
      });
    }
  }

  Future<void> _login() async {
    if (_passwordController.text.trim().isEmpty) {
      if (mounted) {
        showCustomSnackBar(
          context,
          'Por favor, ingresa tu contraseña maestra',
          durationSeconds: 2,
          backgroundColor: Colors.orange.shade800,
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await ref
          .read(authServiceProvider)
          .login(_passwordController.text);
      if (success) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const MainScreen(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        }
      } else {
        if (mounted) {
          showCustomSnackBar(
            context,
            'Contraseña maestra incorrecta',
            durationSeconds: 3,
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context,
          'Error: $e',
          durationSeconds: 2,
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithPin() async {
    final pin = await showDialog<String>(
      context: context,
      builder: (context) => _PinDialog(),
    );

    if (pin != null) {
      setState(() => _isLoading = true);
      try {
        final success = await ref.read(authServiceProvider).loginWithPin(pin);
        if (success) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const MainScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }
        } else {
          if (mounted) {
            showCustomSnackBar(
              context,
              'PIN incorrecto',
              durationSeconds: 2,
              backgroundColor: Colors.red,
            );
          }
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loginWithBio() async {
    setState(() => _isLoading = true);
    try {
      final success = await ref.read(authServiceProvider).loginWithBiometrics();
      if (success) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const MainScreen(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        }
      } else {
        if (mounted) {
          showCustomSnackBar(
            context,
            'Biometría falló o no configurada',
            durationSeconds: 3,
            backgroundColor: Colors.red,
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _contentController.dispose();
    _pulseController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Animated Logo
                  _buildAnimatedLogo(primaryColor),
                  const SizedBox(height: 48),

                  // Animated Title
                  _buildAnimatedTitle(),
                  const SizedBox(height: 8),

                  // Animated Subtitle
                  _buildAnimatedSubtitle(),
                  const SizedBox(height: 48),

                  // Animated Password Field
                  _buildAnimatedPasswordField(primaryColor),
                  const SizedBox(height: 24),

                  // Animated Login Button
                  _buildAnimatedLoginButton(primaryColor, onPrimaryColor),

                  // Animated Alternative Options
                  if (_hasPin || _hasBiometrics) ...[
                    const SizedBox(height: 20),
                    _buildAnimatedDivider(),
                    const SizedBox(height: 20),
                    _buildAnimatedOptions(primaryColor),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo(Color primaryColor) {
    return FadeTransition(
      opacity: _logoFadeAnimation,
      child: ScaleTransition(
        scale: _logoScaleAnimation,
        child: RotationTransition(
          turns: _logoRotationAnimation,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing glow effect
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    height: 140 * _pulseAnimation.value,
                    width: 140 * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  );
                },
              ),
              // Glassmorphism container
              Container(
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: Theme.of(context).brightness == Brightness.dark
                        ? [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.05),
                          ]
                        : [Colors.white, Colors.grey.shade100],
                  ),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    Theme.of(context).brightness == Brightness.dark
                        ? BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        : BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                  ],
                ),
                child: Center(
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryColor.withOpacity(0.8),
                          primaryColor.withOpacity(0.4),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Lock badge
              Positioned(
                bottom: 5,
                right: 5,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 24,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTitle() {
    return FadeTransition(
      opacity: _titleFadeAnimation,
      child: SlideTransition(
        position: _titleSlideAnimation,
        child: Text(
          'Secure Vault',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
            letterSpacing: -0.5,
            shadows: [
              Shadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black26
                    : Colors.grey.withOpacity(0.3),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedSubtitle() {
    return FadeTransition(
      opacity: _subtitleFadeAnimation,
      child: SlideTransition(
        position: _subtitleSlideAnimation,
        child: Text(
          'Tu seguridad es nuestra prioridad',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.8)
                : Colors.grey.shade600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedPasswordField(Color primaryColor) {
    return FadeTransition(
      opacity: _fieldFadeAnimation,
      child: SlideTransition(
        position: _fieldSlideAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              Theme.of(context).brightness == Brightness.dark
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
          child: TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Contraseña Maestra',
              labelStyle: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.7)
                    : Colors.grey.shade600,
                fontFamily: "JetBrainsMono",
              ),
              hintText: 'Ingresa tu contraseña',
              hintStyle: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.4)
                    : Colors.grey.shade400,
                fontFamily: "JetBrainsMono",
              ),
              prefixIcon: Icon(
                Icons.vpn_key_rounded,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.7)
                    : Colors.grey.shade500,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.7)
                      : Colors.grey.shade500,
                ),
                onPressed: () => setState(() => _isObscured = !_isObscured),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: primaryColor.withOpacity(0.8),
                  width: 2,
                ),
              ),
            ),
            obscureText: _isObscured,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
              fontFamily: 'JetBrainsMono',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLoginButton(Color primaryColor, Color onPrimaryColor) {
    return FadeTransition(
      opacity: _buttonFadeAnimation,
      child: SlideTransition(
        position: _buttonSlideAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, primaryColor.withOpacity(0.8)],
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : _login,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: _isLoading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: onPrimaryColor,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'DESBLOQUEAR',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedDivider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _optionsFadeAnimation,
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: isDark
                  ? Colors.white.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              'O inicia con',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.6)
                    : Colors.black.withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: 'JetBrainsMono',
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: isDark
                  ? Colors.white.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedOptions(Color primaryColor) {
    return FadeTransition(
      opacity: _optionsFadeAnimation,
      child: SlideTransition(
        position: _optionsSlideAnimation,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_hasPin)
              _AnimatedAuthOptionButton(
                icon: Icons.pin_rounded,
                label: 'PIN',
                onTap: _isLoading ? null : _loginWithPin,
                delay: 0,
              ),
            if (_hasPin && _hasBiometrics) const SizedBox(width: 24),
            if (_hasBiometrics)
              _AnimatedAuthOptionButton(
                icon: Icons.fingerprint_rounded,
                label: 'Biometría',
                onTap: _isLoading ? null : _loginWithBio,
                delay: 100,
              ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedAuthOptionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final int delay;

  const _AnimatedAuthOptionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.delay = 0,
  });

  @override
  State<_AnimatedAuthOptionButton> createState() =>
      _AnimatedAuthOptionButtonState();
}

class _AnimatedAuthOptionButtonState extends State<_AnimatedAuthOptionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _hoverController.forward(),
        onTapUp: (_) {
          _hoverController.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () => _hoverController.reverse(),
        child: Container(
          width: 110,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.3)
                  : primaryColor.withOpacity(0.5),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.2)
                    : primaryColor.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                widget.icon,
                size: 36,
                color: isDark ? Colors.white : primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : primaryColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinDialog extends StatefulWidget {
  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark
          ? theme.colorScheme.surface.withOpacity(0.95)
          : theme.dialogTheme.backgroundColor,
      title: Text(
        'Ingresa PIN',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : theme.colorScheme.onSurface,
          fontSize: 20,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark ? primaryColor.withOpacity(0.3) : theme.dividerColor,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: TextField(
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
          color: isDark ? Colors.white : theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: '••••',
          counterText: '',
          border: InputBorder.none,
          hintStyle: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.3)
                : theme.colorScheme.onSurface.withOpacity(0.3),
            letterSpacing: 16,
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
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: isDark
                      ? Colors.white.withOpacity(0.8)
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.8)],
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context, _controller.text),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      child: const Text(
                        'Aceptar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
