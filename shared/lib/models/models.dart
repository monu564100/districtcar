class LocationModel {
  final double latitude;
  final double longitude;
  final String address;
  final String? geohash;

  LocationModel({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.geohash,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      if (geohash != null) 'geohash': geohash,
    };
  }

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      address: map['address'] as String? ?? '',
      geohash: map['geohash'] as String?,
    );
  }
}

class VehicleCategoryModel {
  final String id;
  final String name;
  final String displayName;
  final String icon;
  final String image;
  final double baseFare;
  final double perKmRate;
  final double perMinuteRate;
  final double minimumFare;
  final double bookingFee;
  final double waitingCharge;
  final double cancellationFee;
  final bool isActive;

  VehicleCategoryModel({
    required this.id,
    required this.name,
    required this.displayName,
    required this.icon,
    required this.image,
    required this.baseFare,
    required this.perKmRate,
    required this.perMinuteRate,
    required this.minimumFare,
    required this.bookingFee,
    required this.waitingCharge,
    required this.cancellationFee,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'displayName': displayName,
      'icon': icon,
      'image': image,
      'baseFare': baseFare,
      'perKmRate': perKmRate,
      'perMinuteRate': perMinuteRate,
      'minimumFare': minimumFare,
      'bookingFee': bookingFee,
      'waitingCharge': waitingCharge,
      'cancellationFee': cancellationFee,
      'isActive': isActive,
    };
  }

  factory VehicleCategoryModel.fromMap(Map<String, dynamic> map, String docId) {
    return VehicleCategoryModel(
      id: docId,
      name: map['name'] as String? ?? '',
      displayName: map['displayName'] as String? ?? map['name'] as String? ?? '',
      icon: map['icon'] as String? ?? '',
      image: map['image'] as String? ?? '',
      baseFare: (map['baseFare'] as num?)?.toDouble() ?? 0.0,
      perKmRate: (map['perKmRate'] as num?)?.toDouble() ?? 0.0,
      perMinuteRate: (map['perMinuteRate'] as num?)?.toDouble() ?? 0.0,
      minimumFare: (map['minimumFare'] as num?)?.toDouble() ?? 0.0,
      bookingFee: (map['bookingFee'] as num?)?.toDouble() ?? 0.0,
      waitingCharge: (map['waitingCharge'] as num?)?.toDouble() ?? 0.0,
      cancellationFee: (map['cancellationFee'] as num?)?.toDouble() ?? 0.0,
      isActive: map['isActive'] as bool? ?? true,
    );
  }
}

class BookingModel {
  final String id;
  final String readableId;
  final String customerId;
  final String? driverId;
  final String vehicleCategoryId;
  final String? vehicleId;
  final LocationModel pickup;
  final LocationModel destination;
  final double estimatedDistanceKm;
  final double estimatedDurationMinutes;
  final double estimatedFare;
  final double? finalFare;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final String? rideOtp;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.readableId,
    required this.customerId,
    this.driverId,
    required this.vehicleCategoryId,
    this.vehicleId,
    required this.pickup,
    required this.destination,
    required this.estimatedDistanceKm,
    required this.estimatedDurationMinutes,
    required this.estimatedFare,
    this.finalFare,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    this.rideOtp,
    required this.createdAt,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map, String docId) {
    return BookingModel(
      id: docId,
      readableId: map['readableId'] as String? ?? docId,
      customerId: map['customerId'] as String? ?? '',
      driverId: map['driverId'] as String?,
      vehicleCategoryId: map['vehicleCategoryId'] as String? ?? '',
      vehicleId: map['vehicleId'] as String?,
      pickup: LocationModel.fromMap(map['pickup'] as Map<String, dynamic>? ?? {}),
      destination: LocationModel.fromMap(map['destination'] as Map<String, dynamic>? ?? {}),
      estimatedDistanceKm: (map['estimatedDistanceKm'] as num?)?.toDouble() ?? 0.0,
      estimatedDurationMinutes: (map['estimatedDurationMinutes'] as num?)?.toDouble() ?? 0.0,
      estimatedFare: (map['estimatedFare'] as num?)?.toDouble() ?? 0.0,
      finalFare: (map['finalFare'] as num?)?.toDouble(),
      paymentMethod: map['paymentMethod'] as String? ?? 'cash',
      paymentStatus: map['paymentStatus'] as String? ?? 'pending',
      status: map['status'] as String? ?? 'requested',
      rideOtp: map['rideOtp'] as String?,
      createdAt: (map['createdAt'] != null && map['createdAt'].toString().contains('Timestamp'))
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }
}
