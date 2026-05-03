import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:secure_vault/core/app_theme.dart';
import 'package:secure_vault/providers/theme_provider.dart';
import 'package:secure_vault/services/auth_service.dart';
import 'package:secure_vault/services/db_service.dart';
import 'package:secure_vault/ui/screens/auth_check_screen.dart';

import 'package:secure_vault/providers/security_provider.dart';
import 'package:secure_vault/services/security_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

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
    final security = ref.read(securityProvider);
    final timeout = security.autoLockTimeout.duration;

    if (state == AppLifecycleState.paused) {
      _pausedTime ??= DateTime.now();

      if (!security.isBypassingAutoLock && timeout == Duration.zero) {
        final auth = ref.read(authServiceProvider);
        auth.logout();
        auth.wasAutoLocked = true;
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      }
    } else if (state == AppLifecycleState.inactive) {
      _pausedTime ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (security.isBypassingAutoLock) {
        ref.read(securityProvider.notifier).setBypassingAutoLock(false);
        _pausedTime = null;
        return;
      }

      if (_pausedTime != null) {
        final elapsed = DateTime.now().difference(_pausedTime!);
        bool shouldLock = false;

        if (timeout != Duration.zero && timeout != null && elapsed >= timeout) {
          shouldLock = true;
        }

        if (shouldLock) {
          final auth = ref.read(authServiceProvider);
          auth.logout();
          auth.wasAutoLocked = true;
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/',
            (route) => false,
          );
        }
      }
      _pausedTime = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final colorTheme = ref.read(themeProvider.notifier).colorTheme;
    SecurityService.setSecureMode(true);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Vault',
      debugShowCheckedModeBanner: false,
      themeMode: themeState.themeMode,
      theme: AppTheme.buildLightTheme(colorTheme),
      darkTheme: AppTheme.buildDarkTheme(colorTheme),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('es', '')],
      routes: {'/': (context) => const AuthCheckScreen()},
    );
  }
}

final navigatorKey = GlobalKey<NavigatorState>();
