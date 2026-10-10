# District Car — Google Play Store Listing & Data Safety Compliance

## 1. App Store Identification
- **App Name**: District Car — Cab & Tour Ride
- **Package Name (Application ID)**: `com.districtcarcustomerd.app`
- **Category**: Maps & Navigation / Travel & Local
- **Target Audience**: General Public (13+)
- **Primary Language**: English (United States), Hindi (India)
- **Version Code**: `6`
- **Version Name**: `1.0.0`
- **AAB File**: [`DistrictCar_Customer_Release_v6.aab`](DistrictCar_Customer_Release_v6.aab) (51.5 MB)

---

## 2. Store Listing Metadata

### Short Description (Up to 80 characters)
> Jharkhand's 1st rural & district cab network with guaranteed round-trip savings.

### Full Description (Up to 4000 characters)
```text
District Car (districtcar.in) is Jharkhand's pioneering rural and district cab booking service, built to connect village communities, remote tolas, Sadar Hospitals, and district headquarters across all 24 districts of Jharkhand with transparent, dignified, and safe mobility.

WHY COMMUTERS CHOOSE DISTRICT CAR:
• ZERO SURGE PRICING: Fixed, transparent per-km rates with zero arbitrary rain or peak surges.
• 1-TAP ROUND-TRIP PACKAGE: Need to visit Sadar Hospital, a medical checkup, court hearings, or mandi? Book a Round Trip with an automatic return discount and 1 hour of waiting included for free!
• REAL-TIME GOOGLE GPS ACCURACY: Accurate doorstep village and chowk pick-ups powered by Google Maps Directions & Distance Matrix, showing exact travel duration and live traffic.
• VEHICLE CHOICES FOR EVERY NEED:
  - Economy Mini Cab (Hatchback/Sedan AC) — ₹15/km (One-way) / ₹17.5/km (Round-trip)
  - Auto Rickshaw (Local & Rural Routes) — ₹11/km
  - Comfort Sedan AC — ₹23/km (One-way) / ₹25/km (Round-trip)
  - SUV / Bolero / Ertiga (6-7 Seater AC) — ₹21/km
• TOURS & TRAVELS PACKAGES: Explore famous Jharkhand destinations including Hundru Falls, Jonha Falls, Baba Baidyanath Dham Deoghar, Parasnath, Betla National Park, and Patratu Valley with dedicated sightseeing drivers.
• VERIFIED SARATHI DRIVER PARTNERS: Police-verified drivers with local route familiarity and safe rural driving records.
• 24x7 INCIDENT & GRIEVANCE SUPPORT: In-app reporting for ride concerns, overcharging, and lost property handled directly by our customer care team within 2 hours.

CORPORATE & REGISTRATION CREDENTIALS:
• Company: District Car Mobility Private Limited
• Registered Headquarters: Nichey Chowk, Khunti, Jharkhand - 835210
• Leadership: Monu Kumar (CEO) & Sonu Kumar (Co-Founder)
• Support Helpline: +91 87896 01387
• Support Email: support@districtcar.in
• Official Website: https://districtcar.in
```

---

## 3. Google Play Store Data Safety Questionnaire Answers

Google Play Console requires exact declarations regarding data collection, encryption, and deletion. Use these exact answers:

| Data Type | Collected? | Shared? | Purpose | Ephemeral? | User Can Delete? |
|---|---|---|---|---|---|
| **Approximate Location** | Yes | No | App functionality, fraud prevention, driver dispatch | No | Yes (via account deletion) |
| **Precise Location** | Yes | No | Real-time ride navigation, accurate pickup/drop navigation, driver assignment | Active session only | Yes (via account deletion) |
| **Name** | Yes | No | Account management, driver identification | No | Yes (Profile ➔ Delete Account) |
| **Email Address** | Yes | No | Account management, ride receipts | No | Yes |
| **Phone Number** | Yes | No | Account authentication, driver trip coordination | No | Yes |
| **User IDs (Firebase UID)** | Yes | No | App functionality, analytics | No | Yes |
| **Crash Logs & Diagnostics** | Yes | No | App stability, performance improvement | No | Automatic retention |

### Data Safety Declarations:
1. **Is data encrypted in transit?** 
   - **Yes**, all network traffic uses HTTPS / TLS 1.3 to Google Cloud Firebase servers.
2. **Do you provide a way for users to request that their data is deleted?** 
   - **Yes**. Users can delete their account and all personal data inside the app under:
     `Profile ➔ Delete Account (खाता हटाएँ)`
   - Web deletion request URL: `https://districtcar.in/#terms` (Email request to `support@districtcar.in`).

---

## 4. Play Store Contact & Policy URLs

- **Privacy Policy URL**: `https://districtcar.in/#terms`
- **Account Deletion Request URL**: `https://districtcar.in/#terms`
- **Support Email**: `support@districtcar.in`
- **Support Phone**: `+918789601387`
- **Developer Website**: `https://districtcar.in`
- **Physical Address**: `Nichey Chowk, Khunti, Jharkhand - 835210, India`
