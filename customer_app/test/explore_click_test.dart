import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:district_car_shared/models/models.dart';
import 'package:district_car_shared/services/destinations_service.dart';
import 'package:district_car_customer/features/tours/popular_destinations_screen.dart';
import 'package:district_car_customer/features/tours/destination_detail_screen.dart';

void main() {
  testWidgets('Clicking a destination in PopularDestinationsScreen navigates to DestinationDetailScreen', (WidgetTester tester) async {
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

    // Verify PopularDestinationsScreen is shown
    expect(find.byType(PopularDestinationsScreen), findsOneWidget);
    expect(find.text('Tours & Travels'), findsOneWidget);

    // Find Hundru Falls text
    final hundruFinder = find.text('Hundru Falls');
    expect(hundruFinder, findsWidgets);

    // Tap on the first Hundru Falls card
    await tester.tap(hundruFinder.first);
    await tester.pumpAndSettle();

    // Verify DestinationDetailScreen is opened!
    expect(find.byType(DestinationDetailScreen), findsOneWidget);
  });
}
