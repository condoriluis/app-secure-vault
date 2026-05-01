import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:secure_vault/core/app_theme.dart';
import 'package:secure_vault/providers/theme_provider.dart';
import 'package:secure_vault/services/auth_service.dart';
import 'package:secure_vault/services/db_service.dart';
import 'package:secure_vault/ui/screens/auth_check_screen.dart';

import 'package:secure_vault/providers/security_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final dbService = DbService();
  await dbService.init();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  DateTime? _pausedTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedTime != null) {
        final timeout = ref.read(securityProvider).autoLockTimeout.duration;

        // Si el timeout es nulo, nunca se bloquea por tiempo
        if (timeout != null) {
          final duration = DateTime.now().difference(_pausedTime!);
          if (duration >= timeout) {
            ref.read(authServiceProvider).logout();
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/',
              (route) => false,
            );
          }
        }
      }
      _pausedTime = null; // Resetear el tiempo de pausa al volver
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final colorTheme = ref.read(themeProvider.notifier).colorTheme;

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Vault',
      debugShowCheckedModeBanner: false,
      themeMode: themeState.themeMode,
      theme: AppTheme.buildLightTheme(colorTheme),
      darkTheme: AppTheme.buildDarkTheme(colorTheme),
      routes: {'/': (context) => const AuthCheckScreen()},
    );
  }
}

final navigatorKey = GlobalKey<NavigatorState>();
