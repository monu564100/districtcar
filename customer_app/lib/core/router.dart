import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/profile_setup_screen.dart';
import '../features/auth/auth_service.dart';
import '../features/home/home_screen.dart';
import '../features/booking/active_trip_screen.dart';
import '../features/booking/driver_selection_screen.dart';
import '../features/trips/trips_history_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/about_us_screen.dart';
import '../features/profile/legal_policy_screen.dart';
import '../features/profile/report_driver_screen.dart';
import '../features/profile/delete_account_screen.dart';
import '../features/tours/popular_destinations_screen.dart';
import '../features/tours/destination_detail_screen.dart';
import '../features/tours/tour_booking_screen.dart';
import 'package:district_car_shared/models/models.dart';
import 'package:district_car_shared/services/destinations_service.dart';

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
          final id = state.uri.queryParameters['id'];
          final dest = (state.extra as PopularDestinationModel?) ??
              (id != null
                  ? DestinationsService.defaultDestinations.firstWhere(
                      (d) => d.id == id,
                      orElse: () => DestinationsService.defaultDestinations.first,
                    )
                  : DestinationsService.defaultDestinations.first);
          return DestinationDetailScreen(destination: dest);
        },
      ),
      GoRoute(
        path: '/book-tour',
        builder: (context, state) {
          final id = state.uri.queryParameters['id'];
          final dest = (state.extra as PopularDestinationModel?) ??
              (id != null
                  ? DestinationsService.defaultDestinations.firstWhere(
                      (d) => d.id == id,
                      orElse: () => DestinationsService.defaultDestinations.first,
                    )
                  : DestinationsService.defaultDestinations.first);
          return TourBookingScreen(destination: dest);
        },
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          redirectPath: (state.extra as String?) ?? state.uri.queryParameters['redirect'],
        ),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => ProfileSetupScreen(
          redirectPath: (state.extra as String?) ?? state.uri.queryParameters['redirect'],
        ),
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
        builder: (context, state) {
          final user = ref.watch(authServiceProvider).currentUser;
          if (user == null) {
            return const LoginScreen(redirectPath: '/trips');
          }
          return const TripsHistoryScreen();
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) {
          final user = ref.watch(authServiceProvider).currentUser;
          if (user == null) {
            return const LoginScreen(redirectPath: '/profile');
          }
          return const ProfileScreen();
        },
      ),
      GoRoute(
        path: '/about-us',
        builder: (context, state) => const AboutUsScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const LegalPolicyScreen(initialTabIndex: 0),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const LegalPolicyScreen(initialTabIndex: 1),
      ),
      GoRoute(
        path: '/report-driver',
        builder: (context, state) {
          final booking = state.extra as BookingModel?;
          return ReportDriverScreen(initialBooking: booking);
        },
      ),
      GoRoute(
        path: '/delete-account',
        builder: (context, state) => const DeleteAccountScreen(),
      ),
    ],
  );
});
