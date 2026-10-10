# District Car Notification Service & Worker

A high-performance Node.js background worker and push notification server for **District Car** (Customer App, Driver Partner App, and Admin Panel).

---

## 🚀 Features

1. **Automatic Driver Alert on New Booking**:
   - Listens in real-time or accepts HTTP requests when a customer places a ride request.
   - Automatically pushes high-priority notifications to matching vehicle category topics (`/topics/driver_<category>`), the general drivers topic (`/topics/drivers`), and online driver personal inboxes.

2. **Customer Notification on Driver Acceptance**:
   - Instantly notifies the customer via topic (`/topics/customer_<uid>`), token, and personal inbox when a driver accepts a ride.
   - Includes driver name, vehicle plate, phone number, and OTP.

3. **Upcoming Scheduled Ride Alert (Cron)**:
   - Scans active bookings every 5 minutes.
   - Alerts both customer and driver 15 to 60 minutes before scheduled departure.

4. **Tours & Travel Hindi Jokes User Engagement Campaign**:
   - Automated morning and evening campaign scheduler (`0 10,17 * * *`).
   - Hilarious Jharkhand-themed Hindi travel jokes (*"Chalo Netarhat ghoom ke aatey hai"*, *"Office boss tiger ki tarah daad raha ho toh Betla dekh lo"*, Patratu Valley, Hundru Falls, Deoghar Darshan).
   - Also syncs to customer app `banner_offers` carousel for visual engagement.

5. **Admin Panel Integration**:
   - Seamlessly connected to the Admin Panel's `NotificationBroadcastScreen`.
   - Allows administrators to preview, select, and send one-click campaigns and custom broadcasts.

---

## 🛠️ Architecture

- **`server.js`**: Express HTTP server running on port `4000`.
- **`firebaseClient.js`**: Dual Firebase adapter supporting Firebase Admin SDK and modular Firestore Client SDK.
- **`notificationService.js`**: Multichannel notification dispatch engine.
- **`firestoreWatcher.js`**: Real-time snapshot listener on the `bookings` collection.
- **`scheduler.js`**: Automated node-cron worker for upcoming ride reminders and campaigns.
- **`travelCampaigns.js`**: Catalog of Jharkhand tourist destinations with Hindi jokes.

---

## 💻 Running the Worker

### Install Dependencies
```bash
cd notification_service
npm install
```

### Start Server
```bash
npm start
```
Server runs at `http://localhost:4000`.

---

## 📡 API Endpoints

- **`GET /health`**: Status check and worker heartbeat.
- **`POST /api/notifications/booking-created`**: Push booking alert to drivers.
- **`POST /api/notifications/booking-accepted`**: Push acceptance alert to customer.
- **`POST /api/notifications/booking-reminder`**: Alert upcoming ride to customer and driver.
- **`POST /api/notifications/campaign/travel`**: Broadcast a Hindi travel engagement campaign.
- **`GET /api/notifications/campaigns`**: Fetch all pre-configured travel campaigns.
- **`POST /api/notifications/admin-broadcast`**: Send custom broadcast from Admin Panel.
