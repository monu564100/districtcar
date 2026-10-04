# District Car — Production-Ready Ride/Vehicle Booking Platform

District Car is an enterprise-grade ride-hailing and logistics platform built with Flutter and Firebase. The system is architected as a clean monorepo comprising customer and driver mobile apps, an administrative operations dashboard, and secure Firebase Cloud Functions.

---

## 1. Project Architecture

```
district_car/
│
├── customer_app/             # Flutter Customer Application (iOS / Android)
├── driver_app/               # Flutter Driver Application (iOS / Android)
├── admin_panel/              # Flutter Web Operations & Admin Console
├── functions/                # TypeScript Cloud Functions Backend
├── shared/                   # Shared Dart package (Models, Theme, Enums, Constants)
├── firebase/                 # Firestore rules, Storage rules, and Composite Indexes
├── .env.example              # Environment configuration template
└── README.md
```

---

## 2. System Features & Flow

### 📱 Customer Mobile App
* **UI/UX Reference Match**: Ultra-modern soft periwinkle background (`#E4E7FD`), rounded cards, custom category selection, origin/destination inputs, and floating bottom navigation dock.
* **Authentication**: Firebase Phone Authentication with OTP verification and profile creation.
* **Booking Lifecycle**: Live fare estimation via Cloud Functions, driver search with 25s timeouts, real-time live map tracking, and 4-digit ride OTP verification.
* **Ratings**: 1–5 star driver rating with backend aggregation.

### 🚗 Driver Mobile App
* **Partner Onboarding**: Mandatory legal registration and live vehicle photo captured strictly via device camera.
* **Online/Offline Engine**: Large interactive state toggle updating geohash coordinates and driver availability.
* **Request Acceptance**: Real-time incoming overlay with countdown, server-side transaction protection against race conditions.
* **Trip Workflow**: Arrived -> Verify Ride OTP -> Trip Started -> Complete Trip -> Cash collection.

### 🖥️ Admin Operations Web Panel
* **Responsive Web Dashboard**: Real-time platform KPI cards, active trips, gross revenue, and pending driver applications.
* **Driver Partner Verification**: Review live vehicle photos and approve/reject driver access.
* **Rate Cards & Fares**: Live configuration of base fares, per-kilometer rates, and minimum fare thresholds.

### ⚡ Cloud Functions Backend
* **Transactional Driver Assignment**: Atomic Firestore transactions preventing race conditions when multiple drivers respond.
* **Geospatial Engine**: Haversine formula calculation, geohashing, and dynamic radius expansion (5 km -> 10 km -> 15 km).
* **Push Notifications**: Automated FCM delivery for booking updates, driver assignments, arrival, and completion.

---

## 3. Getting Started & Running Locally

### Prerequisites
* Flutter SDK (3.10+)
* Node.js (18+) & npm
* Firebase CLI (`npm install -g firebase-tools`)

### Step 1: Install Cloud Functions Dependencies & Test
```bash
cd functions
npm install
npm test
npm run build
```

### Step 2: Configure Firebase
1. Log in to Firebase CLI:
   ```bash
   firebase login
   ```
2. Initialize or link your project:
   ```bash
   firebase use --add
   ```
3. Deploy Firestore rules, Storage rules, and indexes:
   ```bash
   firebase deploy --only firestore:rules,firestore:indexes,storage
   ```
4. Deploy Cloud Functions:
   ```bash
   firebase deploy --only functions
   ```

### Step 3: Run Flutter Applications

**Run Customer App:**
```bash
cd customer_app
flutter pub get
flutter run
```

**Run Driver App:**
```bash
cd driver_app
flutter pub get
flutter run
```

**Run Admin Web Panel:**
```bash
cd admin_panel
flutter pub get
flutter run -d chrome
```

---

## 4. Security & Production Hardening
* **Role-Based Security**: Custom claims and Firestore security rules prevent unauthorized data access or client-side status tampering.
* **Server Authoritative Fares**: All calculations are executed server-side via Cloud Functions.
* **Camera-Only Photo Enforcement**: Driver onboarding requires live device camera capture to eliminate spoofing.
