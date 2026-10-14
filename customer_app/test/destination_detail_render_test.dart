import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:district_car_shared/models/models.dart';
import 'package:district_car_customer/features/tours/destination_detail_screen.dart';

void main() {
  testWidgets('DestinationDetailScreen renders without errors', (WidgetTester tester) async {
    final dest = PopularDestinationModel(
      id: 'hundru_falls',
      name: 'Hundru Falls',
      hindiName: 'हुंडरू जलप्रपात',
      category: 'waterfall',
      district: 'Ranchi',
      locationAddress: 'Ormanjhi, Ranchi',
      latitude: 23.4503,
      longitude: 85.6567,
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Hundru_Falls_Ranchi.jpg/1280px-Hundru_Falls_Ranchi.jpg',
      galleryImages: [
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Hundru_Falls_Ranchi.jpg/1280px-Hundru_Falls_Ranchi.jpg',
      ],
      description: 'Hundru Falls is a scenic waterfall',
      highlights: ['98m drop', 'Rock formations'],
      safetyTips: ['Slippery rocks'],
      entryFee: '₹20',
      timeNeeded: '3 Hours',
      stepsOrParking: 'Parking available',
      bestTimeToVisit: 'July to Feb',
      startingFare: 1199.0,
      approxDistanceKm: 44.0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DestinationDetailScreen(destination: dest),
      ),
    );

    await tester.pump();

    expect(find.text('Hundru Falls'), findsOneWidget);
    expect(find.text('Plan this trip'), findsOneWidget);

    // Test scrolling
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('Tour Highlights'), findsOneWidget);
  });

  testWidgets('Tapping back button pops back to previous screen', (WidgetTester tester) async {
    final dest = PopularDestinationModel(
      id: 'hundru_falls',
      name: 'Hundru Falls',
      hindiName: 'हुंडरू जलप्रपात',
      category: 'waterfall',
      district: 'Ranchi',
      locationAddress: 'Ormanjhi, Ranchi',
      latitude: 23.4503,
      longitude: 85.6567,
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Hundru_Falls_Ranchi.jpg/1280px-Hundru_Falls_Ranchi.jpg',
      galleryImages: [],
      description: 'Hundru Falls is a scenic waterfall',
      highlights: ['98m drop'],
      safetyTips: ['Slippery rocks'],
      entryFee: '₹20',
      timeNeeded: '3 Hours',
      stepsOrParking: 'Parking available',
      bestTimeToVisit: 'July to Feb',
      startingFare: 1199.0,
      approxDistanceKm: 44.0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DestinationDetailScreen(destination: dest),
                  ),
                );
              },
              child: const Text('Go to Details'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Go to Details'));
    await tester.pumpAndSettle();
    expect(find.text('Hundru Falls'), findsOneWidget);

    // Tap back button
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Go to Details'), findsOneWidget);
  });

  testWidgets('GoRouter push and pop with DestinationDetailScreen', (WidgetTester tester) async {
    final dest = PopularDestinationModel(
      id: 'hundru_falls',
      name: 'Hundru Falls',
      hindiName: 'हुंडरू जलप्रपात',
      category: 'waterfall',
      district: 'Ranchi',
      locationAddress: 'Ormanjhi, Ranchi',
      latitude: 23.4503,
      longitude: 85.6567,
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Hundru_Falls_Ranchi.jpg/1280px-Hundru_Falls_Ranchi.jpg',
      galleryImages: [],
      description: 'Hundru Falls is a scenic waterfall',
      highlights: ['98m drop'],
      safetyTips: ['Slippery rocks'],
      entryFee: '₹20',
      timeNeeded: '3 Hours',
      stepsOrParking: 'Parking available',
      bestTimeToVisit: 'July to Feb',
      startingFare: 1199.0,
      approxDistanceKm: 44.0,
    );

    final router = GoRouter(
      initialLocation: '/tours',
      routes: [
        GoRoute(
          path: '/tours',
          builder: (context, state) => Scaffold(
            body: ElevatedButton(
              onPressed: () => context.push('/destination-details', extra: dest),
              child: const Text('Go to Details'),
            ),
          ),
        ),
        GoRoute(
          path: '/destination-details',
          builder: (context, state) => DestinationDetailScreen(destination: dest),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Go to Details'));
    await tester.pumpAndSettle();
    expect(find.text('Hundru Falls'), findsOneWidget);

    // Tap back button
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Go to Details'), findsOneWidget);
  });
}
