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

  factory LocationModel.fromMap(dynamic raw) {
    if (raw == null) {
      return LocationModel(latitude: 0.0, longitude: 0.0, address: '');
    }
    final Map map = (raw is Map) ? raw : {};
    double toDbl(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }
    return LocationModel(
      latitude: toDbl(map['latitude']),
      longitude: toDbl(map['longitude']),
      address: map['address']?.toString() ?? '',
      geohash: map['geohash']?.toString(),
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

  factory BookingModel.fromMap(dynamic rawMap, String docId) {
    final Map map = (rawMap is Map) ? rawMap : {};

    double toDbl(dynamic v, [double fallback = 0.0]) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    DateTime parseDate(dynamic d) {
      if (d == null) return DateTime.now();
      try {
        if (d.toString().contains('Timestamp')) {
          return (d as dynamic).toDate();
        }
        final parsed = DateTime.tryParse(d.toString());
        if (parsed != null) return parsed;
      } catch (_) {}
      return DateTime.now();
    }

    return BookingModel(
      id: docId,
      readableId: map['readableId']?.toString() ?? docId,
      customerId: map['customerId']?.toString() ?? '',
      customerName: (map['customerName'] ?? map['customer_name'] ?? map['riderName'] ?? map['userName'] ?? map['name'] ?? map['displayName'])?.toString().trim().isNotEmpty == true ? (map['customerName'] ?? map['customer_name'] ?? map['riderName'] ?? map['userName'] ?? map['name'] ?? map['displayName']).toString().trim() : null,
      customerPhone: (map['customerPhone'] ?? map['customer_phone'] ?? map['riderPhone'] ?? map['userPhone'] ?? map['phoneNumber'] ?? map['phone'] ?? map['mobile'] ?? map['customerMobile'])?.toString().trim().isNotEmpty == true ? (map['customerPhone'] ?? map['customer_phone'] ?? map['riderPhone'] ?? map['userPhone'] ?? map['phoneNumber'] ?? map['phone'] ?? map['mobile'] ?? map['customerMobile']).toString().trim() : null,
      bookingType: map['bookingType']?.toString(),
      tourDestinationName: map['tourDestinationName']?.toString(),
      stayHours: int.tryParse(map['stayHours']?.toString() ?? ''),
      driverId: map['driverId']?.toString(),
      driverName: map['driverName']?.toString(),
      driverPhone: map['driverPhone']?.toString(),
      driverPhoto: map['driverPhoto']?.toString(),
      vehiclePlate: (map['vehiclePlateNumber'] ?? map['vehiclePlate'])?.toString(),
      vehicleModel: map['vehicleModel']?.toString(),
      vehicleImage: map['vehicleImage']?.toString(),
      vehicleCategoryId: map['vehicleCategoryId']?.toString() ?? '',
      vehicleId: map['vehicleId']?.toString(),
      pickup: LocationModel.fromMap(map['pickup']),
      destination: LocationModel.fromMap(map['destination']),
      estimatedDistanceKm: toDbl(map['estimatedDistanceKm']),
      estimatedDurationMinutes: toDbl(map['estimatedDurationMinutes']),
      estimatedFare: toDbl(map['estimatedFare']),
      finalFare: map['finalFare'] != null ? toDbl(map['finalFare']) : null,
      paymentMethod: map['paymentMethod']?.toString() ?? 'cash',
      paymentStatus: map['paymentStatus']?.toString() ?? 'pending',
      status: map['status']?.toString() ?? 'requested',
      rideOtp: (map['rideOtp'] ?? map['otp'] ?? map['ride_otp'])?.toString().trim().isNotEmpty == true ? (map['rideOtp'] ?? map['otp'] ?? map['ride_otp']).toString().trim() : null,
      isRoundTrip: map['isRoundTrip'] == true,
      roundTripStoppingHours: toDbl(map['roundTripStoppingHours'], 1.0),
      scheduledDate: map['scheduledDate']?.toString(),
      scheduledTimeSlot: map['scheduledTimeSlot']?.toString(),
      createdAt: parseDate(map['createdAt']),
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
  final String hindiName;
  final String imageCredit;
  final String imageLicense;
  final String altTextEn;
  final String altTextHi;
  final String entryFee;
  final String timeNeeded;
  final String stepsOrParking;
  final List<String> safetyTips;
  final List<Map<String, dynamic>> nearbyStops;
  final Map<String, dynamic> hubPackages;
  final bool isCombo;
  final List<String> comboDestinations;
  final String packageType;

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
    this.hindiName = '',
    this.imageCredit = 'District Car Verified Partner / Tourism Dept',
    this.imageLicense = 'CC BY-SA 4.0',
    this.altTextEn = '',
    this.altTextHi = '',
    this.entryFee = 'Free Entry',
    this.timeNeeded = 'Half Day',
    this.stepsOrParking = 'Parking available',
    this.safetyTips = const [],
    this.nearbyStops = const [],
    this.hubPackages = const {},
    this.isCombo = false,
    this.comboDestinations = const [],
    this.packageType = '',
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
      'hindiName': hindiName,
      'imageCredit': imageCredit,
      'imageLicense': imageLicense,
      'altTextEn': altTextEn,
      'altTextHi': altTextHi,
      'entryFee': entryFee,
      'timeNeeded': timeNeeded,
      'stepsOrParking': stepsOrParking,
      'safetyTips': safetyTips,
      'nearbyStops': nearbyStops,
      'hubPackages': hubPackages,
      'isCombo': isCombo,
      'comboDestinations': comboDestinations,
      'packageType': packageType,
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
      hindiName: map['hindiName'] as String? ?? '',
      imageCredit: map['imageCredit'] as String? ?? 'Wikimedia Commons / Public License',
      imageLicense: map['imageLicense'] as String? ?? 'CC BY-SA 4.0',
      altTextEn: map['altTextEn'] as String? ?? '',
      altTextHi: map['altTextHi'] as String? ?? '',
      entryFee: map['entryFee'] as String? ?? 'Free Entry',
      timeNeeded: map['timeNeeded'] as String? ?? 'Half Day',
      stepsOrParking: map['stepsOrParking'] as String? ?? 'Parking available',
      safetyTips: (map['safetyTips'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      nearbyStops: (map['nearbyStops'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [],
      hubPackages: (map['hubPackages'] as Map<String, dynamic>?) ?? {},
      isCombo: map['isCombo'] == true || (map['category'] as String?)?.toLowerCase().trim() == 'combo',
      comboDestinations: (map['comboDestinations'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      packageType: map['packageType'] as String? ?? '',
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
    String? hindiName,
    String? imageCredit,
    String? imageLicense,
    String? altTextEn,
    String? altTextHi,
    String? entryFee,
    String? timeNeeded,
    String? stepsOrParking,
    List<String>? safetyTips,
    List<Map<String, dynamic>>? nearbyStops,
    Map<String, dynamic>? hubPackages,
    bool? isCombo,
    List<String>? comboDestinations,
    String? packageType,
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
      hindiName: hindiName ?? this.hindiName,
      imageCredit: imageCredit ?? this.imageCredit,
      imageLicense: imageLicense ?? this.imageLicense,
      altTextEn: altTextEn ?? this.altTextEn,
      altTextHi: altTextHi ?? this.altTextHi,
      entryFee: entryFee ?? this.entryFee,
      timeNeeded: timeNeeded ?? this.timeNeeded,
      stepsOrParking: stepsOrParking ?? this.stepsOrParking,
      safetyTips: safetyTips ?? this.safetyTips,
      nearbyStops: nearbyStops ?? this.nearbyStops,
      hubPackages: hubPackages ?? this.hubPackages,
      isCombo: isCombo ?? this.isCombo,
      comboDestinations: comboDestinations ?? this.comboDestinations,
      packageType: packageType ?? this.packageType,
    );
  }
}

