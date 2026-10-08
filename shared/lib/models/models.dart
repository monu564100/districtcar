export 'district_user.dart';

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
  final double roundTripDiscountPercent;
  final double hourlyWaitingCharge;
  final double platformCommissionPercent;
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
    this.roundTripDiscountPercent = 35.0,
    this.hourlyWaitingCharge = 60.0,
    this.platformCommissionPercent = 10.0,
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
      'roundTripDiscountPercent': roundTripDiscountPercent,
      'hourlyWaitingCharge': hourlyWaitingCharge,
      'platformCommissionPercent': platformCommissionPercent,
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
      roundTripDiscountPercent: (map['roundTripDiscountPercent'] as num?)?.toDouble() ?? 35.0,
      hourlyWaitingCharge: (map['hourlyWaitingCharge'] as num?)?.toDouble() ?? 60.0,
      platformCommissionPercent: (map['platformCommissionPercent'] as num?)?.toDouble() ?? 10.0,
      isActive: map['isActive'] as bool? ?? true,
    );
  }
}

class BookingModel {
  final String id;
  final String readableId;
  final String customerId;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? driverPhoto;
  final String? vehiclePlate;
  final String? vehicleModel;
  final String? vehicleImage;
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
  final bool isRoundTrip;
  final double roundTripStoppingHours;
  final String? scheduledDate;
  final String? scheduledTimeSlot;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.readableId,
    required this.customerId,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.driverPhoto,
    this.vehiclePlate,
    this.vehicleModel,
    this.vehicleImage,
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
    this.isRoundTrip = false,
    this.roundTripStoppingHours = 1.0,
    this.scheduledDate,
    this.scheduledTimeSlot,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'readableId': readableId,
      'customerId': customerId,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'driverPhoto': driverPhoto,
      'vehiclePlate': vehiclePlate,
      'vehicleModel': vehicleModel,
      'vehicleImage': vehicleImage,
      'vehicleCategoryId': vehicleCategoryId,
      'vehicleId': vehicleId,
      'pickup': pickup.toMap(),
      'destination': destination.toMap(),
      'estimatedDistanceKm': estimatedDistanceKm,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'estimatedFare': estimatedFare,
      'finalFare': finalFare,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'status': status,
      'rideOtp': rideOtp,
      'isRoundTrip': isRoundTrip,
      'roundTripStoppingHours': roundTripStoppingHours,
      'scheduledDate': scheduledDate,
      'scheduledTimeSlot': scheduledTimeSlot,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map, String docId) {
    return BookingModel(
      id: docId,
      readableId: map['readableId'] as String? ?? docId,
      customerId: map['customerId'] as String? ?? '',
      driverId: map['driverId'] as String?,
      driverName: map['driverName'] as String?,
      driverPhone: map['driverPhone'] as String?,
      driverPhoto: map['driverPhoto'] as String?,
      vehiclePlate: map['vehiclePlate'] as String?,
      vehicleModel: map['vehicleModel'] as String?,
      vehicleImage: map['vehicleImage'] as String?,
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
      isRoundTrip: map['isRoundTrip'] as bool? ?? false,
      roundTripStoppingHours: (map['roundTripStoppingHours'] as num?)?.toDouble() ?? 1.0,
      scheduledDate: map['scheduledDate'] as String?,
      scheduledTimeSlot: map['scheduledTimeSlot'] as String?,
      createdAt: (map['createdAt'] != null && map['createdAt'].toString().contains('Timestamp'))
          ? (map['createdAt'] as dynamic).toDate()
          : (map['createdAt'] != null && DateTime.tryParse(map['createdAt'].toString()) != null
              ? DateTime.parse(map['createdAt'].toString())
              : DateTime.now()),
    );
  }

  BookingModel copyWith({
    String? id,
    String? readableId,
    String? customerId,
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? driverPhoto,
    String? vehiclePlate,
    String? vehicleModel,
    String? vehicleImage,
    String? vehicleCategoryId,
    String? vehicleId,
    LocationModel? pickup,
    LocationModel? destination,
    double? estimatedDistanceKm,
    double? estimatedDurationMinutes,
    double? estimatedFare,
    double? finalFare,
    String? paymentMethod,
    String? paymentStatus,
    String? status,
    String? rideOtp,
    bool? isRoundTrip,
    double? roundTripStoppingHours,
    String? scheduledDate,
    String? scheduledTimeSlot,
    DateTime? createdAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      readableId: readableId ?? this.readableId,
      customerId: customerId ?? this.customerId,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverPhoto: driverPhoto ?? this.driverPhoto,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleImage: vehicleImage ?? this.vehicleImage,
      vehicleCategoryId: vehicleCategoryId ?? this.vehicleCategoryId,
      vehicleId: vehicleId ?? this.vehicleId,
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      estimatedDistanceKm: estimatedDistanceKm ?? this.estimatedDistanceKm,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      finalFare: finalFare ?? this.finalFare,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      rideOtp: rideOtp ?? this.rideOtp,
      isRoundTrip: isRoundTrip ?? this.isRoundTrip,
      roundTripStoppingHours: roundTripStoppingHours ?? this.roundTripStoppingHours,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTimeSlot: scheduledTimeSlot ?? this.scheduledTimeSlot,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
