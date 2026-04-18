import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';

class AuthState {
  final bool isAuthenticated;
  final String? error;

  const AuthState({this.isAuthenticated = false, this.error});

  AuthState copyWith({bool? isAuthenticated, String? error, bool clearError = false}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  bool verifyPin(String pin) {
    final box = Hive.box(AppConstants.settingsBox);
    final stored =
        box.get(AppConstants.pinKey, defaultValue: AppConstants.defaultPin) as String;
    if (pin == stored) {
      state = state.copyWith(isAuthenticated: true, clearError: true);
      return true;
    }
    state = state.copyWith(error: 'PIN incorrecto. Inténtalo de nuevo.');
    return false;
  }

  void clearError() => state = state.copyWith(clearError: true);

  Future<void> changePin(String newPin) async {
    final box = Hive.box(AppConstants.settingsBox);
    await box.put(AppConstants.pinKey, newPin);
  }

  void logout() => state = const AuthState();
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
