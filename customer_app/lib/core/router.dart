import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/profile_setup_screen.dart';
import '../features/home/home_screen.dart';
import '../features/booking/active_trip_screen.dart';
import '../features/booking/driver_selection_screen.dart';
import '../features/trips/trips_history_screen.dart';
import '../features/profile/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const CustomerHomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/choose-driver',
        builder: (context, state) => const DriverSelectionScreen(),
      ),
      GoRoute(
        path: '/active-trip/:bookingId',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId'] ?? '';
          return ActiveTripScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/trips',
        builder: (context, state) => const TripsHistoryScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
