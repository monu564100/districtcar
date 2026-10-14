import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:district_car_shared/widgets/location_picker_sheet.dart';
import 'package:district_car_shared/models/models.dart';

void main() {
  testWidgets('LocationPickerSheet opens in typing mode and renders premium layout', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    LocationModel? picked;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                picked = await LocationPickerSheet.show(
                  context,
                  title: 'Select Destination',
                  initialValue: '',
                  isPickup: false,
                );
              },
              child: const Text('Open Picker'),
            ),
          ),
        ),
      ),
    );

    // Tap button to open sheet
    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    // 1. Verify sheet and header components render
    expect(find.byType(LocationPickerSheet), findsOneWidget);
    expect(find.text('Select Destination'), findsOneWidget);
    expect(find.text('DESTINATION (कहाँ जाना है)'), findsOneWidget);

    // 2. Verify TextField is rendered with autofocus
    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);
    final textField = tester.widget<TextField>(textFieldFinder);
    expect(textField.autofocus, isTrue);

    // 3. Verify GPS tile and District filter
    expect(find.text('Use Current GPS Location (वर्तमान स्थान)'), findsOneWidget);
    expect(find.textContaining('Select District'), findsOneWidget);

    // 4. Test typing in the search bar
    await tester.enterText(textFieldFinder, 'Ranchi');
    await tester.pumpAndSettle();

    expect(find.text('Ranchi'), findsOneWidget);

    // 5. Test clear button
    final clearFinder = find.byIcon(Icons.cancel_rounded);
    expect(clearFinder, findsOneWidget);
    await tester.tap(clearFinder);
    await tester.pumpAndSettle();

    // 6. Test selecting a popular hub
    final firstResultFinder = find.byIcon(Icons.north_west_rounded);
    expect(firstResultFinder, findsWidgets);
    await tester.tap(firstResultFinder.first);
    await tester.pumpAndSettle();

    // 7. Verify sheet dismissed and returned location
    expect(find.byType(LocationPickerSheet), findsNothing);
    expect(picked, isNotNull);
  });
}
