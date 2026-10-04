import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/admin_login_screen.dart';
import '../features/dashboard/admin_dashboard_screen.dart';
import '../features/drivers/driver_verification_screen.dart';
import '../features/fares/fare_management_screen.dart';

final adminRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      GoRoute(
        path: '/admin-login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/driver-verification',
        builder: (context, state) => const DriverVerificationScreen(),
      ),
      GoRoute(
        path: '/fares',
        builder: (context, state) => const FareManagementScreen(),
      ),
    ],
  );
});
