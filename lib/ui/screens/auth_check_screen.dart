import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secure_vault/services/auth_service.dart';
import 'package:secure_vault/ui/screens/animated_login_screen.dart';
import 'package:secure_vault/ui/screens/onboarding_screen.dart';

class AuthCheckScreen extends ConsumerStatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  ConsumerState<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends ConsumerState<AuthCheckScreen> {
  bool? _hasAccount;

  @override
  void initState() {
    super.initState();
    _checkAccount();
  }

  Future<void> _checkAccount() async {
    final authService = ref.read(authServiceProvider);
    final hasAccount = await authService.hasAccount();
    setState(() {
      _hasAccount = hasAccount;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasAccount == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_hasAccount!) {
      return const AnimatedLoginScreen();
    } else {
      return const OnboardingScreen();
    }
  }
}
