import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/driver_login_screen.dart';
import '../features/auth/driver_onboarding_screen.dart';
import '../features/home/driver_home_screen.dart';
import '../features/requests/incoming_request_dialog.dart';
import '../features/trip/driver_active_trip_screen.dart';
import '../features/earnings/driver_earnings_screen.dart';
import '../features/profile/driver_profile_screen.dart';

final driverRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/driver-home',
    routes: [
      GoRoute(
        path: '/driver-home',
        builder: (context, state) => const DriverHomeScreen(),
      ),
      GoRoute(
        path: '/driver-login',
        builder: (context, state) => const DriverLoginScreen(),
      ),
      GoRoute(
        path: '/driver-onboarding',
        builder: (context, state) => const DriverOnboardingScreen(),
      ),
      GoRoute(
        path: '/driver-trip/:bookingId',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId'] ?? '';
          return DriverActiveTripScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/driver-earnings',
        builder: (context, state) => const DriverEarningsScreen(),
      ),
      GoRoute(
        path: '/driver-profile',
        builder: (context, state) => const DriverProfileScreen(),
      ),
    ],
  );
});
