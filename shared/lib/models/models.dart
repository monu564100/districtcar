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
  final String? customerName;
  final String? customerPhone;
  final String? bookingType;
  final String? tourDestinationName;
  final int? stayHours;
  final String? scheduledDate;
  final String? scheduledTimeSlot;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.readableId,
    required this.customerId,
    this.customerName,
    this.customerPhone,
    this.bookingType,
    this.tourDestinationName,
    this.stayHours,
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
      if (customerName != null) 'customerName': customerName,
      if (customerPhone != null) 'customerPhone': customerPhone,
      if (bookingType != null) 'bookingType': bookingType,
      if (tourDestinationName != null) 'tourDestinationName': tourDestinationName,
      if (stayHours != null) 'stayHours': stayHours,
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
      customerName: map['customerName'] as String?,
      customerPhone: map['customerPhone'] as String?,
      bookingType: map['bookingType'] as String?,
      tourDestinationName: map['tourDestinationName'] as String?,
      stayHours: (map['stayHours'] as num?)?.toInt(),
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
    String? customerName,
    String? customerPhone,
    String? bookingType,
    String? tourDestinationName,
    int? stayHours,
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
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      bookingType: bookingType ?? this.bookingType,
      tourDestinationName: tourDestinationName ?? this.tourDestinationName,
      stayHours: stayHours ?? this.stayHours,
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

class PopularDestinationModel {
  final String id;
  final String name;
  final String category; // 'waterfall', 'temple', 'hill_station', 'nature', 'heritage'
  final String district;
  final String locationAddress;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final List<String> galleryImages;
  final String description;
  final String bestTimeToVisit;
  final String timings;
  final double rating;
  final int reviewsCount;
  final double approxDistanceKm;
  final double startingFare;
  final bool isTrending;
  final bool isPopular;
  final List<String> highlights;

  PopularDestinationModel({
    required this.id,
    required this.name,
    required this.category,
    required this.district,
    required this.locationAddress,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    this.galleryImages = const [],
    required this.description,
    this.bestTimeToVisit = 'October to March',
    this.timings = '06:00 AM – 06:00 PM',
    this.rating = 4.8,
    this.reviewsCount = 450,
    this.approxDistanceKm = 45.0,
    this.startingFare = 799.0,
    this.isTrending = true,
    this.isPopular = true,
    this.highlights = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'district': district,
      'locationAddress': locationAddress,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'galleryImages': galleryImages,
      'description': description,
      'bestTimeToVisit': bestTimeToVisit,
      'timings': timings,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'approxDistanceKm': approxDistanceKm,
      'startingFare': startingFare,
      'isTrending': isTrending,
      'isPopular': isPopular,
      'highlights': highlights,
    };
  }

  factory PopularDestinationModel.fromMap(Map<String, dynamic> map, String docId) {
    return PopularDestinationModel(
      id: docId,
      name: map['name'] as String? ?? 'Tour Destination',
      category: (map['category'] as String? ?? 'nature').toLowerCase().trim(),
      district: map['district'] as String? ?? 'Ranchi',
      locationAddress: map['locationAddress'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 23.3441,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 85.3096,
      imageUrl: map['imageUrl'] as String? ?? '',
      galleryImages: (map['galleryImages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      description: map['description'] as String? ?? '',
      bestTimeToVisit: map['bestTimeToVisit'] as String? ?? 'October to March',
      timings: map['timings'] as String? ?? '06:00 AM – 06:00 PM',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.8,
      reviewsCount: (map['reviewsCount'] as num?)?.toInt() ?? 320,
      approxDistanceKm: (map['approxDistanceKm'] as num?)?.toDouble() ?? 45.0,
      startingFare: (map['startingFare'] as num?)?.toDouble() ?? 799.0,
      isTrending: map['isTrending'] == true,
      isPopular: map['isPopular'] ?? true,
      highlights: (map['highlights'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  PopularDestinationModel copyWith({
    String? id,
    String? name,
    String? category,
    String? district,
    String? locationAddress,
    double? latitude,
    double? longitude,
    String? imageUrl,
    List<String>? galleryImages,
    String? description,
    String? bestTimeToVisit,
    String? timings,
    double? rating,
    int? reviewsCount,
    double? approxDistanceKm,
    double? startingFare,
    bool? isTrending,
    bool? isPopular,
    List<String>? highlights,
  }) {
    return PopularDestinationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      district: district ?? this.district,
      locationAddress: locationAddress ?? this.locationAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      galleryImages: galleryImages ?? this.galleryImages,
      description: description ?? this.description,
      bestTimeToVisit: bestTimeToVisit ?? this.bestTimeToVisit,
      timings: timings ?? this.timings,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      approxDistanceKm: approxDistanceKm ?? this.approxDistanceKm,
      startingFare: startingFare ?? this.startingFare,
      isTrending: isTrending ?? this.isTrending,
      isPopular: isPopular ?? this.isPopular,
      highlights: highlights ?? this.highlights,
    );
  }
}

