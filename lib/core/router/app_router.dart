import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/ingredientes/presentation/ingredientes_screen.dart';
import '../../features/ingresos/presentation/ingresos_screen.dart';
import '../../features/personal/presentation/personal_screen.dart';
import '../../features/suministros/presentation/suministros_screen.dart';
import '../../features/asistencias/presentation/asistencias_screen.dart';
import '../../features/asistencias/presentation/liquidacion_screen.dart';
import '../../features/comensales/presentation/comensales_screen.dart';
import '../../features/directorio/presentation/directorio_screen.dart';
import '../../features/transporte/presentation/transporte_screen.dart';
import '../../features/usuarios/presentation/usuarios_screen.dart';
import '../../features/ventas/presentation/ventas_screen.dart';
import '../../shared/widgets/placeholder_screen.dart';

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
      final auth = ref.read(authProvider);
      final isAuth = auth.isAuthenticated;
      final location = state.matchedLocation;
      final onLogin = location == '/login';

      if (!isAuth && !onLogin) return '/login';
      if (isAuth && onLogin) return '/';

      // Rutas que solo el admin puede visitar
      const adminOnlyRoutes = ['/usuarios'];
      if (isAuth && adminOnlyRoutes.contains(location) && !auth.esAdmin) {
        return '/';
      }

      // Rutas con permiso por módulo (cualquier ruta fuera de las especiales)
      const publicRoutes = ['/', '/login', '/liquidacion', '/reportes', '/usuarios'];
      if (isAuth && !publicRoutes.contains(location) && !auth.esAdmin) {
        if (!auth.tieneAcceso(location)) return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login',      name: 'login',        builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/',           name: 'dashboard',    builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/personal',   name: 'personal',     builder: (context, state) => const PersonalScreen()),
      GoRoute(path: '/ingredientes',name: 'ingredientes', builder: (context, state) => const IngredientesScreen()),
      GoRoute(path: '/suministros', name: 'suministros', builder: (context, state) => const SuministrosScreen()),
      GoRoute(path: '/transporte',  name: 'transporte',  builder: (context, state) => const TransporteScreen()),
      GoRoute(path: '/ingresos',    name: 'ingresos',    builder: (context, state) => const IngresosScreen()),
      GoRoute(path: '/comensales',  name: 'comensales',  builder: (context, state) => const ComensalesScreen()),
      GoRoute(path: '/directorio',  name: 'directorio',  builder: (context, state) => const DirectorioScreen()),
      GoRoute(path: '/asistencias', name: 'asistencias', builder: (context, state) => const AsistenciasScreen()),
      GoRoute(path: '/liquidacion', name: 'liquidacion', builder: (context, state) => const LiquidacionScreen()),
      GoRoute(path: '/usuarios',    name: 'usuarios',    builder: (context, state) => const UsuariosScreen()),
      GoRoute(path: '/ventas',      name: 'ventas',      builder: (context, state) => const VentasScreen()),
      GoRoute(path: '/reportes',    name: 'reportes',    builder: (context, state) => const PlaceholderScreen(title: 'Reportes')),
    ],
  );
});
