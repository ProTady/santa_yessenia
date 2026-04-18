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
    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20, MediaQuery.of(context).padding.top + 20, 20, 20),
            decoration: const BoxDecoration(
              color: AppConstants.primaryGreen,
            ),
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
                const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  AppConstants.appSubtitle,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  route: '/',
                  currentRoute: currentRoute ?? '/',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text('MÓDULOS',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey,
                          letterSpacing: 1)),
                ),
                _DrawerItem(
                  icon: Icons.people_rounded,
                  label: 'Personal',
                  route: '/personal',
                  currentRoute: currentRoute ?? '/',
                ),
                _DrawerItem(
                  icon: Icons.kitchen_rounded,
                  label: 'Ingredientes',
                  route: '/ingredientes',
                  currentRoute: currentRoute ?? '/',
                ),
                _DrawerItem(
                  icon: Icons.propane_tank_rounded,
                  label: 'Suministros',
                  route: '/suministros',
                  currentRoute: currentRoute ?? '/',
                ),
                _DrawerItem(
                  icon: Icons.local_shipping_rounded,
                  label: 'Transporte',
                  route: '/transporte',
                  currentRoute: currentRoute ?? '/',
                ),
                _DrawerItem(
                  icon: Icons.payments_rounded,
                  label: 'Ingresos',
                  route: '/ingresos',
                  currentRoute: currentRoute ?? '/',
                ),
                const Divider(indent: 16, endIndent: 16),
                _DrawerItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Reportes',
                  route: '/reportes',
                  currentRoute: currentRoute ?? '/',
                ),
              ],
            ),
          ),

          // Logout
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppConstants.errorRed),
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

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
  });

  bool get _isActive => currentRoute == route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon,
          color: _isActive ? AppConstants.primaryGreen : Colors.grey.shade600,
          size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: _isActive ? AppConstants.primaryGreen : Colors.grey.shade800,
          fontWeight: _isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: _isActive,
      selectedTileColor: AppConstants.primaryGreen.withAlpha(18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: () {
        Navigator.of(context).pop();
        if (!_isActive) context.go(route);
      },
    );
  }
}
