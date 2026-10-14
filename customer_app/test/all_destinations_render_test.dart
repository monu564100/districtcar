import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:district_car_shared/services/destinations_service.dart';
import 'package:district_car_customer/features/tours/destination_detail_screen.dart';

void main() {
  testWidgets('Test rendering all 13 destinations in DestinationDetailScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    for (final dest in DestinationsService.defaultDestinations) {
      debugPrint('Testing DestinationDetailScreen for: ${dest.id} (${dest.name})');
      await tester.pumpWidget(
        MaterialApp(
          home: DestinationDetailScreen(key: ValueKey(dest.id), destination: dest),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(dest.name), findsOneWidget, reason: 'Failed on ${dest.id}');
      expect(find.text('Plan this trip'), findsOneWidget, reason: 'Failed on ${dest.id}');
    }
    debugPrint('ALL 13 DESTINATIONS PASSED IN TEST!');
  });
}
