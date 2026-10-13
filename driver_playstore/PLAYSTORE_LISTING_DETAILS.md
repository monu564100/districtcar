# Google Play Console Submission Details - Driver Partner App

## 1. App Identifiers & Build Specs
* **App Name**: District Car Partner - Driver App
* **Package / Application ID**: `com.drivercardistrict.app`
* **Version Name**: `1.0.0`
* **Version Code**: `8`
* **App Bundle File**: `driver_playstore/DistrictCar_Driver_Release.aab`
* **Target Android SDK**: `34` (Android 14) / Min SDK: `21` (Android 5.0)

---

## 2. Store Listing Texts

### Short Description (80 Characters max):
> Driver partner app for receiving ride requests and trips across Jharkhand.

### Full Description:
District Car Partner is the driver application for vehicle owners and commercial drivers operating across Khunti, Ranchi, and districts of Jharkhand.

The app connects drivers with local passengers looking for doorstep pickups, block commutes, and district tour travel.

Key Features:
• Direct Payments: Receive trip fare settlements directly from passengers via Cash or UPI.
• Block & Stand Selection: View and accept ride requests originating in your operating area.
• Duty Status Control: Toggle your availability online or offline with one tap.
• Location-Based Dispatch: Receive ride requests dispatched according to your vehicle location.
• Support Helpline: Direct access to customer care (+91 87896 01387) and driver assistance.
• Account Management: Complete control over your profile with in-app account and data deletion options.

Manage your trips and ride requests easily with District Car Partner.

---

## 3. Play Console "App Access" (For Google Review Team)
In Play Console > Policy and programs > App access, select **"All or some functionality is restricted"** and add this instruction:

* **Instruction Name**: Driver App Review Test Access
* **Username / Email**: `playstore.driver@districtcar.com`
* **Password / Credentials**: `No password required. Tap the "Play Store Team Demo Login (Test Account)" button located directly below Google Sign-In.`
* **Explanation for Reviewers**:
> Reviewers can instantly log into the partner driver app without a physical Google/Gmail account by tapping the "Play Store Team Demo Login (Test Account)" button on the sign-in screen. It preloads a verified partner driver profile with an active vehicle and opens the main driver dashboard immediately.

---

## 4. Play Console "Location in Background" Declaration
When Google Play asks for the declaration of Background Location usage:
* **Core Purpose**: Vehicle tracking and ride dispatch during active duty.
* **Declaration Text**:
> District Car Partner is an on-demand driver dispatch application. Background location access is strictly required to:
> 1. Match nearby passengers with the closest available driver within 10–25 km.
> 2. Provide live route tracking to passengers for safety while the driver navigates with screen turned off or uses an external navigation app (e.g. Google Maps).
> 3. Calculate trip distance accurately for fare estimation.
> Location tracking is only active when the driver turns their status to "Online" and stops automatically when they go "Offline".

---

## 5. Privacy Policy & Support Contact
* **Privacy Policy URL**: `https://notification.projectmarket.in/privacy-policy` (or `https://notification.projectmarket.in/privacy-policy/`)
* **Account & Data Deletion URL**: `https://notification.projectmarket.in/delete-account` (or `https://notification.projectmarket.in/delete-account/`)
* **Support Email**: `contact@projectmarket.in` / `support@districtcar.in`
* **Support Phone**: `+91 87896 01387`
* **Category**: Maps & Navigation / Travel & Local
