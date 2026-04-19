import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/usuarios/models/usuario_model.dart';

class AuthState {
  final bool isAuthenticated;
  final String? error;
  final UsuarioApp? usuarioActual;

  const AuthState({
    this.isAuthenticated = false,
    this.error,
    this.usuarioActual,
  });

  bool get esAdmin =>
      usuarioActual == null || usuarioActual!.esAdmin;

  bool tieneAcceso(String ruta) =>
      esAdmin || (usuarioActual?.tieneAcceso(ruta) ?? false);

  AuthState copyWith({
    bool? isAuthenticated,
    String? error,
    UsuarioApp? usuarioActual,
    bool clearError = false,
    bool clearUsuario = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: clearError ? null : (error ?? this.error),
      usuarioActual:
          clearUsuario ? null : (usuarioActual ?? this.usuarioActual),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  /// Login con un usuario específico y su PIN
  bool login(UsuarioApp usuario, String pin) {
    if (pin == usuario.pin) {
      state = AuthState(
        isAuthenticated: true,
        usuarioActual: usuario,
      );
      return true;
    }
    state = state.copyWith(error: 'PIN incorrecto. Inténtalo de nuevo.');
    return false;
  }

  void clearError() => state = state.copyWith(clearError: true);

  void logout() => state = const AuthState();
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
