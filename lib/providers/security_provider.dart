import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AutoLockTimeout {
  immediate,
  tenSeconds,
  oneMinute,
  fiveMinutes,
  tenMinutes,
}

extension AutoLockTimeoutExtension on AutoLockTimeout {
  String get label {
    switch (this) {
      case AutoLockTimeout.immediate:
        return 'Inmediatamente';
      case AutoLockTimeout.tenSeconds:
        return 'despues de 10 segundos';
      case AutoLockTimeout.oneMinute:
        return 'despues de 1 minuto';
      case AutoLockTimeout.fiveMinutes:
        return 'despues de 5 minutos';
      case AutoLockTimeout.tenMinutes:
        return 'despues de 10 minutos';
    }
  }

  Duration? get duration {
    switch (this) {
      case AutoLockTimeout.immediate:
        return Duration.zero;
      case AutoLockTimeout.tenSeconds:
        return const Duration(seconds: 10);
      case AutoLockTimeout.oneMinute:
        return const Duration(minutes: 1);
      case AutoLockTimeout.fiveMinutes:
        return const Duration(minutes: 5);
      case AutoLockTimeout.tenMinutes:
        return const Duration(minutes: 10);
    }
  }
}

class SecurityState {
  final AutoLockTimeout autoLockTimeout;
  final bool isBypassingAutoLock;

  SecurityState({
    required this.autoLockTimeout,
    this.isBypassingAutoLock = false,
  });

  SecurityState copyWith({
    AutoLockTimeout? autoLockTimeout,
    bool? isBypassingAutoLock,
  }) {
    return SecurityState(
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      isBypassingAutoLock: isBypassingAutoLock ?? this.isBypassingAutoLock,
    );
  }
}

class SecurityNotifier extends StateNotifier<SecurityState> {
  SecurityNotifier()
    : super(SecurityState(autoLockTimeout: AutoLockTimeout.immediate)) {
    _loadSettings();
  }

  static const _autoLockKey = 'auto_lock_timeout';

  void setAutoLockTimeout(AutoLockTimeout timeout) {
    state = state.copyWith(autoLockTimeout: timeout);
    _saveSettings();
  }

  void setBypassingAutoLock(bool value) {
    state = state.copyWith(isBypassingAutoLock: value);
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_autoLockKey, state.autoLockTimeout.index);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_autoLockKey);
    
    AutoLockTimeout timeout = AutoLockTimeout.immediate;
    if (index != null && index >= 0 && index < AutoLockTimeout.values.length) {
      timeout = AutoLockTimeout.values[index];
    }
    
    state = SecurityState(
      autoLockTimeout: timeout,
    );
  }
}

final securityProvider = StateNotifierProvider<SecurityNotifier, SecurityState>(
  (ref) {
    return SecurityNotifier();
  },
);
