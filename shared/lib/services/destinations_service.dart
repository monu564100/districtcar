import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class DestinationsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Curated authentic list of Jharkhand's most popular tourist spots
  static final List<PopularDestinationModel> defaultDestinations = [
    // 1. Waterfalls
    PopularDestinationModel(
      id: 'hundru_falls',
      name: 'Hundru Falls (हुंडरू जलप्रपात)',
      category: 'waterfall',
      district: 'Ranchi',
      locationAddress: 'Hundru Falls, Ormanjhi-Purulia Road, Ranchi, Jharkhand 835219',
      latitude: 23.4503,
      longitude: 85.6567,
      imageUrl: 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=900&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?auto=format&fit=crop&w=900&q=80',
      ],
      description:
          'Hundru Falls is the 34th highest waterfall in India and one of Ranchi’s crown jewels. Cascading down from a dramatic height of 98 meters (322 ft) on the Subarnarekha River, the roaring water creates stunning frothy plunge pools surrounded by rugged rock formations. Perfect for family picnics, photography, and refreshing village nature excursions.',
      highlights: [
        '98m (322 ft) Spectacular Drop',
        'Subarnarekha River Plunge Pool',
        'Spectacular Rock Formations',
        'Safe Steps & Viewing Deck',
      ],
      bestTimeToVisit: 'July to February (Monsoon & Winter)',
      timings: '06:00 AM – 05:30 PM',
      rating: 4.8,
      reviewsCount: 1420,
      approxDistanceKm: 44.0,
      startingFare: 849.0,
      isTrending: true,
      isPopular: true,
    ),
    PopularDestinationModel(
      id: 'dassam_falls',
      name: 'Dassam Falls (दशम जलप्रपात)',
      category: 'waterfall',
      district: 'Ranchi',
      locationAddress: 'Taimara, Bundu, Ranchi-Tata NH 33, Ranchi, Jharkhand 835204',
      latitude: 23.1438,
      longitude: 85.4667,
      imageUrl: 'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?auto=format&fit=crop&w=900&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=900&q=80',
      ],
      description:
          'Also known as Da-song falls in local Mundari dialect (meaning gathering of 10 streams), Dassam Falls drops from 44 meters (144 ft) on the Kanchi River. The deafening sound of gushing waters across jagged rocks and verdant green canopies creates an awe-inspiring sight that draws tourists from across eastern India.',
      highlights: [
        '10 Streams of Kanchi River',
        '144 Feet Breathtaking Fall',
        'Lush Forest Covered Foothills',
        'Picnic Shelters & Snack Stalls',
      ],
      bestTimeToVisit: 'August to March',
      timings: '06:00 AM – 06:00 PM',
      rating: 4.7,
      reviewsCount: 1180,
      approxDistanceKm: 39.0,
      startingFare: 799.0,
      isTrending: true,
      isPopular: true,
    ),
    PopularDestinationModel(
      id: 'jonha_falls',
      name: 'Jonha Falls (जोन्हा / गौतमधारा)',
      category: 'waterfall',
      district: 'Ranchi',
      locationAddress: 'Jonha, Gautamdhara, Anigada, Ranchi, Jharkhand 835103',
      latitude: 23.3425,
      longitude: 85.6083,
      imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=900&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=900&q=80',
      ],
      description:
          'Jonha Falls, famously called Gautamdhara, is a classic hanging valley waterfall where the holy Raru River drops 43 meters (141 ft). An ancient Lord Buddha Ashram and Shiva Mandir sits at the top of the plateau, where tradition holds that Gautama Buddha meditated during his spiritual wanderings.',
      highlights: [
        'Historic Lord Buddha Temple',
        'Hanging Valley Edge',
        'Over 700 Stone Steps',
        'Scenic Railway Station Nearby',
      ],
      bestTimeToVisit: 'September to March',
      timings: '06:00 AM – 05:00 PM',
      rating: 4.6,
      reviewsCount: 890,
      approxDistanceKm: 42.0,
      startingFare: 820.0,
      isTrending: false,
      isPopular: true,
    ),
    PopularDestinationModel(
      id: 'panchghagh_falls',
      name: 'Panchghagh Falls (पंचघाघ जलप्रपात)',
      category: 'waterfall',
      district: 'Khunti',
      locationAddress: 'Khunti-Chaibasa Highway, Khunti District, Jharkhand 835210',
      latitude: 22.8800,
      longitude: 85.2500,
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=900&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=900&q=80',
      ],
      description:
          'Panchghagh is a pristine cascading waterfall formed by five distinct streams of the Banai River flowing smoothly over rocky granite shelves. Because the streams are gentle, shallow, and wide, it is renowned as the safest waterfall in Jharkhand for families and children to dip their feet and enjoy peaceful outings.',
      highlights: [
        '5 Serene Cascading Streams',
        'Gentle & Safe Water Currents',
        'Ideal Family Picnic Spot',
        'Pristine Rural Environment',
      ],
      bestTimeToVisit: 'October to February',
      timings: '07:00 AM – 05:30 PM',
      rating: 4.6,
      reviewsCount: 650,
      approxDistanceKm: 55.0,
      startingFare: 999.0,
      isTrending: false,
      isPopular: true,
    ),
    PopularDestinationModel(
      id: 'lodh_falls',
      name: 'Lodh Falls (लोध / बुढ़ा घाघ)',
      category: 'waterfall',
      district: 'Latehar',
      locationAddress: 'Mahuadanr Forest Valley, Latehar District, Jharkhand 822119',
      latitude: 23.5350,
      longitude: 84.1160,
      imageUrl: 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=900&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=900&q=80',
      ],
      description:
          'Lodh Falls is the grandest and highest waterfall in Jharkhand with a towering multi-tiered fall of 143 meters (469 ft) on the Burha River. Hidden inside the deep virgin sal forests of the Palamu plateau, its mighty roar can be heard over 10 kilometers away, making it an epic outstation excursion.',
      highlights: [
        'Highest Waterfall in Jharkhand (469 ft)',
        'Deep Sal Forest Wilderness',
        'Multi-Tier Cascades',
        'Untouched Natural Splendor',
      ],
      bestTimeToVisit: 'August to January',
      timings: '07:00 AM – 04:30 PM',
      rating: 4.9,
      reviewsCount: 520,
      approxDistanceKm: 195.0,
      startingFare: 2799.0,
      isTrending: true,
      isPopular: true,
    ),

    // 2. Temples & Spiritual
    PopularDestinationModel(
      id: 'baidyanath_dham',
      name: 'Baba Baidyanath Jyotirlinga (बाबा बैद्यनाथ धाम)',
      category: 'temple',
      district: 'Deoghar',
      locationAddress: 'Shivganga Muhalla, Deoghar, Santhal Pargana, Jharkhand 814112',
      latitude: 24.4925,
      longitude: 86.7000,
      imageUrl: 'https://images.unsplash.com/photo-1582510003544-4d00b7f74220?auto=format&fit=crop&w=900&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1582510003544-4d00b7f74220?auto=format&fit=crop&w=900&q=80',
      ],
      description:
          'Baba Baidyanath Temple is one of the sacred 12 Jyotirlingas of Lord Shiva and also one of the 51 Shaktipeeths in Hindu belief. Revered for centuries, millions of pilgrims undertake the sacred Shravani Mela Kanwar Yatra here. The temple spire boasts an iconic golden Panchshula that is revered by devotees worldwide.',
      highlights: [
        'One of the 12 Sacred Jyotirlingas',
        '51 Shakti Peeth Destination',
        'Sacred Shivganga Water Pond',
        'Ancient Nagara Architecture',
      ],
      bestTimeToVisit: 'All Year (Especially July-August & Winters)',
      timings: '04:00 AM – 09:00 PM',
      rating: 4.9,
      reviewsCount: 3850,
      approxDistanceKm: 250.0,
      startingFare: 3499.0,
      isTrending: true,
      isPopular: true,
    ),
    PopularDestinationModel(
      id: 'jagannath_temple_ranchi',
      name: 'Jagannath Temple (जगन्नाथ मंदिर, रांची)',
      category: 'temple',
      district: 'Ranchi',
      locationAddress: 'Jagannathpur Hill, Dhurwa, HEC Township, Ranchi 834004',
      latitude: 23.3283,
      longitude: 85.2750,
      imageUrl: 'https://images.unsplash.com/photo-1609766857041-ed402ea8069a?auto=format&fit=crop&w=900&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1609766857041-ed402ea8069a?auto=format&fit=crop&w=900&q=80',
      ],
      description:
          'Built in 1691 by King Barkagarh Thakur Ani Nath Shahdeo, this revered hilltop shrine mimics the sacred Puri Jagannath Temple architecture. Perched on a gentle hill in Dhurwa, it hosts the famous annual Rath Yatra festival drawing thousands of devotees, and offers peaceful vistas over Ranchi city.',
      highlights: [
        '17th-Century Heritage Architecture',
        'Hilltop Panoramic City Views',
        'Famous Annual Rath Yatra',
        'Lord Balabhadra & Subhadra Deities',
      ],
      bestTimeToVisit: 'All Year Round',
      timings: '05:00 AM – 12:00 PM & 03:30 PM – 08:30 PM',
      rating: 4.7,
      reviewsCount: 1640,
      approxDistanceKm: 11.0,
      startingFare: 299.0,
      isTrending: false,
      isPopular: true,
    ),
    PopularDestinationModel(
      id: 'rajrappa_temple',
      name: 'Maa Chhinnamastika Mandir (रजरप्पा मंदिर)',
      category: 'temple',
      district: 'Ramgarh',
      locationAddress: 'Rajrappa, Bhairavi & Damodar River Confluence, Ramgarh 829101',
      latitude: 23.6322,
      longitude: 85.7111,
      imageUrl: 'https://images.unsplash.com/photo-1620619767323-b95a89183081?auto=format&fit=crop&w=900&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1620619767323-b95a89183081?auto=format&fit=crop&w=900&q=80',
      ],
      description:
          'A sacred Shakta pilgrimage situated at the scenic confluence of the roaring Bhairavi (Bhera) waterfall and the majestic Damodar River. Dedicated to Goddess Chhinnamasta—one of the 10 Mahavidyas—this centuries-old temple holds supreme tantric and spiritual significance in Jharkhand.',
      highlights: [
        'Goddess Chhinnamasta Mahavidya Peeth',
        'Scenic River Confluence (Sangam)',
        'Boating in Damodar Waters',
        'Ancient Rock Carvings',
      ],
      bestTimeToVisit: 'October to April',
      timings: '05:00 AM – 08:30 PM',
      rating: 4.8,
      reviewsCount: 2210,
      approxDistanceKm: 68.0,
      startingFare: 1199.0,
      isTrending: true,
      isPopular: true,
    ),
    PopularDestinationModel(
      id: 'parasnath_shikharji',
      name: 'Shree Shikharji Parasnath (सम्मेद शिखरजी)',
      category: 'temple',
      district: 'Giridih',
      locationAddress: 'Madhuban, Parasnath Hill, Giridih District, Jharkhand 825329',
      latitude: 23.9620,
      longitude: 86.1310,
      imageUrl: 'https://images.unsplash.com/photo-1519817650390-64a93db51149?auto=format&fit=crop&w=900&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1519817650390-64a93db51149?auto=format&fit=crop&w=900&q=80',
      ],
      description:
          'Shikharji is the highest mountain peak in Jharkhand (1365 meters) and the most holy pilgrimage shrine for the global Jain community. It is the sacred Nirvana Bhumi where 20 out of the 24 Tirthankaras attained Moksha. The trek amidst serene mountain mist and divine Tonks is an unforgettable spiritual journey.',
      highlights: [
        'Highest Mountain Peak in Jharkhand (1365m)',
        'Sacred Moksha Bhumi of 20 Tirthankaras',
        'Madhuban Base Ashrams & Museums',
        'Serene Misty Mountain Trails',
      ],
      bestTimeToVisit: 'October to March',
      timings: '04:00 AM – 08:00 PM',
      rating: 4.9,
      reviewsCount: 1980,
      approxDistanceKm: 165.0,
      startingFare: 2499.0,
      isTrending: true,
      isPopular: true,
    ),
    PopularDestinationModel(
      id: 'pahari_mandir',
      name: 'Pahari Mandir (पहाड़ी मंदिर, रांची)',
      category: 'temple',
      district: 'Ranchi',
      locationAddress: 'Pahari Tola, Ratu Road, Ranchi, Jharkhand 834005',
      latitude: 23.3742,
      longitude: 85.3120,
      imageUrl: 'https://images.unsplash.com/photo-1545232979-8bf68ee9b1af?auto=format&fit=crop&w=900&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1545232979-8bf68ee9b1af?auto=format&fit=crop&w=900&q=80',
      ],
      description:
          'Perched at an altitude of 2140 feet atop Phansi Tongri hill, Pahari Mandir is dedicated to Lord Shiva. It holds a unique patriotic tradition where the Indian National Tricolour flag has been hoisted with honor since 1947 alongside temple sanctums, while offering a 360-degree skyline view of Ranchi.',
      highlights: [
        'Hilltop Shiva Sanctum at 2140 ft',
        '360° Ranchi City Skyline View',
        '468 Steps Gentle Climb',
        'Historic Patriotic Flag Hoisting Spot',
      ],
      bestTimeToVisit: 'All Year (Early Mornings & Evenings)',
      timings: '05:00 AM – 08:30 PM',
      rating: 4.6,
      reviewsCount: 1540,
      approxDistanceKm: 4.5,
      startingFare: 199.0,
      isTrending: false,
      isPopular: true,
    ),

    // 3. Hill Stations & Nature
    PopularDestinationModel(
      id: 'netarhat',
      name: 'Netarhat (नेतरहाट - छोटानागपुर की रानी)',
      category: 'hill_station',
      district: 'Latehar',
      locationAddress: 'Netarhat Plateau, Latehar District, Jharkhand 835218',
      latitude: 23.4833,
      longitude: 84.2667,
      imageUrl: 'https://images.unsplash.com/photo-1506197603052-3cc9c3a201bd?auto=format&fit=crop&w=900&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1506197603052-3cc9c3a201bd?auto=format&fit=crop&w=900&q=80',
      ],
      description:
          'Netarhat, acclaimed as the "Queen of Chotanagpur", is Jharkhand’s premier hill station located 3700 feet above sea level. Famed for its hypnotic sunrise and sunset at Magnolia Point, fragrant pine tree forests, crisp cool mountain air, and pear orchards, it is the ultimate romantic getaway and weekend escape.',
      highlights: [
        'Magnolia Point Sunset View',
        'Pine Tree Forest & Pear Orchards',
        'Pleasant Mountain Weather',
        'Netarhat Dam & Sunrise Point',
      ],
      bestTimeToVisit: 'September to March',
      timings: 'Open 24 Hours (Sunrise to Sunset Recommended)',
      rating: 4.9,
      reviewsCount: 2150,
      approxDistanceKm: 155.0,
      startingFare: 2399.0,
      isTrending: true,
      isPopular: true,
    ),
    PopularDestinationModel(
      id: 'patratu_valley',
      name: 'Patratu Valley & Dam (पतरातू घाटी एवं डैम)',
      category: 'hill_station',
      district: 'Ramgarh',
      locationAddress: 'Patratu Ghat S-Curve Road & Lake Dam, Ramgarh, Jharkhand 829119',
      latitude: 23.6428,
      longitude: 85.3033,
      imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=900&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=900&q=80',
      ],
      description:
          'Patratu Valley is famous for its stunning zig-zag S-curve winding roads snaking through verdant green hills. At the bottom lies the sprawling Patratu Lake and Dam, featuring state-of-the-art speed boating, island resorts, water sports, and sunset view decks that make for an exhilarating drive from Ranchi.',
      highlights: [
        'Iconic S-Curve Ghat Driving Route',
        'Speed Boating & Island Lake Cruises',
        'Sunset Viewpoints with Food Plazas',
        'Modern Tourism Complex & Parks',
      ],
      bestTimeToVisit: 'All Year (Evenings & Winters Best)',
      timings: '06:00 AM – 07:00 PM',
      rating: 4.8,
      reviewsCount: 3100,
      approxDistanceKm: 38.0,
      startingFare: 749.0,
      isTrending: true,
      isPopular: true,
    ),
    PopularDestinationModel(
      id: 'betla_national_park',
      name: 'Betla National Park (बेतला राष्ट्रीय उद्यान)',
      category: 'nature',
      district: 'Latehar',
      locationAddress: 'Betla, Palamu Tiger Reserve, Latehar-Daltonganj, Jharkhand 822126',
      latitude: 23.8667,
      longitude: 84.1833,
      imageUrl: 'https://images.unsplash.com/photo-1534177616072-ef7dc120449d?auto=format&fit=crop&w=900&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1534177616072-ef7dc120449d?auto=format&fit=crop&w=900&q=80',
      ],
      description:
          'Betla National Park is one of India’s pioneering wildlife sanctuaries under Project Tiger. Spanning thick sal forests and bamboo groves, visitors enjoy open-jeep safaris encountering wild elephants, leopards, sloths, spotted deer, and the historic 16th-century twin forts of the Chero Kings nestled deep within the jungle.',
      highlights: [
        'Open Jeep Wildlife Safaris',
        'Wild Elephants & Tiger Reserve',
        'Historic 16th-Century Chero Fort',
        'Rich Bird Watching Haven',
      ],
      bestTimeToVisit: 'November to April',
      timings: '06:00 AM – 10:00 AM & 02:00 PM – 05:00 PM',
      rating: 4.7,
      reviewsCount: 880,
      approxDistanceKm: 170.0,
      startingFare: 2650.0,
      isTrending: false,
      isPopular: true,
    ),
  ];

  /// Live Firestore Stream with local fallback
  static Stream<List<PopularDestinationModel>> streamDestinations() {
    return _firestore.collection('popular_destinations').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return defaultDestinations;
      }
      return snapshot.docs.map((doc) {
        return PopularDestinationModel.fromMap(doc.data(), doc.id);
      }).toList();
    }).handleError((_) => defaultDestinations);
  }

  /// Get all destinations (with instant fallback)
  static Future<List<PopularDestinationModel>> getDestinations() async {
    try {
      final snap = await _firestore.collection('popular_destinations').get();
      if (snap.docs.isEmpty) {
        return defaultDestinations;
      }
      return snap.docs.map((doc) => PopularDestinationModel.fromMap(doc.data(), doc.id)).toList();
    } catch (_) {
      return defaultDestinations;
    }
  }

  /// Add new destination (from Admin Panel)
  static Future<void> addDestination(PopularDestinationModel destination) async {
    final ref = _firestore.collection('popular_destinations').doc();
    final data = destination.copyWith(id: ref.id).toMap();
    await ref.set(data);
  }

  /// Update destination (from Admin Panel)
  static Future<void> updateDestination(PopularDestinationModel destination) async {
    await _firestore
        .collection('popular_destinations')
        .doc(destination.id)
        .set(destination.toMap(), SetOptions(merge: true));
  }

  /// Delete destination (from Admin Panel)
  static Future<void> deleteDestination(String destinationId) async {
    await _firestore.collection('popular_destinations').doc(destinationId).delete();
  }

  /// Seed defaults if collection is empty
  static Future<void> seedDefaultDestinations() async {
    final batch = _firestore.batch();
    for (final dest in defaultDestinations) {
      final docRef = _firestore.collection('popular_destinations').doc(dest.id);
      batch.set(docRef, dest.toMap());
    }
    await batch.commit();
  }
}
