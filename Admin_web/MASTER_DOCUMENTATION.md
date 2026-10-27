# District Car — Complete End-to-End Master Documentation & Operational Blueprint

> **Enterprise Mobility Platform for Rural, Semi-Urban & District Connectivity in Jharkhand**  
> *Authoritative Guide from Inception to Scale | Architecture, Operations, Legal Compliance & Tech Stack*

---

## 📑 Table of Contents
1. [Executive Overview & Platform Model](#1-executive-overview--platform-model)
2. [End-to-End System Architecture](#2-end-to-end-system-architecture)
3. [Business & Revenue Mechanics (90/10 Model)](#3-business--revenue-mechanics-9010-model)
4. [The 3-Trip Cash Lock Rule Engine](#4-the-3-trip-cash-lock-rule-engine)
5. [Fleet Operations & Driver Onboarding Playbook](#5-fleet-operations--driver-onboarding-playbook)
6. [Legal, Compliance & Banking Roadmap](#6-legal-compliance--banking-roadmap)
7. [Enterprise Admin Web Portal Manual](#7-enterprise-admin-web-portal-manual)
8. [Mobile Applications (Customer & Driver)](#8-mobile-applications-customer--driver)
9. [Firebase Backend & Data Schemas](#9-firebase-backend--data-schemas)
10. [Deployment & DevOps Blueprint](#10-deployment--devops-blueprint)
11. [30-Day District Launch Playbook](#11-30-day-district-launch-playbook)

---

## 1. Executive Overview & Platform Model

**District Car** is a purpose-built mobility ecosystem designed for Tier-2, Tier-3, and rural districts of Jharkhand (originating in Khunti, Murhu, Ranchi, Ramgarh, and surrounding belts). Unlike urban ride-hailing platforms that enforce complex digital payment gateways, District Car utilizes a **Hyperlocal Direct-Match Intermediary Model**:

```
[Rider via Customer App] ---> Requests Ride ---> [District Car Cloud Engine]
                                                        |
                                                        v
                                             [Dispatches Nearest Driver]
                                                        |
                                                        v
[Rider Pays 100% Cash/UPI Directly to Driver] <--- [Ride Completed]
                                                        |
                                                        v
[Driver Remits 10% Platform Commission to Admin HQ]
```

### Core Value Propositions:
* **Zero Payment Gateway Friction**: Riders pay drivers directly upon arrival via cash or driver’s personal UPI QR code. No failed card transactions or internet banking drop-offs in remote areas.
* **Fair Take-Home Pay**: Drivers retain **90% of every fare** (substantially higher than urban aggregators charging 25–30%).
* **Guaranteed Platform Revenue**: Enforced via an automated **3-Trip Cash Lock Rule** tracked in Firestore.
* **Full Intermediary Protection**: Operates under Section 79 of the Information Technology Act (Intermediary Safe Harbor).

---

## 2. End-to-End System Architecture

The ecosystem connects four high-performance layers:
1. **Customer Mobile App (`customer_app`)**: Flutter Android/iOS application with live GPS pickup detection, vehicle class selection (Mini, Sedan, SUV, Auto), fare estimation, round-trip booking, 4-digit Ride Start OTP, and emergency SOS controls.
2. **Driver Partner App (`driver_app`)**: Flutter mobile application featuring radar discovery mode, 1-tap ride acceptance, customer OTP verification, live earnings wallet, and automated 3-trip cash rule enforcement.
3. **Enterprise Admin Web Portal (`Admin_web`)**: Single-page application built with HTML5, CSS3, and JavaScript with Master PIN **`564100`**, real-time Firestore synchronization, KYC document inspector, ride ledger, manual driver assignment dropdown, cash/UPI commission settlement, and permanent delete controls.
4. **Firebase Cloud Infrastructure (`districtcar-4b880`)**: Google Cloud Firestore, Firebase Authentication, Cloud Storage for driver DL/RC document uploads, and Firebase Cloud Messaging (FCM) for instant push alerts.

---

## 3. Business & Revenue Mechanics (90/10 Model)

District Car operates on a clear financial ledger:

$$\text{Gross Customer Fare} = \text{Base Fare} + (\text{Distance (km)} \times \text{Per-Km Rate}) + \text{Waiting/Toll Charges}$$

$$\text{Driver Partner Earnings (90\%)} = \text{Gross Fare} \times 0.90$$

$$\text{District Car Platform Fee (10\%)} = \text{Gross Fare} \times 0.10$$

### Ledger Accounting Example:
| Metric | Amount | Description |
| :--- | :--- | :--- |
| **Gross Fare Collected** | ₹500 | Paid directly by rider to driver in Cash or UPI. |
| **Driver Partner Net** | ₹450 (90%) | Kept immediately by the driver partner. |
| **Platform Commission Due** | ₹50 (10%) | Automatically logged to driver's `pendingCommission` in Firestore. |

### How Admin Collects the 10% Platform Fee:
1. **Cash at District Hub**: Driver visits the local hub (or weekly meeting) and pays accrued commission. Admin clicks **"Settle Payment"** in the Admin Portal, entering the cash voucher reference.
2. **Direct UPI to Admin**: Driver scans Admin's UPI QR code and sends the commission. Admin enters the bank UTR reference in the Admin Portal.
3. **Wallet Deduction**: For any corporate or prepay trips routed through the platform, fee is offset against the driver's wallet.

---

## 4. The 3-Trip Cash Lock Rule Engine

To guarantee that driver partners settle their platform commission dues without requiring complex credit cards, District Car implements the automated **3-Trip Rule**:

1. Every time a driver completes a ride where `paymentMethod == 'cash'`, the app and backend increment:
   * `unpaidTripsCount = unpaidTripsCount + 1`
   * `pendingCommission = pendingCommission + (finalFare * 0.10)`
2. When `unpaidTripsCount >= 3`:
   * Driver mobile app automatically restricts accepting new bookings with a warning dialog.
   * Admin portal highlights the driver with a red badge: `3 / 3 (Locked)`.
3. Upon settlement by Admin:
   * `pendingCommission` is reduced or cleared.
   * `unpaidTripsCount` resets to `0`.
   * Driver's app unlocks immediately in real time via Firestore snapshot listener.

---

## 5. Fleet Operations & Driver Onboarding Playbook

### Commercial Vehicles Only (Yellow Plate Rule)
Under Section 66 of the Motor Vehicles Act, 1988, carrying passengers for hire in personal white-plate vehicles is illegal in India. Onboarding white-plate cars exposes the platform and driver to RTO challans (₹10,000–₹25,000) and vehicle impoundment.

### Mandatory Documents Required per Driver:
1. **Driver Identification**:
   * Commercial Driving License (DL) with Transport endorsement.
   * Aadhaar Card (Identity & Residential verification).
   * Police Character Certificate (*Acharan Praman Patra*) via Jharkhand Police citizen portal.
2. **Vehicle Compliance**:
   * Vehicle Registration Certificate (RC) showing **Commercial Yellow Plate** (Taxi / Cab / Auto).
   * Commercial Insurance with Third-Party & Passenger Liability cover.
   * Fitness Certificate (FC) issued by District RTO.
   * Pollution Under Control Certificate (PUC).
   * District or All-Jharkhand Tourist Permit.

### Admin KYC Verification Workflow:
* Navigate to **Drivers & KYC** in Admin Portal.
* Click the Eye icon on any pending driver to open the **KYC Document Inspector**.
* Inspect high-resolution photo uploads of Driving License and Registration Certificate.
* Click **Approve** (activates driver instantly) or **Reject** (prompts for specific reason such as *“Blurry RC copy”*).

---

## 6. Legal, Compliance & Banking Roadmap

### A. Intermediary Safe Harbor (Section 79, IT Act 2000)
Because District Car does not operate its own vehicles and drivers are independent partners, the platform qualifies as an **Electronic Intermediary**:
* **Explicit Terms of Service**: Both driver and rider must agree to terms on first launch.
* **Grievance Officer**: Designated contact listed on portal (`grievance@districtcar.in`).
* **Law Enforcement Support**: Ability to supply booking logs to district police within 72 hours upon formal inquiry.

### B. Three-Stage Banking & Entity Roadmap

| Stage | Milestone | Entity & Account | Tax & GST |
| :--- | :--- | :--- | :--- |
| **Stage 1: Launch Week** | 1–15 Drivers (Pilot in 1 District) | **Sole Proprietorship** using personal Savings Account / UPI. | **No GST required** (Turnover < ₹20 Lakhs). |
| **Stage 2: Fleet Expansion** | 15–100 Drivers (Daily Commission Inflow) | **Udyam MSME Certificate** (Free) + **Zero/Low-Balance Current Account** under *"District Car"*. | Track commission income; prepare for formal accounting. |
| **Stage 3: Multi-District Scale** | Annual Commission > ₹20 Lakhs | **Private Limited Company** (MCA) + **State Aggregator License** from Jharkhand STA. | **GST Registration** (5% GST on transport facilitation). |

---

## 7. Enterprise Admin Web Portal Manual

The Admin Portal is accessible on your local machine (`http://localhost:8080/`) and deployed on Vercel:

### Key Features:
* **Master Security Lock**: Protected by PIN **`564100`** with 6-digit auto-advancing input, shake animation on invalid entry, session persistence, and manual lock button.
* **Executive Dashboard**: Gross ride volume, 10% platform share, 90% driver take-home, active drivers telemetry, and a 7-day volume chart powered by Chart.js.
* **Drivers & KYC Module**: Driver profiles, phone numbers, vehicle category, live status (Online/Busy/Offline), DL/RC modal inspector, approve/reject buttons, and permanent delete.
* **All Rides & Trips**:
  * Formatted `#DC-XXXXX` booking identifiers.
  * **Booking Requested Time** (e.g. `26 Oct, 01:45 PM`).
  * **Driver Accept Time** with response duration delta (e.g. `⚡ Accepted: 01:48 PM (+3m)`).
  * **Manual Driver Assignment Dropdown**: Inline and modal selectors listing available online drivers with matching category star ratings.
  * Gross Fare, 10% Platform Fee, and 90% Driver Share split.
  * Permanent delete booking action.
  * 1-click CSV Report export.
* **Driver Commissions & Settlements Category**:
  * Financial cards for Commission Accrued, Commission Due, and Total Commission Settled.
  * Complete Driver Commission Ledger table.
  * **Settle Payment Modal**: Settle full or partial commission via Cash, PhonePe/GPay UPI, Bank Transfer, or Wallet Deduction with receipt reference. Automatically resets the driver's 3-trip cash lock!
  * Settlement receipts audit trail stored in Firestore collection `commission_settlements`.
* **Customers Module**: Customer names, phone numbers, trip count, total spent, block/unblock security toggle, and permanent delete.
* **Remote App Update Controls**: Sync live build numbers (e.g. `26`) to Firestore `remote_configs/app_updates` with force-update toggle and direct APK download URL.

---

## 8. Mobile Applications (Customer & Driver)

* **Customer App (`customer_app`)**: Live GPS address lookup, Mini/Sedan/SUV/Auto categories, round-trip support, 4-digit OTP generation, live driver telemetry, and SOS emergency buttons.
* **Driver Partner App (`driver_app`)**: Radar dispatch screen, pledge agreement, ride start customer OTP verification box, dynamic wallet with 10% commission dues, and 3-trip rule auto-locking.

---

## 9. Firebase Backend & Data Schemas

The system runs on Google Cloud Firestore (`districtcar-4b880`):
* `users`: Customer profiles, phone numbers, trip history, blocked state.
* `drivers`: Driver profiles, vehicle details, verification status, wallet balance, `pendingCommission`, `unpaidTripsCount`, and live status.
* `bookings`: Trip details, customer/driver IDs, pickup/drop coordinates, `rideOtp`, `estimatedFare`, `finalFare`, `createdAt`, `driverAcceptedAt`, and status.
* `commission_settlements`: Audit records of every commission payment made by drivers (timestamp, amount, payment mode, receipt number, admin ID).
* `payout_requests`: Instant UPI withdrawal requests submitted by drivers.
* `remote_configs/app_updates`: Live build versions and force-update flags.

---

## 10. Deployment & DevOps Blueprint

### Production Repositories:
1. **Admin Web Portal (Vercel)**: [`https://github.com/monu564100/DistrictCar_Admin.git`](https://github.com/monu564100/DistrictCar_Admin.git)
2. **Master Project Monorepo**: [`https://github.com/monu564100/districtcar.git`](https://github.com/monu564100/districtcar.git)

### Local Server Launch:
* Simply double click [`serve.bat`](file:///c:/Users/monu5/OneDrive/Desktop/Ditrict%20car/Admin_web/serve.bat) inside `Admin_web` or run `python server.py`.

---

## 11. 30-Day District Launch Playbook

* **Week 1**: Register free Udyam MSME certificate and onboard the first 10–15 commercial yellow-plate drivers in your district hub (verify DL and RC).
* **Week 2**: Ground marketing with pamphlets at key district transit hubs (Railway Station, Bus Stand, District Hospital, Main Market Chowk).
* **Week 3**: Soft launch first 50 rides (optional 0% commission introductory trial for drivers to seed supply).
* **Week 4**: Enable the 10% commission rule, conduct weekly in-person settlements at the district hub, and open a dedicated District Car Current Account.
