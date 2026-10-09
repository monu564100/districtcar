import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/profile_setup_screen.dart';
import '../features/home/home_screen.dart';
import '../features/booking/active_trip_screen.dart';
import '../features/booking/driver_selection_screen.dart';
import '../features/trips/trips_history_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/tours/popular_destinations_screen.dart';
import '../features/tours/destination_detail_screen.dart';
import '../features/tours/tour_booking_screen.dart';
import 'package:district_car_shared/models/models.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const CustomerHomeScreen(),
      ),
      GoRoute(
        path: '/tours',
        builder: (context, state) => const PopularDestinationsScreen(),
      ),
      GoRoute(
        path: '/destination-details',
        builder: (context, state) {
          final dest = state.extra as PopularDestinationModel;
          return DestinationDetailScreen(destination: dest);
        },
      ),
      GoRoute(
        path: '/book-tour',
        builder: (context, state) {
          final dest = state.extra as PopularDestinationModel;
          return TourBookingScreen(destination: dest);
        },
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
