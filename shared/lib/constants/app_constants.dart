class AppConstants {
  static const String appName = 'District Car';
  static const String currencySymbol = '₹';
  static const String currencyCode = 'INR';

  // Request timeout
  static const int driverRequestTimeoutSeconds = 25;

  // Search Radii (km)
  static const double initialSearchRadiusKm = 5.0;
  static const double maxSearchRadiusKm = 15.0;

  // Location update thresholds
  static const double driverLocationUpdateDistanceMeters = 20.0;
  static const int driverLocationUpdateIntervalSeconds = 10;
}

enum BookingStatus {
  requested,
  searchingDriver,
  driverAssigned,
  driverArriving,
  driverArrived,
  tripStarted,
  tripCompleted,
  cancelledByCustomer,
  cancelledByDriver,
  expired,
  noDriverFound,
}

extension BookingStatusX on BookingStatus {
  String get value {
    switch (this) {
      case BookingStatus.requested:
        return 'requested';
      case BookingStatus.searchingDriver:
        return 'searching_driver';
      case BookingStatus.driverAssigned:
        return 'driver_assigned';
      case BookingStatus.driverArriving:
        return 'driver_arriving';
      case BookingStatus.driverArrived:
        return 'driver_arrived';
      case BookingStatus.tripStarted:
        return 'trip_started';
      case BookingStatus.tripCompleted:
        return 'trip_completed';
      case BookingStatus.cancelledByCustomer:
        return 'cancelled_by_customer';
      case BookingStatus.cancelledByDriver:
        return 'cancelled_by_driver';
      case BookingStatus.expired:
        return 'expired';
      case BookingStatus.noDriverFound:
        return 'no_driver_found';
    }
  }

  static BookingStatus fromString(String? val) {
    switch (val) {
      case 'searching_driver':
        return BookingStatus.searchingDriver;
      case 'driver_assigned':
        return BookingStatus.driverAssigned;
      case 'driver_arriving':
        return BookingStatus.driverArriving;
      case 'driver_arrived':
        return BookingStatus.driverArrived;
      case 'trip_started':
        return BookingStatus.tripStarted;
      case 'trip_completed':
        return BookingStatus.tripCompleted;
      case 'cancelled_by_customer':
        return BookingStatus.cancelledByCustomer;
      case 'cancelled_by_driver':
        return BookingStatus.cancelledByDriver;
      case 'expired':
        return BookingStatus.expired;
      case 'no_driver_found':
        return BookingStatus.noDriverFound;
      default:
        return BookingStatus.requested;
    }
  }

  String get label {
    switch (this) {
      case BookingStatus.requested:
        return 'Requested';
      case BookingStatus.searchingDriver:
        return 'Searching Driver';
      case BookingStatus.driverAssigned:
        return 'Driver Assigned';
      case BookingStatus.driverArriving:
        return 'Driver Arriving';
      case BookingStatus.driverArrived:
        return 'Driver Arrived';
      case BookingStatus.tripStarted:
        return 'Trip In Progress';
      case BookingStatus.tripCompleted:
        return 'Completed';
      case BookingStatus.cancelledByCustomer:
        return 'Cancelled by You';
      case BookingStatus.cancelledByDriver:
        return 'Cancelled by Driver';
      case BookingStatus.expired:
        return 'Expired';
      case BookingStatus.noDriverFound:
        return 'No Driver Found';
    }
  }
}

enum DriverVerificationStatus {
  pending,
  approved,
  rejected,
  suspended,
}

extension DriverVerificationStatusX on DriverVerificationStatus {
  String get value {
    switch (this) {
      case DriverVerificationStatus.pending:
        return 'pending';
      case DriverVerificationStatus.approved:
        return 'approved';
      case DriverVerificationStatus.rejected:
        return 'rejected';
      case DriverVerificationStatus.suspended:
        return 'suspended';
    }
  }

  static DriverVerificationStatus fromString(String? val) {
    switch (val) {
      case 'approved':
        return DriverVerificationStatus.approved;
      case 'rejected':
        return DriverVerificationStatus.rejected;
      case 'suspended':
        return DriverVerificationStatus.suspended;
      default:
        return DriverVerificationStatus.pending;
    }
  }
}
