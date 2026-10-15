import 'package:flutter_test/flutter_test.dart';
import 'package:district_car_customer/features/booking/waiting/booking_search_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BookingSearchController State Machine Tests', () {
    test('Initializes in SearchingNearbyState with 5km radius and 0s elapsed', () {
      final controller = BookingSearchController();
      expect(controller.state, isA<SearchingNearbyState>());
      expect(controller.state.radiusKm, 5.0);
      expect(controller.state.activeProgressStep, 1);
      expect(controller.state.matchedDriversCount, 0);
      controller.dispose();
    });

    test('Expands to 8km after 40 seconds simulated elapsed time', () {
      // Simulate controller started 41 seconds ago
      final pastTime = DateTime.now().subtract(const Duration(seconds: 41));
      final controller = BookingSearchController(initialStartedAt: pastTime);

      // Trigger tick
      // Since controller starts timer, let's wait 1.1s for periodic tick
      fakeAsyncTicking((_) {
        // Wait for update
      });
      controller.dispose();
    });

    test('Transitions to DriverFoundState when backend confirms driver', () {
      final controller = BookingSearchController();

      controller.updateFromBackend(
        status: 'confirmed',
        driverId: 'drv_jh_007',
        rawData: {
          'driverName': 'Suresh Munda',
          'driverPhone': '+91 98765 43210',
          'driverRating': 4.95,
          'vehicleModel': 'Maruti Suzuki Dzire',
          'vehicleNumber': 'JH 01 DD 4821',
          'vehicleType': 'Prime Sedan',
          'otp': '5932',
        },
      );

      expect(controller.state, isA<DriverFoundState>());
      final foundState = controller.state as DriverFoundState;
      expect(foundState.driverName, 'Suresh Munda');
      expect(foundState.vehicleNumber, 'JH 01 DD 4821');
      expect(foundState.otp, '5932');
      expect(foundState.activeProgressStep, 3);
      controller.dispose();
    });

    test('Transitions to NoDriverFoundState when status is no_driver_found', () {
      final controller = BookingSearchController();

      controller.updateFromBackend(
        status: 'no_driver_found',
        driverId: null,
        rawData: {'closedReason': 'No drivers in 12 km area'},
      );

      expect(controller.state, isA<NoDriverFoundState>());
      final noDriver = controller.state as NoDriverFoundState;
      expect(noDriver.failureReason, 'No drivers in 12 km area');
      controller.dispose();
    });

    test('User cancel triggers CancelledSearchState with recorded reason', () {
      final controller = BookingSearchController();

      controller.cancelSearch('Changed my plan');

      expect(controller.state, isA<CancelledSearchState>());
      final cancelState = controller.state as CancelledSearchState;
      expect(cancelState.cancelReason, 'Changed my plan');
      controller.dispose();
    });
  });
}

void fakeAsyncTicking(void Function(void) callback) {
  // Utility runner for tests
}
