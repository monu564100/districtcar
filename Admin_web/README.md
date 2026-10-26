# District Car — Enterprise Admin Web Portal

A high-performance, single-page application (SPA) built with pure HTML5, CSS3, and JavaScript (Vanilla) for managing District Car fleet operations, drivers, customers, ride dispatch, and real-time 10% platform commission accounting across Jharkhand.

---

## 🌟 Key Modules & Features

### 1. Executive Operations & Revenue Dashboard
- **Gross Revenue**: Real-time summation of all completed rides across Jharkhand.
- **10% Platform Commission**: Automated ledger tracking platform maintenance fee.
- **90% Driver Partner Payout**: Real-time net driver take-home accounting.
- **Daily Analytics Graph**: 7-day revenue trend built with Chart.js.
- **Live Fleet Telemetry**: Real-time count of online, approved, and active drivers.

### 2. Driver Fleet & KYC Compliance Management
- **Driver Profile**: Name, phone, vehicle plate, category (Auto, Mini, Sedan, SUV).
- **KYC Document Inspector**: Modal view of Driving License (DL) and Vehicle Registration Certificate (RC).
- **Approve / Reject Actions**: One-click driver partner verification with custom rejection feedback.
- **Commission Wallet**: Live tracking of 10% platform dues per driver.
- **3-Trip Cash Lock Rule**: Visual warning chip (`3 / 3 (Locked)`) when a driver reaches 3 unpaid cash rides. One-click "Settle" action resets dues and unblocks the driver in Firestore.

### 3. Customer & Rider Management
- **Customer Directory**: Name, verified phone, total trips, and cumulative platform spend.
- **Account Security**: Instant one-click Block / Unblock customer account toggles.

### 4. Transparent Rides & 10% Commission Ledger
- **Readable Trip IDs**: Formatted `#DC-XXXXX` identifier.
- **OTP Verification**: Driver ride start verification PIN.
- **Financial Split Per Ride**:
  - Total Gross Fare
  - 10% District Car Platform Fee
  - 90% Driver Net Earnings
- **Filter & Search**: Instant filtering by status (Completed, In-Transit, Searching, Cancelled) and dynamic search by ID, customer, or driver.
- **CSV Export**: One-click download of all ride transactions for accounting and tax records.

### 5. Driver Instant UPI Payouts
- **Withdrawal Queue**: View all driver withdrawal requests from their in-app wallet.
- **One-Click UPI Approval**: Record bank transaction reference (UTR) and mark paid.
- **Rejection Flow**: Reject fraudulent or unverified requests.

### 6. Remote Mobile App Version Control
- Direct synchronization with Firestore `remote_configs/app_updates`.
- Update Driver App Build Number (e.g., `26`) and Customer App Build Number.
- Toggle Force Update mode to prevent outdated mobile clients from taking rides.

---

## 🚀 How to Run the Website

### Option A: Using the Windows Batch File
Simply double-click `serve.bat` inside the `Admin_web` folder.

### Option B: Using Python CLI
```bash
cd Admin_web
python server.py
```
Open your browser and visit: **`http://localhost:8080`**

### Option C: Production Deployment
Since this admin portal uses pure client-side HTML/CSS/JS and connects directly to Firebase Firestore, it can be hosted instantly anywhere with zero build step:
- **Firebase Hosting**: `firebase deploy --only hosting`
- **Vercel / Netlify / GitHub Pages**: Deploy the `Admin_web/` directory directly.
