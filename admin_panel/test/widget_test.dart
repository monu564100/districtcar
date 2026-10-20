import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:district_car_admin/main.dart';

void main() {
  testWidgets('Admin panel smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: DistrictCarAdminPanelApp()),
    );
    expect(find.byType(DistrictCarAdminPanelApp), findsOneWidget);
  });
}
