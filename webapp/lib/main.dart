import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/layout/admin_layout.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/worker_approvals/worker_approvals_screen.dart';
import 'screens/payments/payments_screen.dart';
import 'screens/refunds/refunds_screen.dart';
import 'screens/disputes/disputes_screen.dart';
import 'screens/users/users_screen.dart';
import 'screens/revenue/revenue_screen.dart';
import 'screens/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SkillFoxApp());
}

final _router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isOnLogin = state.uri.toString() == '/login';
    if (isLoggedIn && isOnLogin) return '/dashboard';
    if (!isLoggedIn && !isOnLogin) return '/login';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (c, s) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => AdminLayout(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (c, s) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/workers',
          builder: (c, s) => const WorkerApprovalsScreen(),
        ),
        GoRoute(
          path: '/payments',
          builder: (c, s) => const PaymentsScreen(),
        ),
        GoRoute(
          path: '/refunds',
          builder: (c, s) => const RefundsScreen(),
        ),
        GoRoute(
          path: '/disputes',
          builder: (c, s) => const DisputesScreen(),
        ),
        GoRoute(
          path: '/users',
          builder: (c, s) => const UsersScreen(),
        ),
        GoRoute(
          path: '/revenue',
          builder: (c, s) => const RevenueScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (c, s) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);

class SkillFoxApp extends StatelessWidget {
  const SkillFoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SkillFox Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: _router,
    );
  }
}