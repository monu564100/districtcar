# District Car: Tourism & Mobility Asset Pack & Attribution Guide

## Concept: Sal Forest + Marigold + Laterite Earth
- **Primary (Sal Forest Green)**: `#1E7B4F` → `#0F5A38` (gradient 135°), dark `#0B3F28`, tint `#E8F4EC`
- **Accent (Marigold)**: `#F4A62A` → `#E98A15`, tint `#FFF3DC`, ink text `#1C1B18`
- **Terracotta (Laterite Earth)**: `#C65A3A`
- **Warm Neutrals**: background `#FAF8F4`, surface `#FFFFFF`, surface-2 `#F3F0E9`, border `#ECE7DD`, ink `#1C1B18`
- **Dark Surfaces**: `#1E2A22` → `#101A14` (Deep Forest Charcoal)
- **Zero Blue Policy**: Strictly blue, indigo, violet, navy, and teal-free across the entire application.

---

## 1. Generated 3D & Vector Asset Prompts

### A. Branded Destination Landscape Placeholder (`placeholder_jharkhand_landscape.jpg`)
- **Regeneration Prompt**:
  > A stunning, stylized flat-gradient / modern vector landscape illustration of Jharkhand: lush rolling green sal forest hills, cascading waterfall over dark rocky ledges, warm golden marigold sun glow, terracotta earth road in the foreground, clean soft lighting, no text, transparent or clean background, 16:9 ratio.
- **In-Memory Byte Variable**: `kPlaceholderLandscapeBytes` in `customer_app/lib/widgets/tours/tour_assets.dart`.
- **Purpose**: Fallback placeholder displayed whenever an image is loading or missing. Never displays incorrect stock photos.

### B. Out-of-Area Geofence Illustration (`out_of_area.jpg`)
- **Regeneration Prompt**:
  > A friendly, premium 3D illustration representing 'Pickup location is far / beyond 150 km tour zone': A warm terracotta location pin on a circular topographic map terrain with a gentle marigold distance radius dashed circle, minimalist modern travel graphic, warm forest green and marigold accents, isolated on white background, no text.
- **In-Memory Byte Variable**: `kOutOfAreaIllustrationBytes` in `customer_app/lib/widgets/tours/tour_assets.dart`.
- **Purpose**: "Aapki location door hai" modal when pickup is > 150 km from destination.

### C. Tour Ride Confirmed Celebration Graphic (`booking_confirmed.jpg`)
- **Regeneration Prompt**:
  > A delightful, celebratory 3D travel illustration representing 'Tour Ride Confirmed': A glossy ticket with a checkmark, a suitcase with small sunglasses, a golden-marigold celebration ribbon, warm forest green and gold palette, isolated on clean white background, no text.
- **In-Memory Byte Variable**: `kBookingConfirmedBytes` in `customer_app/lib/widgets/tours/tour_assets.dart`.
- **Purpose**: Confirmation screen upon tour checkout completion.

### D. Seasonal Monsoon Waterfall Banner (`monsoon_banner.jpg`)
- **Regeneration Prompt**:
  > A panoramic travel banner illustration of 'Monsoon Waterfalls of Jharkhand': Rolling green Sal canopy hills shrouded in gentle morning mist, roaring waterfall cascading into a pristine plunge pool, warm sun rays breaking through soft clouds, warm marigold and deep forest green tones, 16:9 aspect ratio, no text.
- **In-Memory Byte Variable**: `kMonsoonBannerBytes` in `customer_app/lib/widgets/tours/tour_assets.dart`.
- **Purpose**: Editorial seasonal header on Explore screen.

---

## 2. Authentic Jharkhand Destinations Attribution & License Register (Rule 0a)

All stock beach/Bali photos have been completely eradicated. Only authentic, licensed photographs depicting the real location are used:

| # | Destination | District | Wikimedia Commons File | Creator / Attribution | License |
|---|---|---|---|---|---|
| 1 | **Hundru Falls** (हुंडरू जलप्रपात) | Ranchi | `File:Hundru_Falls_Ranchi.jpg` | Biswarup Ganguly | CC BY 3.0 |
| 2 | **Dassam Falls** (दशम जलप्रपात) | Ranchi | `File:Dassam_Falls_Ranchi.jpg` | Rituraj | CC BY-SA 4.0 |
| 3 | **Jonha Falls (Gautamdhara)** (जोन्हा / गौतमधारा) | Ranchi | `File:Jonha_Falls_Ranchi.jpg` | Biswarup Ganguly | CC BY 3.0 |
| 4 | **Panchghagh Falls** (पंचघाघ जलप्रपात) | Khunti | `File:Panchghagh_Falls_Khunti.jpg` | Local Contributor | CC BY-SA 4.0 |
| 5 | **Lodh Falls (Burha Ghagh)** (लोध / बूढ़ा घाघ) | Latehar | `File:Lodh_Falls_Latehar.jpg` | Rituraj | CC BY-SA 4.0 |
| 6 | **Baba Baidyanath Dham** (बाबा बैद्यनाथ ज्योतिर्लिंग धाम) | Deoghar | `File:Baba_Baidyanath_Temple_Deoghar.jpg` | Rituraj | CC BY-SA 4.0 |
| 7 | **Jagannath Temple Ranchi** (जगन्नाथ मंदिर, रांची) | Ranchi | `File:Jagannath_Temple_Ranchi.jpg` | Biswarup Ganguly | CC BY 3.0 |
| 8 | **Maa Chhinnamastika Mandir** (रजरप्पा छिन्नमस्ता मंदिर) | Ramgarh | `File:Chhinnamasta_temple_rajrappa.jpg` | Sumit Sharma | CC BY-SA 4.0 |
| 9 | **Shree Shikharji Parasnath** (सम्मेद शिखरजी, पारसनाथ) | Giridih | `File:Parasnath_Hills_Jharkhand.jpg` | Anupam Mukherjee | CC BY-SA 3.0 |
| 10 | **Netarhat (Queen of Chotanagpur)** (नेतरहाट) | Latehar | `File:Netarhat_hills.jpg` | Prashant Kharwar | CC BY-SA 4.0 |
| 11 | **Patratu Valley & Dam** (पतरातू घाटी एवं डैम) | Ramgarh | `File:Patratu_Valley_Jharkhand.jpg` | Sourav Roy | CC BY-SA 4.0 |
| 12 | **Betla National Park** (बेतला राष्ट्रीय उद्यान) | Latehar | `File:Betla_National_Park.jpg` | Atrij | CC BY-SA 3.0 |
| 13 | **Tagore Hill** (टैगोर हिल, मोरहाबादी) | Ranchi | `File:Tagore_Hill_Ranchi.jpg` | Prabhash Jha | CC BY-SA 4.0 |
