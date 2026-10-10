const cron = require('node-cron');
const { firebaseClient, clientFirestore } = require('./firebaseClient');
const notificationService = require('./notificationService');

const {
  clientCollection,
  clientGetDocs,
  clientDoc,
  clientUpdateDoc,
  clientQuery,
  clientWhere,
  clientServerTimestamp,
} = clientFirestore;

class SchedulerWorker {
  constructor() {
    this.upcomingJob = null;
    this.campaignJob = null;
  }

  start() {
    console.log('⏰ [SchedulerWorker] Initializing background cron jobs...');

    const upcomingCronExpr = process.env.CRON_UPCOMING_BOOKING || '*/5 * * * *';
    const campaignCronExpr = process.env.CRON_TRAVEL_CAMPAIGN || '0 10,17 * * *';

    // 1. Job 1: Check upcoming scheduled rides (every 5 minutes)
    if (process.env.ENABLE_AUTOMATED_REMINDERS !== 'false') {
      this.upcomingJob = cron.schedule(upcomingCronExpr, async () => {
        console.log('[SchedulerWorker] Running upcoming rides reminder check...');
        await this.checkUpcomingBookings();
      });
      console.log(`[SchedulerWorker] Upcoming rides check scheduled with cron: "${upcomingCronExpr}"`);
    }

    // 2. Job 2: User Engagement Travel Hindi jokes campaign
    if (process.env.ENABLE_TRAVEL_CAMPAIGNS !== 'false') {
      this.campaignJob = cron.schedule(campaignCronExpr, async () => {
        console.log('[SchedulerWorker] Running automated Hindi jokes travel engagement broadcast...');
        try {
          await notificationService.sendTravelEngagementCampaign();
        } catch (e) {
          console.error('[SchedulerWorker] Travel campaign execution failed:', e.message);
        }
      });
      console.log(`[SchedulerWorker] Travel engagement campaign scheduled with cron: "${campaignCronExpr}"`);
    }
  }

  /**
   * Scans bookings for upcoming scheduled departures in the next 15-60 minutes
   * and dispatches reminders to both Customer and Driver.
   */
  async checkUpcomingBookings() {
    const db = firebaseClient.clientDb;
    if (!db) return;

    try {
      const now = new Date();
      const lookAheadMinutes = 60;

      // Query active bookings
      const q = clientQuery(
        clientCollection(db, 'bookings'),
        clientWhere('status', 'in', ['driver_assigned', 'requested', 'searching_driver'])
      );
      const snapshot = await clientGetDocs(q);

      console.log(`[SchedulerWorker] Auditing ${snapshot.size} active bookings for upcoming schedule alerts...`);

      for (const docSnap of snapshot.docs) {
        const data = docSnap.data();
        if (data.reminderSent) continue;

        let departureTime = null;
        if (data.scheduledAt) {
          departureTime = data.scheduledAt.toDate ? data.scheduledAt.toDate() : new Date(data.scheduledAt);
        } else if (data.pickupTime) {
          departureTime = new Date(data.pickupTime);
        }

        if (departureTime && !isNaN(departureTime.getTime())) {
          const diffMinutes = (departureTime.getTime() - now.getTime()) / (1000 * 60);

          if (diffMinutes > 0 && diffMinutes <= lookAheadMinutes) {
            console.log(`[SchedulerWorker] Booking ${docSnap.id} departure in ${Math.round(diffMinutes)} mins! Sending alert.`);

            await notificationService.notifyUpcomingBookingReminder({
              bookingId: docSnap.id,
              customerId: data.customerId,
              driverId: data.driverId,
              pickupTime: departureTime.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
              pickupAddress: data.pickup?.address || 'Pickup Point',
              destinationAddress: data.destination?.address || 'Destination',
            });

            await clientUpdateDoc(clientDoc(db, 'bookings', docSnap.id), {
              reminderSent: true,
              reminderSentAt: clientServerTimestamp(),
            });
          }
        }
      }
    } catch (err) {
      console.warn('[SchedulerWorker] Notice in checkUpcomingBookings:', err.message);
    }
  }
}

module.exports = new SchedulerWorker();
