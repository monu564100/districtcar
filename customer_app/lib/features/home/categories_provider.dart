import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:district_car_shared/models/models.dart';

final List<VehicleCategoryModel> defaultVehicleCategories = [
  VehicleCategoryModel(
    id: 'car',
    name: 'Car',
    displayName: 'Car',
    icon: 'directions_car',
    image: '',
    baseFare: 50.0,
    perKmRate: 15.0,
    perMinuteRate: 2.0,
    minimumFare: 80.0,
    bookingFee: 10.0,
    waitingCharge: 2.0,
    cancellationFee: 30.0,
  ),
  VehicleCategoryModel(
    id: 'taxi',
    name: 'Taxi',
    displayName: 'Taxi',
    icon: 'local_taxi',
    image: '',
    baseFare: 40.0,
    perKmRate: 12.0,
    perMinuteRate: 1.5,
    minimumFare: 60.0,
    bookingFee: 10.0,
    waitingCharge: 2.0,
    cancellationFee: 25.0,
  ),
  VehicleCategoryModel(
    id: 'bus',
    name: 'Bus',
    displayName: 'Bus',
    icon: 'directions_bus',
    image: '',
    baseFare: 30.0,
    perKmRate: 6.0,
    perMinuteRate: 1.0,
    minimumFare: 40.0,
    bookingFee: 5.0,
    waitingCharge: 1.0,
    cancellationFee: 15.0,
  ),
  VehicleCategoryModel(
    id: 'bike',
    name: 'Bike',
    displayName: 'Bike',
    icon: 'two_wheeler',
    image: '',
    baseFare: 20.0,
    perKmRate: 8.0,
    perMinuteRate: 1.0,
    minimumFare: 35.0,
    bookingFee: 5.0,
    waitingCharge: 1.0,
    cancellationFee: 15.0,
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
