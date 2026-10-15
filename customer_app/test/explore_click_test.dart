import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:district_car_shared/models/models.dart';
import 'package:district_car_shared/services/destinations_service.dart';
import 'package:district_car_customer/features/tours/popular_destinations_screen.dart';
import 'package:district_car_customer/features/tours/destination_detail_screen.dart';
import 'package:district_car_customer/features/tours/tour_booking_screen.dart';

void main() {
  testWidgets('Complete Explore navigation: Card tap opens Detail, Plan Trip opens Booking, Back pops cleanly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final router = GoRouter(
      initialLocation: '/tours',
      routes: [
        GoRoute(
          path: '/tours',
          builder: (context, state) => const PopularDestinationsScreen(),
        ),
        GoRoute(
          path: '/destination-details',
          builder: (context, state) {
            final dest = (state.extra as PopularDestinationModel?) ??
                DestinationsService.defaultDestinations.first;
            return DestinationDetailScreen(destination: dest);
          },
        ),
        GoRoute(
          path: '/book-tour',
          builder: (context, state) {
            final dest = (state.extra as PopularDestinationModel?) ??
                DestinationsService.defaultDestinations.first;
            return TourBookingScreen(destination: dest);
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify PopularDestinationsScreen is shown
    expect(find.byType(PopularDestinationsScreen), findsOneWidget);
    expect(find.text('Tours & Travels'), findsOneWidget);

    // 2. Find Hundru Falls card and tap it
    final hundruFinder = find.text('Hundru Falls');
    expect(hundruFinder, findsWidgets);

    await tester.tap(hundruFinder.first);
    await tester.pumpAndSettle();

    // 3. Verify DestinationDetailScreen opened immediately!
    expect(find.byType(DestinationDetailScreen), findsOneWidget);
    expect(find.text('About this Place'), findsOneWidget);
    expect(find.text('Plan this trip'), findsOneWidget);

    // 4. Tap "Plan this trip" button
    await tester.tap(find.text('Plan this trip'));
    await tester.pumpAndSettle();

    // 5. Verify TourBookingScreen opened!
    expect(find.byType(TourBookingScreen), findsOneWidget);
    expect(find.text('Plan Your Tour'), findsOneWidget);

    // 6. Tap Back on TourBookingScreen
    final bookingBackFinder = find.byIcon(Icons.arrow_back_ios_new_rounded);
    expect(bookingBackFinder, findsWidgets);
    await tester.tap(bookingBackFinder.first);
    await tester.pumpAndSettle();

    // 7. Verify back to DestinationDetailScreen
    expect(find.byType(TourBookingScreen), findsNothing);
    expect(find.byType(DestinationDetailScreen), findsOneWidget);

    // 8. Tap Back on DestinationDetailScreen
    final detailBackFinder = find.byIcon(Icons.arrow_back_ios_new_rounded);
    expect(detailBackFinder, findsWidgets);
    await tester.tap(detailBackFinder.first);
    await tester.pumpAndSettle();

    // 9. Verify cleanly back to PopularDestinationsScreen
    expect(find.byType(DestinationDetailScreen), findsNothing);
    expect(find.byType(PopularDestinationsScreen), findsOneWidget);
  });
}
