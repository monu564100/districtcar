import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:district_car_shared/models/models.dart';
import 'package:district_car_customer/features/tours/tour_booking_screen.dart';

void main() {
  testWidgets('TourBookingScreen renders without errors', (WidgetTester tester) async {
    final dest = PopularDestinationModel(
      id: 'hundru_falls',
      name: 'Hundru Falls',
      hindiName: 'हुंडरू जलप्रपात',
      category: 'waterfall',
      district: 'Ranchi',
      locationAddress: 'Ormanjhi, Ranchi',
      latitude: 23.4503,
      longitude: 85.6567,
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/b/be/Hundru_Falls%2C_Jharkhand%2C_India_4.jpg',
      description: 'Hundru Falls is a scenic waterfall',
      startingFare: 1199.0,
      approxDistanceKm: 44.0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TourBookingScreen(destination: dest),
      ),
    );

    await tester.pump();

    expect(find.text('Plan Your Tour'), findsOneWidget);
    expect(find.text('Select Vehicle'), findsOneWidget);
  });
}
