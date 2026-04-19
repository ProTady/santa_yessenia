import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/supabase/sync_manager.dart';
import '../../core/wifi_sync/wifi_sync_provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/usuarios/models/usuario_model.dart';
import '../../features/wifi_sync/presentation/wifi_client_screen.dart';
import '../../features/wifi_sync/presentation/wifi_server_screen.dart';

class AppDrawer extends ConsumerWidget {
  final String? currentRoute;
  const AppDrawer({super.key, this.currentRoute});

  Future<void> _sincronizar(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Sincronizando...'),
          ],
        ),
      ),
    );

    final resultados = await SyncManager.sincronizarTodo();

    if (!context.mounted) return;
    Navigator.of(context).pop();

    final errores = resultados.entries
        .where((e) => e.value != null)
        .map((e) => '• ${e.key}: ${e.value}')
        .toList();

    final ok = resultados.entries.where((e) => e.value == null).length;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(
              errores.isEmpty ? Icons.check_circle_rounded : Icons.warning_rounded,
              color: errores.isEmpty ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            const Text('Sincronización'),
          ],
        ),
        content: errores.isEmpty
            ? Text('$ok tablas sincronizadas correctamente.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$ok tablas OK. Errores:'),
                  const SizedBox(height: 8),
                  ...errores.map((e) => Text(e,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.red))),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = currentRoute ?? '/';
    final auth = ref.watch(authProvider);
    final esAdmin = auth.esAdmin;
    final usuario = auth.usuarioActual;

    bool puede(String ruta) => auth.tieneAcceso(ruta);

    return Drawer(
      child: Column(
        children: [
          // ── Header con info del usuario ───────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 20, 20, 20),
            decoration: const BoxDecoration(color: AppConstants.primaryGreen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: usuario != null
                          ? Center(
                              child: Text(
                                usuario.nombre.isNotEmpty
                                    ? usuario.nombre[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.primaryGreen),
                              ),
                            )
                          : const Icon(Icons.restaurant,
                              color: AppConstants.primaryGreen, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            usuario?.nombre ?? AppConstants.appName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            usuario?.rol.label ?? AppConstants.appSubtitle,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Navegación ────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Dashboard — siempre visible
                _DrawerItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  route: '/',
                  currentRoute: route,
                ),

                const SizedBox(height: 4),

                // ── GASTOS ────────────────────────────────────────
                if (esAdmin ||
                    puede('/personal') ||
                    puede('/ingredientes') ||
                    puede('/suministros') ||
                    puede('/transporte')) ...[
                  _SectionHeader(
                    label: 'GASTOS',
                    color: AppConstants.expenseColor,
                    icon: Icons.trending_down_rounded,
                  ),
                  if (esAdmin || puede('/personal'))
                    _DrawerItem(
                      icon: Icons.people_rounded,
                      label: 'Personal',
                      route: '/personal',
                      currentRoute: route,
                      activeColor: AppConstants.primaryGreen,
                    ),
                  if (esAdmin || puede('/ingredientes'))
                    _DrawerItem(
                      icon: Icons.kitchen_rounded,
                      label: 'Ingredientes',
                      route: '/ingredientes',
                      currentRoute: route,
                      activeColor: const Color(0xFF1565C0),
                    ),
                  if (esAdmin || puede('/suministros'))
                    _DrawerItem(
                      icon: Icons.propane_tank_rounded,
                      label: 'Suministros',
                      route: '/suministros',
                      currentRoute: route,
                      activeColor: const Color(0xFF6A1B9A),
                    ),
                  if (esAdmin || puede('/transporte'))
                    _DrawerItem(
                      icon: Icons.local_shipping_rounded,
                      label: 'Transporte',
                      route: '/transporte',
                      currentRoute: route,
                      activeColor: const Color(0xFFE65100),
                    ),
                  const SizedBox(height: 4),
                ],

                // ── INGRESOS ──────────────────────────────────────
                if (esAdmin || puede('/ingresos') || puede('/ventas')) ...[
                  _SectionHeader(
                    label: 'INGRESOS',
                    color: AppConstants.incomeColor,
                    icon: Icons.trending_up_rounded,
                  ),
                  if (esAdmin || puede('/ingresos'))
                    _DrawerItem(
                      icon: Icons.payments_rounded,
                      label: 'Ingresos del Fundo',
                      route: '/ingresos',
                      currentRoute: route,
                      activeColor: const Color(0xFF00695C),
                    ),
                  if (esAdmin || puede('/ventas'))
                    _DrawerItem(
                      icon: Icons.storefront_rounded,
                      label: 'Ventas',
                      route: '/ventas',
                      currentRoute: route,
                      activeColor: const Color(0xFF6A1B9A),
                    ),
                  const SizedBox(height: 4),
                ],

                // ── OPERACIONES ───────────────────────────────────
                if (esAdmin || puede('/comensales') || puede('/directorio')) ...[
                  _SectionHeader(
                    label: 'OPERACIONES',
                    color: Color(0xFF00838F),
                    icon: Icons.restaurant_menu_rounded,
                  ),
                  if (esAdmin || puede('/comensales'))
                    _DrawerItem(
                      icon: Icons.groups_rounded,
                      label: 'Comensales',
                      route: '/comensales',
                      currentRoute: route,
                      activeColor: const Color(0xFF00838F),
                    ),
                  if (esAdmin || puede('/directorio'))
                    _DrawerItem(
                      icon: Icons.contact_page_rounded,
                      label: 'Directorio',
                      route: '/directorio',
                      currentRoute: route,
                      activeColor: const Color(0xFF00838F),
                    ),
                  const SizedBox(height: 4),
                ],

                // ── RRHH ──────────────────────────────────────────
                if (esAdmin || puede('/asistencias')) ...[
                  _SectionHeader(
                    label: 'RRHH',
                    color: AppConstants.asistenciaColor,
                    icon: Icons.badge_rounded,
                  ),
                  _DrawerItem(
                    icon: Icons.fact_check_rounded,
                    label: 'Asistencias',
                    route: '/asistencias',
                    currentRoute: route,
                    activeColor: AppConstants.asistenciaColor,
                  ),
                  const SizedBox(height: 4),
                ],

                // ── ADMINISTRACIÓN (solo admin) ───────────────────
                if (esAdmin) ...[
                  const Divider(indent: 16, endIndent: 16),
                  _SectionHeader(
                    label: 'ADMINISTRACIÓN',
                    color: AppConstants.primaryGreen,
                    icon: Icons.admin_panel_settings_rounded,
                  ),
                  _DrawerItem(
                    icon: Icons.manage_accounts_rounded,
                    label: 'Usuarios',
                    route: '/usuarios',
                    currentRoute: route,
                    activeColor: AppConstants.primaryGreen,
                  ),
                ],

                const SizedBox(height: 4),
                const Divider(indent: 16, endIndent: 16),

                // ── REPORTES ──────────────────────────────────────
                _DrawerItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Reportes',
                  route: '/reportes',
                  currentRoute: route,
                ),
              ],
            ),
          ),

          // ── Acciones bottom ───────────────────────────────────────
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── WiFi Sync Admin: servidor ──────────────────────
                if (esAdmin) ...[
                  _WifiServerTile(),
                  ListTile(
                    leading: const Icon(Icons.cloud_sync_rounded,
                        color: Color(0xFF1565C0)),
                    title: const Text('Sincronizar con Supabase',
                        style: TextStyle(color: Color(0xFF1565C0))),
                    onTap: () async {
                      Navigator.of(context).pop();
                      _sincronizar(context);
                    },
                  ),
                ],
                // ── WiFi Sync Usuario: cliente ─────────────────────
                if (!esAdmin)
                  ListTile(
                    leading: const Icon(Icons.wifi_rounded,
                        color: Color(0xFF1565C0)),
                    title: const Text('Sincronizar por WiFi',
                        style: TextStyle(color: Color(0xFF1565C0))),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const WifiClientScreen()));
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded,
                      color: AppConstants.errorRed),
                  title: const Text('Cerrar sesión',
                      style: TextStyle(color: AppConstants.errorRed)),
                  onTap: () {
                    Navigator.of(context).pop();
                    ref.read(authProvider.notifier).logout();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _SectionHeader({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Drawer item ────────────────────────────────────────────────────────────────

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;
  final Color? activeColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
    this.activeColor,
  });

  bool get _isActive => currentRoute == route;
  Color get _color => activeColor ?? AppConstants.primaryGreen;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon,
          color: _isActive ? _color : Colors.grey.shade600, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: _isActive ? _color : Colors.grey.shade800,
          fontWeight: _isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: _isActive,
      selectedTileColor: _color.withAlpha(18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: () {
        Navigator.of(context).pop();
        if (!_isActive) context.go(route);
      },
    );
  }
}

// ── Tile servidor WiFi (solo admin) ───────────────────────────────────────────

class _WifiServerTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverState = ref.watch(wifiServerProvider);
    final isRunning = serverState.isRunning;
    final color = isRunning ? Colors.green.shade700 : const Color(0xFF1565C0);

    return ListTile(
      leading: Icon(
        isRunning ? Icons.wifi_rounded : Icons.wifi_off_rounded,
        color: color,
      ),
      title: Text(
        isRunning
            ? 'Servidor WiFi activo (${serverState.ip ?? '...'})'
            : 'Servidor WiFi',
        style: TextStyle(color: color, fontSize: 14),
      ),
      trailing: Switch.adaptive(
        value: isRunning,
        activeColor: Colors.green.shade700,
        onChanged: (_) =>
            ref.read(wifiServerProvider.notifier).toggle(),
      ),
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const WifiServerScreen()));
      },
    );
  }
}
