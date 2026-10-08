import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:district_car_shared/models/models.dart';

final List<VehicleCategoryModel> defaultVehicleCategories = [
  VehicleCategoryModel(
    id: 'car',
    name: 'Mini Cab',
    displayName: 'Economy Mini Cab',
    icon: 'directions_car',
    image: '',
    baseFare: 60.0,
    perKmRate: 14.0,
    perMinuteRate: 1.5,
    minimumFare: 80.0,
    bookingFee: 0.0,
    waitingCharge: 1.0,
    cancellationFee: 30.0,
    roundTripDiscountPercent: 35.0,
    hourlyWaitingCharge: 60.0,
    platformCommissionPercent: 10.0,
  ),
  VehicleCategoryModel(
    id: 'auto',
    name: 'Auto / E-Rick',
    displayName: 'Auto / E-Rickshaw',
    icon: 'electric_rickshaw',
    image: '',
    baseFare: 40.0,
    perKmRate: 10.0,
    perMinuteRate: 1.0,
    minimumFare: 50.0,
    bookingFee: 0.0,
    waitingCharge: 0.6,
    cancellationFee: 20.0,
    roundTripDiscountPercent: 35.0,
    hourlyWaitingCharge: 40.0,
    platformCommissionPercent: 10.0,
  ),
  VehicleCategoryModel(
    id: 'sedan',
    name: 'Sedan',
    displayName: 'Comfort Sedan',
    icon: 'local_taxi',
    image: '',
    baseFare: 80.0,
    perKmRate: 17.0,
    perMinuteRate: 2.0,
    minimumFare: 120.0,
    bookingFee: 0.0,
    waitingCharge: 1.2,
    cancellationFee: 40.0,
    roundTripDiscountPercent: 35.0,
    hourlyWaitingCharge: 60.0,
    platformCommissionPercent: 10.0,
  ),
  VehicleCategoryModel(
    id: 'suv',
    name: 'Rural SUV',
    displayName: 'Rural SUV (Bolero)',
    icon: 'directions_car_filled',
    image: '',
    baseFare: 120.0,
    perKmRate: 22.0,
    perMinuteRate: 2.5,
    minimumFare: 180.0,
    bookingFee: 0.0,
    waitingCharge: 1.5,
    cancellationFee: 50.0,
    roundTripDiscountPercent: 35.0,
    hourlyWaitingCharge: 80.0,
    platformCommissionPercent: 10.0,
  ),
  VehicleCategoryModel(
    id: 'bike',
    name: 'Bike',
    displayName: 'Gramin Bike',
    icon: 'two_wheeler',
    image: '',
    baseFare: 25.0,
    perKmRate: 8.0,
    perMinuteRate: 1.0,
    minimumFare: 35.0,
    bookingFee: 0.0,
    waitingCharge: 0.5,
    cancellationFee: 15.0,
    roundTripDiscountPercent: 30.0,
    hourlyWaitingCharge: 30.0,
    platformCommissionPercent: 10.0,
  ),
];

final vehicleCategoriesProvider = StreamProvider<List<VehicleCategoryModel>>((ref) {
  try {
    return FirebaseFirestore.instance
        .collection('vehicleCategories')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return defaultVehicleCategories;
          }
          return snapshot.docs
              .map((doc) => VehicleCategoryModel.fromMap(doc.data(), doc.id))
              .toList();
        })
        .handleError((_) => defaultVehicleCategories);
  } catch (_) {
    return Stream.value(defaultVehicleCategories);
  }
});
