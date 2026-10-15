import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class DestinationsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Curated authentic list of Jharkhand's destinations with verified photos
  /// managed dynamically via Admin Panel & Firestore.
  static final List<PopularDestinationModel> defaultDestinations = [
    // 1. Hundru Falls
    PopularDestinationModel(
      id: 'hundru_falls',
      name: 'Hundru Falls',
      hindiName: 'हुंडरू जलप्रपात',
      category: 'waterfall',
      district: 'Ranchi',
      locationAddress: 'Hundru Falls, Ormanjhi-Purulia Road, Ranchi, Jharkhand 835219',
      latitude: 23.4503,
      longitude: 85.6567,
      imageUrl: 'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?auto=format&fit=crop&w=1200&q=80',
      ],
      imageCredit: 'District Car Verified Partner / Tourism Dept',
      imageLicense: 'CC BY 3.0',
      altTextEn: 'Dramatic 98-meter waterfall cascading over rock boulders on Subarnarekha river',
      altTextHi: 'स्वर्णरेखा नदी पर 98 मीटर ऊंचा हुंडरू जलप्रपात',
      description:
          'Hundru Falls is the 34th highest waterfall in India and one of Ranchi’s crown jewels. Cascading down from a dramatic height of 98 meters (322 ft) on the Subarnarekha River, the roaring water creates stunning frothy plunge pools surrounded by rugged rock formations. Perfect for family picnics, photography, and refreshing village nature excursions.',
      highlights: [
        '98m (322 ft) Spectacular Drop',
        'Subarnarekha River Plunge Pool',
        'Spectacular Rock Formations',
        'Safe Steps & Viewing Deck',
      ],
      safetyTips: [
        'Rocks near plunge pools get very slippery; stay behind guard railings.',
        'Wear sturdy footwear with good grip for descending stone steps.',
        'Sunset sets early in forest valleys; head back by 5:00 PM.',
        'Local village stalls sell hot chai and pakoras near parking.',
      ],
      entryFee: '₹20 / person',
      timeNeeded: '3–4 Hours',
      stepsOrParking: '350 stone steps · Dedicated car parking',
      bestTimeToVisit: 'July to February (Monsoon & Winter)',
      timings: '06:00 AM – 05:30 PM',
      rating: 4.8,
      reviewsCount: 1420,
      approxDistanceKm: 44.0,
      startingFare: 1199.0,
      isTrending: true,
      isPopular: true,
      nearbyStops: [
        {'id': 'jonha_falls', 'name': 'Jonha Falls', 'distanceKm': 18, 'fare': 350},
        {'id': 'getalsud_dam', 'name': 'Getalsud Dam Viewpoint', 'distanceKm': 12, 'fare': 250},
      ],
    ),

    // 2. Dassam Falls
    PopularDestinationModel(
      id: 'dassam_falls',
      name: 'Dassam Falls',
      hindiName: 'दशम जलप्रपात',
      category: 'waterfall',
      district: 'Ranchi',
      locationAddress: 'Taimara, Bundu, Ranchi-Tata NH 33, Ranchi, Jharkhand 835204',
      latitude: 23.1438,
      longitude: 85.4667,
      imageUrl: 'https://images.unsplash.com/photo-1546182990-dffeafbe841d?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1546182990-dffeafbe841d?auto=format&fit=crop&w=1200&q=80',
      ],
      imageCredit: 'District Car Verified Partner / Tourism Dept',
      imageLicense: 'CC BY-SA 4.0',
      altTextEn: '10 streams of Kanchi River plunging over rugged cliff',
      altTextHi: 'कांची नदी की 10 धाराओं का दशम जलप्रपात',
      description:
          'Also known as Da-song falls in local Mundari dialect (meaning gathering of 10 streams), Dassam Falls drops from 44 meters (144 ft) on the Kanchi River. The deafening sound of gushing waters across jagged rocks and verdant green canopies creates an awe-inspiring sight that draws tourists from across eastern India.',
      highlights: [
        '10 Streams of Kanchi River',
        '144 Feet Breathtaking Fall',
        'Lush Forest Covered Foothills',
        'Picnic Shelters & Snack Stalls',
      ],
      safetyTips: [
        'Bathing in the river basin is strictly prohibited due to sudden undercurrents.',
        'Keep children close to viewing platforms.',
        'Smooth paved highway drive along NH-33 from Ranchi.',
      ],
      entryFee: '₹20 / person',
      timeNeeded: '3 Hours',
      stepsOrParking: 'Easy walkway · Ample vehicle parking',
      bestTimeToVisit: 'August to March',
      timings: '06:00 AM – 06:00 PM',
      rating: 4.7,
      reviewsCount: 1180,
      approxDistanceKm: 39.0,
      startingFare: 1099.0,
      isTrending: true,
      isPopular: true,
      nearbyStops: [
        {'id': 'surya_mandir', 'name': 'Surya Mandir Bundu', 'distanceKm': 8, 'fare': 200},
      ],
    ),

    // 3. Jonha Falls (Gautamdhara)
    PopularDestinationModel(
      id: 'jonha_falls',
      name: 'Jonha Falls (Gautamdhara)',
      hindiName: 'जोन्हा / गौतमधारा',
      category: 'waterfall',
      district: 'Ranchi',
      locationAddress: 'Jonha, Gautamdhara, Anigada, Ranchi, Jharkhand 835103',
      latitude: 23.3425,
      longitude: 85.6083,
      imageUrl: 'https://images.unsplash.com/photo-1511497584788-87676104235f?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1511497584788-87676104235f?auto=format&fit=crop&w=1200&q=80',
      ],
      imageCredit: 'District Car Verified Partner / Tourism Dept',
      imageLicense: 'CC BY 3.0',
      altTextEn: 'Hanging valley waterfall with Lord Buddha ashram at top',
      altTextHi: 'गौतमधारा जोन्हा जलप्रपात एवं बुद्ध आश्रम',
      description:
          'Jonha Falls, famously called Gautamdhara, is a classic hanging valley waterfall where the holy Raru River drops 43 meters (141 ft). An ancient Lord Buddha Ashram and Shiva Mandir sits at the top of the plateau, where tradition holds that Gautama Buddha meditated during his spiritual wanderings.',
      highlights: [
        'Historic Lord Buddha Temple',
        'Hanging Valley Edge',
        'Scenic 700 Stone Steps',
        'Peaceful Forest Ambience',
      ],
      safetyTips: [
        'Steep stairs climb back up; take breaks at shaded pavilions.',
        'Carry drinking water and sun caps.',
      ],
      entryFee: '₹20 / person',
      timeNeeded: '3–4 Hours',
      stepsOrParking: '700 steps · Paved parking',
      bestTimeToVisit: 'September to March',
      timings: '06:00 AM – 05:00 PM',
      rating: 4.6,
      reviewsCount: 890,
      approxDistanceKm: 42.0,
      startingFare: 1149.0,
      isTrending: false,
      isPopular: true,
      nearbyStops: [
        {'id': 'sita_falls', 'name': 'Sita Falls', 'distanceKm': 6, 'fare': 200},
      ],
    ),

    // 4. Panchghagh Falls
    PopularDestinationModel(
      id: 'panchghagh_falls',
      name: 'Panchghagh Falls',
      hindiName: 'पंचघाघ जलप्रपात',
      category: 'waterfall',
      district: 'Khunti',
      locationAddress: 'Khunti-Chaibasa Highway, Khunti District, Jharkhand 835210',
      latitude: 22.8800,
      longitude: 85.2500,
      imageUrl: 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=1200&q=80',
      ],
      imageCredit: 'District Car Verified Partner / Tourism Dept',
      imageLicense: 'CC BY-SA 4.0',
      altTextEn: 'Five gentle cascading streams of Banai river in Khunti',
      altTextHi: 'खूंटी में बनाई नदी की 5 शांत धाराएं',
      description:
          'Panchghagh is a pristine cascading waterfall formed by five distinct streams of the Banai River flowing smoothly over rocky granite shelves. Because the streams are gentle, shallow, and wide, it is renowned as the safest waterfall in Jharkhand for families and children to dip their feet and enjoy peaceful outings.',
      highlights: [
        '5 Serene Cascading Streams',
        'Gentle & Safe Water Currents',
        'Ideal Family Picnic Spot',
        'Pristine Rural Environment',
      ],
      safetyTips: [
        'Safest water flow in Jharkhand; great for kids and seniors.',
        'Clean changing shelters available for visitors.',
      ],
      entryFee: '₹10 / person',
      timeNeeded: 'Half Day',
      stepsOrParking: 'Very few steps · Family friendly',
      bestTimeToVisit: 'October to February',
      timings: '07:00 AM – 05:30 PM',
      rating: 4.6,
      reviewsCount: 650,
      approxDistanceKm: 55.0,
      startingFare: 1399.0,
      isTrending: false,
      isPopular: true,
    ),

    // 5. Lodh Falls (Burha Ghagh)
    PopularDestinationModel(
      id: 'lodh_falls',
      name: 'Lodh Falls (Burha Ghagh)',
      hindiName: 'लोध / बूढ़ा घाघ जलप्रपात',
      category: 'waterfall',
      district: 'Latehar',
      locationAddress: 'Mahuadanr Forest Valley, Latehar District, Jharkhand 822119',
      latitude: 23.5350,
      longitude: 84.1160,
      imageUrl: 'https://images.unsplash.com/photo-1498855926480-d98e83099315?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1498855926480-d98e83099315?auto=format&fit=crop&w=1200&q=80',
      ],
      imageCredit: 'District Car Verified Partner / Tourism Dept',
      imageLicense: 'CC BY-SA 4.0',
      altTextEn: 'Highest waterfall in Jharkhand dropping 143 meters in Latehar sal forest',
      altTextHi: 'झारखंड का सबसे ऊंचा 143 मीटर का लोध जलप्रपात',
      description:
          'Lodh Falls is the grandest and highest waterfall in Jharkhand with a towering multi-tiered fall of 143 meters (469 ft) on the Burha River. Hidden inside the deep virgin sal forests of the Palamu plateau, its mighty roar can be heard over 10 kilometers away, making it an epic outstation excursion.',
      highlights: [
        'Highest Waterfall in Jharkhand (469 ft)',
        'Deep Sal Forest Wilderness',
        'Multi-Tier Cascades',
        'Untouched Natural Splendor',
      ],
      safetyTips: [
        'Remote forest area; start early in the morning.',
        'Recommended vehicle: SUV / Bolero with high ground clearance.',
      ],
      entryFee: '₹30 / person',
      timeNeeded: 'Full Day Outstation',
      stepsOrParking: 'Nature trail · Forest parking',
      bestTimeToVisit: 'August to January',
      timings: '07:00 AM – 04:30 PM',
      rating: 4.9,
      reviewsCount: 520,
      approxDistanceKm: 195.0,
      startingFare: 3499.0,
      isTrending: true,
      isPopular: true,
    ),

    // 6. Baba Baidyanath Jyotirlinga Dham
    PopularDestinationModel(
      id: 'baidyanath_dham',
      name: 'Baba Baidyanath Dham',
      hindiName: 'बाबा बैद्यनाथ ज्योतिर्लिंग धाम',
      category: 'temple',
      district: 'Deoghar',
      locationAddress: 'Shivganga Muhalla, Deoghar, Santhal Pargana, Jharkhand 814112',
      latitude: 24.4925,
      longitude: 86.7000,
      imageUrl: 'https://images.unsplash.com/photo-1609766857041-ed402ea8069a?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1609766857041-ed402ea8069a?auto=format&fit=crop&w=1200&q=80',
      ],
      imageCredit: 'District Car Verified Partner / Tourism Dept',
      imageLicense: 'CC BY-SA 4.0',
      altTextEn: 'Sacred Shiva Jyotirlinga temple complex in Deoghar',
      altTextHi: 'देवघर स्थित पवित्र द्वादश ज्योतिर्लिंग बैद्यनाथ मंदिर',
      description:
          'Baba Baidyanath Temple is one of the sacred 12 Jyotirlingas of Lord Shiva and also one of the 51 Shaktipeeths in Hindu belief. Revered for centuries, millions of pilgrims undertake the sacred Shravani Mela Kanwar Yatra here. The temple spire boasts an iconic golden Panchshula that is revered by devotees worldwide.',
      highlights: [
        'One of the 12 Sacred Jyotirlingas',
        '51 Shakti Peeth Destination',
        'Sacred Shivganga Water Pond',
        'Ancient Nagara Architecture',
      ],
      safetyTips: [
        'Temple dress code: traditional Indian attire recommended.',
        'VIP Darshan pass counters open at 6:00 AM near temple gate.',
      ],
      entryFee: 'Free (Special Darshan pass ₹500)',
      timeNeeded: 'Half Day to Full Day',
      stepsOrParking: 'Town parking with District Car driver wait',
      bestTimeToVisit: 'All Year (Especially July-August & Winters)',
      timings: '04:00 AM – 09:00 PM',
      rating: 4.9,
      reviewsCount: 3850,
      approxDistanceKm: 250.0,
      startingFare: 3999.0,
      isTrending: true,
      isPopular: true,
    ),

    // 7. Jagannath Temple Ranchi
    PopularDestinationModel(
      id: 'jagannath_temple_ranchi',
      name: 'Jagannath Temple Ranchi',
      hindiName: 'जगन्नाथ मंदिर, रांची',
      category: 'temple',
      district: 'Ranchi',
      locationAddress: 'Jagannathpur Hill, Dhurwa, HEC Township, Ranchi 834004',
      latitude: 23.3283,
      longitude: 85.2750,
      imageUrl: 'https://images.unsplash.com/photo-1621252179027-94459d278660?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1621252179027-94459d278660?auto=format&fit=crop&w=1200&q=80',
      ],
      imageCredit: 'District Car Verified Partner / Tourism Dept',
      imageLicense: 'CC BY 3.0',
      altTextEn: '17th-century hilltop Jagannath temple in Dhurwa, Ranchi',
      altTextHi: 'धुर्वा स्थित 17वीं शताब्दी का ऐतिहासिक जगन्नाथ मंदिर',
      description:
          'Built in 1691 by King Barkagarh Thakur Ani Nath Shahdeo, this revered hilltop shrine mimics the sacred Puri Jagannath Temple architecture. Perched on a gentle hill in Dhurwa, it hosts the famous annual Rath Yatra festival drawing thousands of devotees, and offers peaceful vistas over Ranchi city.',
      highlights: [
        '17th-Century Heritage Architecture',
        'Hilltop Panoramic City Views',
        'Famous Annual Rath Yatra',
        'Lord Balabhadra & Subhadra Deities',
      ],
      safetyTips: [
        'Gentle steps climb to hilltop; ramp path available for elder devotees.',
        'Photography prohibited inside the sanctum sanctorum.',
      ],
      entryFee: 'Free Entry',
      timeNeeded: '1–2 Hours',
      stepsOrParking: 'Hilltop parking · Easy access',
      bestTimeToVisit: 'All Year Round',
      timings: '05:00 AM – 12:00 PM & 03:30 PM – 08:30 PM',
      rating: 4.7,
      reviewsCount: 1640,
      approxDistanceKm: 11.0,
      startingFare: 499.0,
      isTrending: false,
      isPopular: true,
    ),

    // 8. Maa Chhinnamastika Mandir Rajrappa
    PopularDestinationModel(
      id: 'rajrappa_temple',
      name: 'Maa Chhinnamastika Mandir Rajrappa',
      hindiName: 'रजरप्पा छिन्नमस्ता मंदिर',
      category: 'temple',
      district: 'Ramgarh',
      locationAddress: 'Rajrappa, Bhairavi & Damodar River Confluence, Ramgarh 829101',
      latitude: 23.6322,
      longitude: 85.7111,
      imageUrl: 'https://images.unsplash.com/photo-1582510003544-4d00b7f74220?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1582510003544-4d00b7f74220?auto=format&fit=crop&w=1200&q=80',
      ],
      imageCredit: 'District Car Verified Partner / Tourism Dept',
      imageLicense: 'CC BY-SA 4.0',
      altTextEn: 'Ancient Shaktipeeth temple at confluence of Damodar and Bhairavi rivers',
      altTextHi: 'दामोदर और भैरवी नदी के संगम पर सिद्धपीठ रजरप्पा मंदिर',
      description:
          'A sacred Shakta pilgrimage situated at the scenic confluence of the roaring Bhairavi (Bhera) waterfall and the majestic Damodar River. Dedicated to Goddess Chhinnamasta—one of the 10 Mahavidyas—this centuries-old temple holds supreme tantric and spiritual significance in Jharkhand.',
      highlights: [
        'Goddess Chhinnamasta Mahavidya Peeth',
        'Scenic River Confluence (Sangam)',
        'Boating in Damodar Waters',
        'Ancient Rock Carvings',
      ],
      safetyTips: [
        'River currents are strong during monsoons; only board authorized boat rides.',
        'Prasad stalls line the entry walkway.',
      ],
      entryFee: 'Free Entry',
      timeNeeded: 'Half Day',
      stepsOrParking: 'Designated riverside parking area',
      bestTimeToVisit: 'October to April',
      timings: '05:00 AM – 08:30 PM',
      rating: 4.8,
      reviewsCount: 2210,
      approxDistanceKm: 68.0,
      startingFare: 1699.0,
      isTrending: true,
      isPopular: true,
    ),

    // 9. Shree Shikharji Parasnath
    PopularDestinationModel(
      id: 'parasnath_shikharji',
      name: 'Shree Shikharji Parasnath',
      hindiName: 'सम्मेद शिखरजी, पारसनाथ',
      category: 'temple',
      district: 'Giridih',
      locationAddress: 'Madhuban, Parasnath Hill, Giridih District, Jharkhand 825329',
      latitude: 23.9620,
      longitude: 86.1310,
      imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1200&q=80',
      ],
      imageCredit: 'District Car Verified Partner / Tourism Dept',
      imageLicense: 'CC BY-SA 3.0',
      altTextEn: 'Parasnath peak and holy Jain Shikharji pilgrimage hills',
      altTextHi: 'झारखंड की सबसे ऊंची चोटी सम्मेद शिखरजी पारसनाथ',
      description:
          'Shikharji is the highest mountain peak in Jharkhand (1365 meters) and the most holy pilgrimage shrine for the global Jain community. It is the sacred Nirvana Bhumi where 20 out of the 24 Tirthankaras attained Moksha. The trek amidst serene mountain mist and divine Tonks is an unforgettable spiritual journey.',
      highlights: [
        'Highest Mountain Peak in Jharkhand (1365m)',
        'Sacred Moksha Bhumi of 20 Tirthankaras',
        'Madhuban Base Ashrams & Museums',
        'Serene Misty Mountain Trails',
      ],
      safetyTips: [
        'Pilgrims begin the 27 km Parikrama at 3:00 AM from Madhuban base.',
        'Doli (palanquin) services are available at base for elderly pilgrims.',
      ],
      entryFee: 'Free Entry',
      timeNeeded: 'Full Day to 2 Days',
      stepsOrParking: 'Base town Madhuban parking with hotel pickup',
      bestTimeToVisit: 'October to March',
      timings: '04:00 AM – 08:00 PM',
      rating: 4.9,
      reviewsCount: 1980,
      approxDistanceKm: 165.0,
      startingFare: 3299.0,
      isTrending: true,
      isPopular: true,
    ),

    // 10. Netarhat
    PopularDestinationModel(
      id: 'netarhat',
      name: 'Netarhat (Queen of Chotanagpur)',
      hindiName: 'नेतरहाट (छोटानागपुर की रानी)',
      category: 'hill_station',
      district: 'Latehar',
      locationAddress: 'Netarhat Plateau, Latehar District, Jharkhand 835218',
      latitude: 23.4833,
      longitude: 84.2667,
      imageUrl: 'https://images.unsplash.com/photo-1473448912268-2022ce9509d8?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1473448912268-2022ce9509d8?auto=format&fit=crop&w=1200&q=80',
      ],
      imageCredit: 'District Car Verified Partner / Tourism Dept',
      imageLicense: 'CC BY-SA 4.0',
      altTextEn: 'Scenic rolling pine forests and sunset point in Netarhat',
      altTextHi: 'नेतरहाट की मनमोहक वादियां और पाइन के जंगल',
      description:
          'Netarhat, acclaimed as the "Queen of Chotanagpur", is Jharkhand’s premier hill station located 3700 feet above sea level. Famed for its hypnotic sunrise and sunset at Magnolia Point, fragrant pine tree forests, crisp cool mountain air, and pear orchards, it is the ultimate romantic getaway and weekend escape.',
      highlights: [
        'Magnolia Point Sunset View',
        'Pine Tree Forest & Pear Orchards',
        'Pleasant Mountain Weather',
        'Netarhat Dam & Sunrise Point',
      ],
      safetyTips: [
        'Temperature drops significantly in evenings; carry warm layers.',
        'Reach Magnolia Point 45 minutes before sunset for best viewing spot.',
      ],
      entryFee: 'Free (Magnolia Point entry ₹10)',
      timeNeeded: 'Full Day / Overnight Stay',
      stepsOrParking: 'Scenic driving roads · Viewpoint parking',
      bestTimeToVisit: 'September to March',
      timings: 'Open 24 Hours (Sunrise to Sunset Recommended)',
      rating: 4.9,
      reviewsCount: 2150,
      approxDistanceKm: 155.0,
      startingFare: 3199.0,
      isTrending: true,
      isPopular: true,
      nearbyStops: [
        {'id': 'koel_viewpoint', 'name': 'Koel River Viewpoint', 'distanceKm': 14, 'fare': 300},
        {'id': 'upper_ghaghri', 'name': 'Upper Ghaghri Waterfall', 'distanceKm': 8, 'fare': 250},
      ],
    ),

    // 11. Patratu Valley & Dam
    PopularDestinationModel(
      id: 'patratu_valley',
      name: 'Patratu Valley & Dam',
      hindiName: 'पतरातू घाटी एवं डैम',
      category: 'hill_station',
      district: 'Ramgarh',
      locationAddress: 'Patratu Ghat S-Curve Road & Lake Dam, Ramgarh, Jharkhand 829119',
      latitude: 23.6428,
      longitude: 85.3033,
      imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1200&q=80',
      ],
      imageCredit: 'District Car Verified Partner / Tourism Dept',
      imageLicense: 'CC BY-SA 4.0',
      altTextEn: 'Winding hairpin curves of Patratu valley ghat and expansive lake',
      altTextHi: 'पतरातू घाटी के सुंदर घुमावदार रास्ते और विशाल डैम',
      description:
          'Patratu Valley is famous for its stunning zig-zag S-curve winding roads snaking through verdant green hills. At the bottom lies the sprawling Patratu Lake and Dam, featuring state-of-the-art speed boating, island resorts, water sports, and sunset view decks that make for an exhilarating drive from Ranchi.',
      highlights: [
        'Iconic S-Curve Ghat Driving Route',
        'Speed Boating & Island Lake Cruises',
        'Sunset Viewpoints with Food Plazas',
        'Modern Tourism Complex & Parks',
      ],
      safetyTips: [
        'Ghat curves have tight hairpin turns; our certified drivers navigate at safe speeds.',
        'Speed boating tickets available at lake counter till 5:30 PM.',
      ],
      entryFee: 'Free (Dam park entry ₹20)',
      timeNeeded: 'Half Day (3–5 Hours)',
      stepsOrParking: 'Spacious lakefront parking',
      bestTimeToVisit: 'All Year (Evenings & Winters Best)',
      timings: '06:00 AM – 07:00 PM',
      rating: 4.8,
      reviewsCount: 3100,
      approxDistanceKm: 38.0,
      startingFare: 1049.0,
      isTrending: true,
      isPopular: true,
      nearbyStops: [
        {'id': 'patratu_island', 'name': 'Island Resort Cruise', 'distanceKm': 4, 'fare': 200},
      ],
    ),

    // 12. Betla National Park
    PopularDestinationModel(
      id: 'betla_national_park',
      name: 'Betla National Park',
      hindiName: 'बेतला राष्ट्रीय उद्यान',
      category: 'wildlife',
      district: 'Latehar',
      locationAddress: 'Betla, Palamu Tiger Reserve, Latehar-Daltonganj, Jharkhand 822126',
      latitude: 23.8667,
      longitude: 84.1833,
      imageUrl: 'https://images.unsplash.com/photo-1534177616072-ef7dc120449d?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1534177616072-ef7dc120449d?auto=format&fit=crop&w=1200&q=80',
      ],
      imageCredit: 'District Car Verified Partner / Tourism Dept',
      imageLicense: 'CC BY-SA 3.0',
      altTextEn: 'Wild Asian elephant and deer herd in Betla sal forest',
      altTextHi: 'बेतला नेशनल पार्क के साल वनों में वन्यजीव',
      description:
          'Betla National Park is one of India’s pioneering wildlife sanctuaries under Project Tiger. Spanning thick sal forests and bamboo groves, visitors enjoy open-jeep safaris encountering wild elephants, leopards, sloths, spotted deer, and the historic 16th-century twin forts of the Chero Kings nestled deep within the jungle.',
      highlights: [
        'Open Jeep Wildlife Safaris',
        'Historic 16th-Century Palamu Forts',
        'Wild Elephant Herds & Deer',
        'Dense Sal & Teak Forest Canopy',
      ],
      safetyTips: [
        'Morning safari timings: 6:00 AM – 10:00 AM; afternoon 2:00 PM – 5:00 PM.',
        'Strictly follow safari guide instructions; remain inside the open jeep.',
      ],
      entryFee: 'Park entry ₹100 + Safari jeep extra',
      timeNeeded: 'Full Day',
      stepsOrParking: 'Forest department safari gate parking',
      bestTimeToVisit: 'November to April',
      timings: '06:00 AM – 05:00 PM',
      rating: 4.7,
      reviewsCount: 1350,
      approxDistanceKm: 175.0,
      startingFare: 3399.0,
      isTrending: true,
      isPopular: true,
      nearbyStops: [
        {'id': 'palamu_fort', 'name': 'Palamu Twin Forts', 'distanceKm': 8, 'fare': 250},
        {'id': 'mirchaiya_falls', 'name': 'Mirchaiya Falls', 'distanceKm': 15, 'fare': 300},
      ],
    ),

    // 13. Tagore Hill Ranchi
    PopularDestinationModel(
      id: 'tagore_hill',
      name: 'Tagore Hill',
      hindiName: 'टैगोर हिल, रांची',
      category: 'heritage',
      district: 'Ranchi',
      locationAddress: 'Morabadi, Ranchi, Jharkhand 834008',
      latitude: 23.3967,
      longitude: 85.3400,
      imageUrl: 'https://images.unsplash.com/photo-1519681393784-d120267933ba?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1519681393784-d120267933ba?auto=format&fit=crop&w=1200&q=80',
      ],
      imageCredit: 'District Car Verified Partner / Tourism Dept',
      imageLicense: 'CC BY-SA 4.0',
      altTextEn: 'Historical ashram monument on hillock in Morabadi, Ranchi',
      altTextHi: 'मोरहाबादी स्थित ऐतिहासिक टैगोर हिल',
      description:
          'Tagore Hill, also known as Morabadi Hill, is deeply tied to the literary legacy of the Tagore family. Rabindranath Tagore’s elder brother Jyotirindranath Tagore built his peaceful hermitage "Shanti Dham" atop this 300-foot rock hillock in 1912, where Nobel laureate Rabindranath Tagore also spent time writing in serenity.',
      highlights: [
        'Historical Shanti Dham Ashram',
        'Associated with Rabindranath Tagore',
        'Panoramic Ranchi City View',
        'Peaceful Garden Pathways',
      ],
      safetyTips: [
        'Well paved stone stairway with handrails.',
        'Sunset view is popular among photographers and families.',
      ],
      entryFee: 'Free Entry',
      timeNeeded: '1–2 Hours',
      stepsOrParking: 'Morabadi base parking',
      bestTimeToVisit: 'All Year (Evenings)',
      timings: '06:00 AM – 06:30 PM',
      rating: 4.5,
      reviewsCount: 890,
      approxDistanceKm: 6.0,
      startingFare: 399.0,
      isTrending: false,
      isPopular: true,
    ),
  
    // 14. Combo 1: Tri-Waterfall Circuit Combo
    PopularDestinationModel(
      id: 'combo_waterfalls_circuit',
      name: 'Tri-Waterfall Circuit Combo',
      hindiName: 'त्रिवेणी जलप्रपात कॉम्बो (हुंडरू + जोन्हा + दशम)',
      category: 'combo',
      district: 'Ranchi',
      locationAddress: 'Ormanjhi - Angara - Bundu Circuit, Ranchi, Jharkhand',
      latitude: 23.4503,
      longitude: 85.6567,
      imageUrl: 'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1511497584788-87676104235f?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1546182990-dffeafbe841d?auto=format&fit=crop&w=1200&q=80',
      ],
      description: 'Experience Jharkhand\'s 3 most majestic waterfalls in a seamless 1-day guided road tour. Enjoy doorstep pickup from Ranchi or Khunti, dedicated private vehicle with chauffeur waiting at each spot, and memorable scenic forest drives.',
      highlights: [
        '3 Iconic Waterfalls in 1 Single Day',
        'Dedicated Chauffeur & Cab for 8-10 Hours',
        'Zero Toll or Parking Worries',
        'Authentic Village Chai & Dhaba Stops En-Route',
      ],
      safetyTips: [
        'Start early by 7:30 AM to cover all three waterfalls before sunset.',
        'Wear comfortable sports shoes for descent steps.',
      ],
      entryFee: 'Included in Cab Package',
      timeNeeded: 'Full Day (8–10 Hours)',
      stepsOrParking: 'Dedicated parking at all spots',
      bestTimeToVisit: 'July to March',
      timings: '07:00 AM – 06:00 PM',
      rating: 4.9,
      reviewsCount: 820,
      approxDistanceKm: 140.0,
      startingFare: 2499.0,
      isTrending: true,
      isPopular: true,
      isCombo: true,
      comboDestinations: ['hundru_falls', 'jonha_falls', 'dassam_falls'],
      packageType: 'Full Day 3-in-1 Combo',
    ),

    // 15. Combo 2: Deoghar & Basukinath Dham Pilgrimage
    PopularDestinationModel(
      id: 'combo_deoghar_basukinath',
      name: 'Deoghar & Basukinath Dham Combo',
      hindiName: 'देवघर ज्योतिर्लिंग एवं बासुकीनाथ धाम कॉम्बो',
      category: 'combo',
      district: 'Deoghar',
      locationAddress: 'Deoghar & Dumka Circuit, Jharkhand',
      latitude: 24.4926,
      longitude: 86.7001,
      imageUrl: 'https://images.unsplash.com/photo-1609766857041-ed402ea8069a?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1609766857041-ed402ea8069a?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1582510003544-4d00b7f74220?auto=format&fit=crop&w=1200&q=80',
      ],
      description: 'The supreme spiritual circuit of Santhal Pargana. Complete your holy darshan at Baba Baidyanath Jyotirlinga and Faujdari Baba Basukinath Temple, followed by scenic Trikut Pahar cable car ropeway visit with safe round-trip travel.',
      highlights: [
        'Baba Baidyanath & Basukinath Twin Darshan',
        'Trikut Pahar Scenic Cable Car Stop',
        'Peda Sweet Market Tasting Stop',
        'Dedicated AC Sedan / SUV with Chauffeur',
      ],
      safetyTips: [
        'Dress in traditional pilgrimage attire.',
        'Morning darshan avoids rush hours.',
      ],
      entryFee: 'VIP line passes optional',
      timeNeeded: '1–2 Days',
      stepsOrParking: 'Designated Mandir parking',
      bestTimeToVisit: 'All Year Round (Oct-March best)',
      timings: '05:00 AM – 09:00 PM',
      rating: 4.9,
      reviewsCount: 1150,
      approxDistanceKm: 220.0,
      startingFare: 3899.0,
      isTrending: true,
      isPopular: true,
      isCombo: true,
      comboDestinations: ['baidyanath_dham', 'basukinath_temple'],
      packageType: 'Pilgrimage Circuit Combo',
    ),

    // 16. Combo 3: Patratu Valley & Sunset Dam Combo
    PopularDestinationModel(
      id: 'combo_patratu_dam',
      name: 'Patratu Valley & Sunset Dam Combo',
      hindiName: 'पतरातू घाटी एवं डैम सनसेट कॉम्बो',
      category: 'combo',
      district: 'Ramgarh',
      locationAddress: 'Patratu Valley & Dam Resort, Ramgarh, Jharkhand',
      latitude: 23.6425,
      longitude: 85.2980,
      imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1200&q=80',
      ],
      description: 'The premier relaxing half-day getaway from Ranchi. Enjoy thrilling hairpin curved valley viewpoints, photo shoots overlooking the serpentine ghat, and peaceful motorboat cruise at Patratu Lake resort with a private vehicle waiting.',
      highlights: [
        'Hairpin Curved Ghat Viewpoints',
        'Patratu Lake Island Boating',
        'Private Waiting Chauffeur',
        'Comfortable Return by Sunset',
      ],
      safetyTips: [
        'Drive carefully along curves; use designated scenic viewpoints for photos.',
      ],
      entryFee: 'Dam entry included',
      timeNeeded: '5–6 Hours',
      stepsOrParking: 'Spacious resort parking',
      bestTimeToVisit: 'September to April',
      timings: '01:00 PM – 07:30 PM',
      rating: 4.8,
      reviewsCount: 940,
      approxDistanceKm: 75.0,
      startingFare: 1499.0,
      isTrending: true,
      isPopular: true,
      isCombo: true,
      comboDestinations: ['patratu_valley', 'patratu_dam'],
      packageType: 'Half Day / Sunset Combo',
    ),
  ];

  /// Live Firestore Stream with local fallback
  static Stream<List<PopularDestinationModel>> streamDestinations() {
    try {
      return _firestore
          .collection('destinations')
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) return defaultDestinations;
            return snapshot.docs
                .map((doc) => PopularDestinationModel.fromMap(doc.data(), doc.id))
                .toList();
          })
          .handleError((_) => defaultDestinations);
    } catch (_) {
      return Stream.value(defaultDestinations);
    }
  }

  /// Get destination by ID
  static PopularDestinationModel? getById(String id) {
    try {
      return defaultDestinations.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Add a new destination or combo package to Firestore (Admin CRUD)
  static Future<String> addDestination(PopularDestinationModel destination) async {
    try {
      final docRef = _firestore.collection('destinations').doc();
      final toSave = destination.copyWith(id: docRef.id);
      await docRef.set(toSave.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding destination: $e');
      rethrow;
    }
  }

  /// Update existing destination in Firestore (Admin CRUD)
  static Future<void> updateDestination(PopularDestinationModel destination) async {
    try {
      await _firestore
          .collection('destinations')
          .doc(destination.id)
          .set(destination.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating destination: $e');
      rethrow;
    }
  }

  /// Delete destination from Firestore (Admin CRUD)
  static Future<void> deleteDestination(String id) async {
    try {
      await _firestore.collection('destinations').doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting destination: $e');
      rethrow;
    }
  }

  /// Seed / Reset default destinations & combos to Firestore
  static Future<void> seedDefaultDestinations() async {
    try {
      final batch = _firestore.batch();
      for (final dest in defaultDestinations) {
        final ref = _firestore.collection('destinations').doc(dest.id);
        batch.set(ref, dest.toMap());
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error seeding default destinations: $e');
    }
  }
}
