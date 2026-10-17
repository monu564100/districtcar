require('dotenv').config();
const express = require('express');
const cors = require('cors');
const notificationService = require('./notificationService');
const firestoreWatcher = require('./firestoreWatcher');
const schedulerWorker = require('./scheduler');
const { travelCampaigns } = require('./travelCampaigns');
const firebaseClient = require('./firebaseClient');

const app = express();
const PORT = process.env.PORT || 4000;

app.use(cors());
app.use(express.json());

// Health Check & Worker Status
app.get('/health', (req, res) => {
  res.json({
    status: 'online',
    service: 'District Car Notification Service & Background Worker',
    timestamp: new Date().toISOString(),
    firestoreConnected: !!firebaseClient.db,
    fcmServerKeyConfigured: !!firebaseClient.serverKey,
    campaignsLoaded: travelCampaigns.length,
  });
});

/**
 * 1. Endpoint: Trigger / Relay New Booking Notification to Drivers
 * Called from customer app or backend when ride is created
 */
app.post('/api/notifications/booking-created', async (req, res) => {
  try {
    const {
      bookingId,
      readableId,
      categoryId,
      pickupAddress,
      destinationAddress,
      estimatedFare,
    } = req.body;

    if (!bookingId) {
      return res.status(400).json({ success: false, error: 'bookingId is required' });
    }

    const result = await notificationService.notifyDriversNewBooking({
      bookingId,
      readableId: readableId || bookingId,
      categoryId,
      pickupAddress,
      destinationAddress,
      estimatedFare: Number(estimatedFare || 0),
    });

    res.json(result);
  } catch (err) {
    console.error('Error in /api/notifications/booking-created:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * 2. Endpoint: Driver Accepted Booking -> Notify Customer
 * Called from driver app or functions when driver accepts
 */
app.post('/api/notifications/booking-accepted', async (req, res) => {
  try {
    const {
      bookingId,
      customerId,
      driverName,
      driverPhone,
      vehiclePlate,
      vehicleModel,
      rideOtp,
    } = req.body;

    if (!bookingId || !customerId) {
      return res.status(400).json({ success: false, error: 'bookingId and customerId are required' });
    }

    const result = await notificationService.notifyCustomerBookingAccepted({
      bookingId,
      customerId,
      driverName,
      driverPhone,
      vehiclePlate,
      vehicleModel,
      rideOtp,
    });

    res.json(result);
  } catch (err) {
    console.error('Error in /api/notifications/booking-accepted:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * 2b. Endpoint: Driver Started Trip -> Notify Customer with Zomato Live Tracker
 */
app.post('/api/notifications/trip-started', async (req, res) => {
  try {
    const {
      bookingId,
      customerId,
      driverName,
      destinationAddress,
      vehiclePlate,
      vehicleModel,
    } = req.body;

    if (!bookingId || !customerId) {
      return res.status(400).json({ success: false, error: 'bookingId and customerId are required' });
    }

    const result = await notificationService.notifyCustomerTripStarted({
      bookingId,
      customerId,
      driverName,
      destinationAddress,
      vehiclePlate,
      vehicleModel,
    });

    res.json(result);
  } catch (err) {
    console.error('Error in /api/notifications/trip-started:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * 3. Endpoint: Send Upcoming Booking Reminder to Customer & Driver
 */
app.post('/api/notifications/booking-reminder', async (req, res) => {
  try {
    const {
      bookingId,
      customerId,
      driverId,
      pickupTime,
      pickupAddress,
      destinationAddress,
    } = req.body;

    if (!bookingId) {
      return res.status(400).json({ success: false, error: 'bookingId is required' });
    }

    const result = await notificationService.notifyUpcomingBookingReminder({
      bookingId,
      customerId,
      driverId,
      pickupTime,
      pickupAddress,
      destinationAddress,
    });

    res.json(result);
  } catch (err) {
    console.error('Error in /api/notifications/booking-reminder:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * 4. Endpoint: Send Tours & Travel Hindi Joke Campaign
 * Can be triggered automatically by cron or manually from Admin Panel
 */
app.post('/api/notifications/campaign/travel', async (req, res) => {
  try {
    const { campaignId, customCampaign } = req.body;

    let selectedCampaign = null;
    if (customCampaign) {
      selectedCampaign = customCampaign;
    } else if (campaignId) {
      selectedCampaign = travelCampaigns.find((c) => c.id === campaignId);
    }

    const result = await notificationService.sendTravelEngagementCampaign(selectedCampaign);
    res.json(result);
  } catch (err) {
    console.error('Error in /api/notifications/campaign/travel:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * 5. Endpoint: Get all available Travel Campaigns with Hindi Jokes
 * Used by Admin Panel to inspect and pick campaigns
 */
app.get('/api/notifications/campaigns', (req, res) => {
  res.json({
    success: true,
    count: travelCampaigns.length,
    campaigns: travelCampaigns,
  });
});

/**
 * 6. Endpoint: Admin Custom Broadcast
 * Directly invoked from the Admin Panel Notification Screen
 */
app.post('/api/notifications/admin-broadcast', async (req, res) => {
  try {
    const { title, body, imageUrl, targetAudience, extraData } = req.body;

    if (!title || !body) {
      return res.status(400).json({ success: false, error: 'title and body are required' });
    }

    const result = await notificationService.sendAdminBroadcast({
      title,
      body,
      imageUrl,
      targetAudience: targetAudience || 'all',
      extraData,
    });

    res.json(result);
  } catch (err) {
    console.error('Error in /api/notifications/admin-broadcast:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// Start Express Server
const server = app.listen(PORT, () => {
  console.log(`=======================================================`);
  console.log(`🚀 District Car Notification Server running on port ${PORT}`);
  console.log(`📡 URL: http://localhost:${PORT}`);
  console.log(`🔍 Health: http://localhost:${PORT}/health`);
  console.log(`=======================================================`);

  // Start Background Real-time Firestore Watcher
  firestoreWatcher.start();

  // Start Cron Schedulers
  schedulerWorker.start();
});

module.exports = { app, server };
