import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:district_car_customer/features/auth/login_screen.dart';
import 'package:district_car_customer/features/auth/profile_setup_screen.dart';
import 'package:district_car_customer/features/trips/trips_history_screen.dart';
import 'package:district_car_customer/features/profile/profile_screen.dart';
import 'package:district_car_customer/core/router.dart';

void main() {
  testWidgets('Unsigned user opening /trips shows LoginScreen with Google sign-in container', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TripsHistoryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Since user is null, TripsHistoryScreen immediately renders LoginScreen!
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Welcome to District Car'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('Unsigned user opening /profile shows LoginScreen with Google sign-in container', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Since user is null, ProfileScreen immediately renders LoginScreen!
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Welcome to District Car'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('ProfileSetupScreen renders high-quality onboarding with Name, Number, DOB, and Address', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ProfileSetupScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Complete Your Profile'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Mobile Number'), findsOneWidget);
    expect(find.text('Date of Birth (DOB)'), findsOneWidget);
    expect(find.text('Home Address / District'), findsOneWidget);
    expect(find.text('Save & Start Riding'), findsOneWidget);
  });
}
