import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    return Container(
      width: 260,
      color: AppTheme.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('H',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('HomeServices',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 12),
          // Nav Items
          _NavItem(icon: Icons.dashboard_outlined, label: 'Dashboard', path: '/dashboard', currentPath: location),
          _NavItem(icon: Icons.person_add_outlined, label: 'Worker Approvals', path: '/workers', currentPath: location),
          _NavItem(icon: Icons.credit_card_outlined, label: 'Payments', path: '/payments', currentPath: location),
          _NavItem(icon: Icons.refresh_outlined, label: 'Refunds', path: '/refunds', currentPath: location),
          _NavItem(icon: Icons.gavel_outlined, label: 'Disputes', path: '/disputes', currentPath: location),
          _NavItem(icon: Icons.people_outline, label: 'Users Management', path: '/users', currentPath: location),
          _NavItem(icon: Icons.trending_up_outlined, label: 'Revenue Overview', path: '/revenue', currentPath: location),
          _NavItem(icon: Icons.settings_outlined, label: 'Settings', path: '/settings', currentPath: location),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final String currentPath;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentPath == path;

    return GestureDetector(
      onTap: () => context.go(path),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: isActive ? Colors.white : AppTheme.textSecondary),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive ? Colors.white : AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}