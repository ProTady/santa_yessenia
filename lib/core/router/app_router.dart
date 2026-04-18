import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/ingredientes/presentation/ingredientes_screen.dart';
import '../../features/personal/presentation/personal_screen.dart';
import '../../features/suministros/presentation/suministros_screen.dart';
import '../../shared/widgets/placeholder_screen.dart';

// Bridges Riverpod auth state changes to GoRouter's refreshListenable
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (prev, next) => notifyListeners());
  }
  final Ref _ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isAuth = ref.read(authProvider).isAuthenticated;
      final onLogin = state.matchedLocation == '/login';
      if (!isAuth && !onLogin) return '/login';
      if (isAuth && onLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/personal',
        name: 'personal',
        builder: (context, state) => const PersonalScreen(),
      ),
      GoRoute(
        path: '/ingredientes',
        name: 'ingredientes',
        builder: (context, state) => const IngredientesScreen(),
      ),
      GoRoute(
        path: '/suministros',
        name: 'suministros',
        builder: (context, state) => const SuministrosScreen(),
      ),
      GoRoute(
        path: '/transporte',
        name: 'transporte',
        builder: (context, state) => const PlaceholderScreen(title: 'Transporte'),
      ),
      GoRoute(
        path: '/ingresos',
        name: 'ingresos',
        builder: (context, state) => const PlaceholderScreen(title: 'Ingresos'),
      ),
      GoRoute(
        path: '/reportes',
        name: 'reportes',
        builder: (context, state) => const PlaceholderScreen(title: 'Reportes'),
      ),
    ],
  );
});
