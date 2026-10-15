import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:district_car_shared/models/models.dart';
import 'package:district_car_customer/features/booking/waiting/booking_waiting_view.dart';
import 'package:district_car_customer/features/booking/waiting/cancel_sheet.dart';
import 'package:district_car_customer/features/booking/waiting/driver_found_card.dart';
import 'package:district_car_customer/features/booking/waiting/no_driver_state.dart';
import 'package:district_car_customer/features/booking/waiting/searching_hero.dart';
import 'package:district_car_customer/features/booking/waiting/status_block.dart';
import 'package:district_car_customer/features/booking/waiting/trip_summary_card.dart';
import 'package:district_car_customer/features/booking/waiting/support_strip.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testBooking = BookingModel(
    id: 'test_book_671633',
    readableId: 'DC-671633',
    customerId: 'usr_jh_01',
    vehicleCategoryId: 'prime_sedan',
    status: 'searching_driver',
    pickup: LocationModel(
      address: 'Khunti Main Road, Khunti, Jharkhand',
      latitude: 23.0734,
      longitude: 85.2789,
    ),
    destination: LocationModel(
      address: 'Hinoo, Ranchi, Jharkhand',
      latitude: 23.3143,
      longitude: 85.3216,
    ),
    estimatedDistanceKm: 34.5,
    estimatedDurationMinutes: 48.0,
    estimatedFare: 166.0,
    paymentMethod: 'cash',
    paymentStatus: 'pending',
    isRoundTrip: false,
    createdAt: DateTime.now(),
  );

  testWidgets('BookingWaitingView renders all essential components seamlessly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: BookingWaitingView(
          booking: testBooking,
          rawData: const {
            'searchRadiusKm': 5.0,
            'matchedDriversCount': 0,
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify App Bar
    expect(find.text('DC-671633'), findsOneWidget);
    expect(find.text('Help'), findsOneWidget);

    // Verify Searching Hero
    expect(find.byType(SearchingHero), findsOneWidget);
    expect(find.text('Searching within 5 km'), findsOneWidget);
    expect(find.text('Searching nearby drivers'), findsOneWidget);

    // Verify Status Block
    expect(find.byType(StatusBlock), findsOneWidget);
    expect(find.text('Aapke liye driver dhundh rahe hain…'), findsOneWidget);
    expect(find.text('Aam taur par 1–3 minute'), findsOneWidget);

    // Verify Trip Summary Card
    expect(find.byType(TripSummaryCard), findsOneWidget);
    expect(find.text('₹166'), findsOneWidget);
    expect(find.text('Fixed price'), findsOneWidget);
    expect(find.text('One-Way / एक तरफा'), findsOneWidget);

    // Verify Support Strip
    expect(find.byType(SupportStrip), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Call Support'), findsOneWidget);

    // Verify Quiet Cancel Ride Button
    expect(find.text('Cancel ride / राइड रद्द करें'), findsOneWidget);
  });

  testWidgets('Tapping Cancel ride button opens CancelSheet modal', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: BookingWaitingView(
          booking: testBooking,
          rawData: const {},
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Tap quiet cancel ride button
    await tester.tap(find.text('Cancel ride / राइड रद्द करें'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Verify CancelSheet is displayed
    expect(find.byType(CancelSheet), findsOneWidget);
    expect(find.text('Ride cancel karni hai?'), findsOneWidget);
    expect(find.text('Free cancellation: no charge now / बिल्कुल मुफ़्त कैंसिलेशन'), findsOneWidget);
    expect(find.text('Keep Searching / इंतज़ार जारी रखें'), findsOneWidget);
    expect(find.text('Yes, cancel ride / हाँ, राइड कैंसल करें'), findsOneWidget);
  });

  testWidgets('Driver Found state displays DriverFoundCard with OTP and verified profile', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final acceptedBooking = testBooking.copyWith(
      status: 'confirmed',
      driverId: 'drv_test_01',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BookingWaitingView(
          booking: acceptedBooking,
          rawData: const {
            'driverName': 'Ramesh Oraon',
            'driverPhone': '+91 93418 28000',
            'driverRating': 4.9,
            'vehicleModel': 'Maruti Suzuki Dzire',
            'vehicleNumber': 'JH 01 DD 4821',
            'vehicleType': 'Prime Sedan',
            'otp': '4821',
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(DriverFoundCard), findsOneWidget);
    expect(find.text('Driver Found & Assigned!'), findsOneWidget);
    expect(find.text('Ramesh Oraon'), findsOneWidget);
    expect(find.text('JH 01 DD 4821'), findsOneWidget);
    expect(find.text('START RIDE OTP'), findsOneWidget);
    expect(find.text('Call Driver'), findsOneWidget);
  });

  testWidgets('No Driver state displays NoDriverState with 3 actionable pathways', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final noDriverBooking = testBooking.copyWith(
      status: 'no_driver_found',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BookingWaitingView(
          booking: noDriverBooking,
          rawData: const {'closedReason': 'No drivers available in area'},
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(NoDriverState), findsOneWidget);
    expect(find.text('Abhi koi driver free nahi hai'), findsOneWidget);
    expect(find.text('Try Again / दोबारा खोजें'), findsOneWidget);
    expect(find.text('Schedule for Later / बाद के लिए समय तय करें'), findsOneWidget);
    expect(find.text('Book on WhatsApp'), findsOneWidget);
    expect(find.text('Call Help Desk'), findsOneWidget);
  });
}
