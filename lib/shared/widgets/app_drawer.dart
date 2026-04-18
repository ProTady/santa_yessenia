import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../features/auth/providers/auth_provider.dart';

class AppDrawer extends ConsumerWidget {
  final String? currentRoute;
  const AppDrawer({super.key, this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = currentRoute ?? '/';

    return Drawer(
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 20, 20, 20),
            decoration: const BoxDecoration(color: AppConstants.primaryGreen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.restaurant,
                      color: AppConstants.primaryGreen, size: 28),
                ),
                const SizedBox(height: 12),
                const Text(AppConstants.appName,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const Text(AppConstants.appSubtitle,
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),

          // ── Navegación ────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Dashboard
                _DrawerItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  route: '/',
                  currentRoute: route,
                ),

                const SizedBox(height: 4),

                // ── GASTOS ────────────────────────────────────────
                _SectionHeader(
                  label: 'GASTOS',
                  color: AppConstants.expenseColor,
                  icon: Icons.trending_down_rounded,
                ),
                _DrawerItem(
                  icon: Icons.people_rounded,
                  label: 'Personal',
                  route: '/personal',
                  currentRoute: route,
                  activeColor: AppConstants.primaryGreen,
                ),
                _DrawerItem(
                  icon: Icons.kitchen_rounded,
                  label: 'Ingredientes',
                  route: '/ingredientes',
                  currentRoute: route,
                  activeColor: const Color(0xFF1565C0),
                ),
                _DrawerItem(
                  icon: Icons.propane_tank_rounded,
                  label: 'Suministros',
                  route: '/suministros',
                  currentRoute: route,
                  activeColor: const Color(0xFF6A1B9A),
                ),
                _DrawerItem(
                  icon: Icons.local_shipping_rounded,
                  label: 'Transporte',
                  route: '/transporte',
                  currentRoute: route,
                  activeColor: const Color(0xFFE65100),
                ),

                const SizedBox(height: 4),

                // ── INGRESOS ──────────────────────────────────────
                _SectionHeader(
                  label: 'INGRESOS',
                  color: AppConstants.incomeColor,
                  icon: Icons.trending_up_rounded,
                ),
                _DrawerItem(
                  icon: Icons.payments_rounded,
                  label: 'Ingresos del Fundo',
                  route: '/ingresos',
                  currentRoute: route,
                  activeColor: const Color(0xFF00695C),
                ),

                const SizedBox(height: 4),

                // ── OPERACIONES ───────────────────────────────────
                _SectionHeader(
                  label: 'OPERACIONES',
                  color: Color(0xFF00838F),
                  icon: Icons.restaurant_menu_rounded,
                ),
                _DrawerItem(
                  icon: Icons.groups_rounded,
                  label: 'Comensales',
                  route: '/comensales',
                  currentRoute: route,
                  activeColor: const Color(0xFF00838F),
                ),

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

          // ── Cerrar sesión ─────────────────────────────────────────
          const Divider(height: 1),
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
          const SizedBox(height: 8),
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
