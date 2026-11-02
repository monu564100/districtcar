const axios = require('axios');
const { firebaseClient, clientFirestore } = require('./firebaseClient');
const { travelCampaigns } = require('./travelCampaigns');

const {
  clientCollection,
  clientGetDocs,
  clientGetDoc,
  clientDoc,
  clientAddDoc,
  clientSetDoc,
  clientQuery,
  clientWhere,
  clientServerTimestamp,
} = clientFirestore;

class NotificationService {
  constructor() {
    this.firebase = firebaseClient;
  }

  getDb() {
    return this.firebase.clientDb;
  }

  /**
   * 1. Customer Books a Ride -> Dispatch Push Notification to all Online Drivers & Category Topic
   */
  async notifyDriversNewBooking({
    bookingId,
    readableId,
    categoryId,
    pickupAddress,
    destinationAddress,
    estimatedFare,
  }) {
    const db = this.getDb();
    console.log(`[NotificationService] New booking ${readableId || bookingId} created. Alerting drivers...`);

    const title = `🚖 New Ride Request! (₹${Math.round(estimatedFare || 0)})`;
    const body = `${pickupAddress} ➔ ${destinationAddress} [${(categoryId || '').toUpperCase()}]`;

    const dataPayload = {
      type: 'new_booking_offered',
      bookingId,
      readableId: readableId || bookingId,
      categoryId: categoryId || 'sedan',
      fare: String(estimatedFare || 0),
      pickup: pickupAddress || '',
      destination: destinationAddress || '',
    };

    // 1. Record notification in Firestore
    if (db) {
      try {
        await clientAddDoc(clientCollection(db, 'notifications'), {
          title,
          body,
          targetAudience: 'drivers',
          type: 'new_booking_offered',
          bookingId,
          readableId,
          categoryId,
          status: 'delivered',
          sentAt: clientServerTimestamp(),
        });
      } catch (e) {
        console.warn('Could not record notification in Firestore:', e.message);
      }
    }

    // 2. Dispatch SINGLE Push to category topic (or drivers general topic if no category)
    const cleanCat = (categoryId || '').toLowerCase().trim();
    const targetTopic = (cleanCat && cleanCat !== 'all')
      ? `/topics/driver_${cleanCat}`
      : '/topics/drivers';

    await this.firebase.sendPushNotification({
      target: targetTopic,
      title,
      body,
      data: dataPayload,
    });

    // 3. Write to online drivers' inboxes for audit & in-app badge without sending duplicate push
    if (db) {
      try {
        const q = clientQuery(
          clientCollection(db, 'drivers'),
          clientWhere('isOnline', '==', true),
          clientWhere('isBlocked', '==', false)
        );
        const driversSnapshot = await clientGetDocs(q);

        for (const dDoc of driversSnapshot.docs) {
          const driverId = dDoc.id;
          try {
            await clientAddDoc(
              clientCollection(db, 'drivers', driverId, 'inbox_notifications'),
              {
                title,
                body,
                bookingId,
                sentAt: clientServerTimestamp(),
                isRead: false,
              }
            );
          } catch (_) {}
        }
      } catch (err) {
        console.error('[NotificationService] Error updating online driver inboxes:', err.message);
      }
    }

    return { success: true, message: 'Notification dispatched to drivers' };
  }

  /**
   * 2. Driver Accepts Booking -> Dispatch Push Notification to Customer
   */
  async notifyCustomerBookingAccepted({
    bookingId,
    customerId,
    driverName,
    driverPhone,
    vehiclePlate,
    vehicleModel,
    rideOtp,
  }) {
    const db = this.getDb();
    console.log(`[NotificationService] Driver ${driverName} accepted booking ${bookingId}. Alerting customer...`);

    const title = '🎉 Booking Confirmed! Driver Assigned';
    const body = `${driverName || 'Driver'} is on the way in ${vehicleModel || 'Car'} (${vehiclePlate || 'Assigned'}). OTP: ${rideOtp || 'Share with driver'}`;

    const dataPayload = {
      type: 'booking_accepted',
      bookingId,
      driverName: driverName || '',
      driverPhone: driverPhone || '',
      vehiclePlate: vehiclePlate || '',
      vehicleModel: vehicleModel || '',
      rideOtp: String(rideOtp || ''),
    };

    if (db) {
      // Save in public notifications
      try {
        await clientAddDoc(clientCollection(db, 'notifications'), {
          title,
          body,
          targetAudience: 'customers',
          targetUserId: customerId,
          type: 'booking_accepted',
          bookingId,
          status: 'delivered',
          sentAt: clientServerTimestamp(),
        });
      } catch (_) {}

      // Save in Customer inbox
      try {
        await clientAddDoc(
          clientCollection(db, 'users', customerId, 'inbox_notifications'),
          {
            title,
            body,
            bookingId,
            driverName,
            driverPhone,
            vehiclePlate,
            vehicleModel,
            rideOtp,
            sentAt: clientServerTimestamp(),
            isRead: false,
          }
        );
      } catch (_) {}
    }

    // 3. Single delivery to customer (Token first, fallback to topic only if no token)
    let token = null;
    if (db) {
      try {
        const userDocRef = clientDoc(db, 'users', customerId);
        const userSnap = await clientGetDoc(userDocRef);
        token = userSnap.data()?.fcmToken;
      } catch (e) {
        console.warn('Error fetching customer token:', e.message);
      }
    }

    if (token) {
      await this.firebase.sendPushNotification({
        target: token,
        title,
        body,
        data: dataPayload,
      });
    } else {
      const customerTopic = `/topics/customer_${customerId}`;
      await this.firebase.sendPushNotification({
        target: customerTopic,
        title,
        body,
        data: dataPayload,
      });
    }

    return { success: true, message: 'Customer notified of accepted booking' };
  }

  /**
   * 2b. Zomato Style Live Progress Notification: Driver Initiated / Started Riding
   */
  async notifyCustomerTripStarted({
    bookingId,
    customerId,
    driverName,
    destinationAddress,
    vehiclePlate,
    vehicleModel,
  }) {
    const db = this.getDb();
    console.log(`[NotificationService] Trip started for booking ${bookingId}. Dispatching live tracker notification...`);

    const title = 'Ride in progress · District Car';
    const body = `On time | Heading to ${destinationAddress || 'Destination'}. Driven by ${driverName || 'Partner Driver'} (${vehicleModel || 'Cab'} · ${vehiclePlate || ''})`;

    const dataPayload = {
      type: 'trip_started',
      status: 'in_progress',
      bookingId,
      driverName: driverName || '',
      destinationAddress: destinationAddress || '',
      vehiclePlate: vehiclePlate || '',
      vehicleModel: vehicleModel || '',
      channelId: 'district_car_rides',
    };

    if (db) {
      try {
        await clientAddDoc(clientCollection(db, 'notifications'), {
          title,
          body,
          targetAudience: 'customers',
          targetUserId: customerId,
          type: 'trip_started',
          bookingId,
          status: 'delivered',
          sentAt: clientServerTimestamp(),
        });
      } catch (_) {}

      try {
        await clientAddDoc(
          clientCollection(db, 'users', customerId, 'inbox_notifications'),
          {
            title,
            body,
            bookingId,
            driverName,
            destinationAddress,
            sentAt: clientServerTimestamp(),
            isRead: false,
          }
        );
      } catch (_) {}
    }

    let token = null;
    if (db) {
      try {
        const userDocRef = clientDoc(db, 'users', customerId);
        const userSnap = await clientGetDoc(userDocRef);
        token = userSnap.data()?.fcmToken;
      } catch (_) {}
    }

    if (token) {
      await this.firebase.sendPushNotification({
        target: token,
        title,
        body,
        data: dataPayload,
      });
    } else {
      await this.firebase.sendPushNotification({
        target: `/topics/customer_${customerId}`,
        title,
        body,
        data: dataPayload,
      });
    }

    return { success: true, message: 'Customer notified of trip in progress' };
  }

  /**
   * 3. Upcoming Booking Reminder: Send to both Customer & Driver
   */
  async notifyUpcomingBookingReminder({
    bookingId,
    customerId,
    driverId,
    pickupTime,
    pickupAddress,
    destinationAddress,
  }) {
    const db = this.getDb();
    console.log(`[NotificationService] Dispatching upcoming ride reminder for booking ${bookingId}`);

    const customerTitle = '⏰ Your District Car Ride is Coming Soon!';
    const customerBody = `Your scheduled trip from ${pickupAddress || 'Pickup'} is scheduled soon (${pickupTime || 'Today'}). Your driver is preparing!`;

    const driverTitle = '⏰ Upcoming Scheduled Ride Alert!';
    const driverBody = `You have an assigned ride starting soon from ${pickupAddress || 'Pickup'} to ${destinationAddress || 'Drop'}. Please be ready on time!`;

    const dataPayload = {
      type: 'upcoming_booking_reminder',
      bookingId,
      pickupTime: pickupTime || '',
    };

    // 1. Notify Customer
    if (customerId && db) {
      try {
        const userSnap = await clientGetDoc(clientDoc(db, 'users', customerId));
        const token = userSnap.data()?.fcmToken;

        await clientAddDoc(clientCollection(db, 'users', customerId, 'inbox_notifications'), {
          title: customerTitle,
          body: customerBody,
          bookingId,
          sentAt: clientServerTimestamp(),
          isRead: false,
        });

        if (token) {
          await this.firebase.sendPushNotification({
            target: token,
            title: customerTitle,
            body: customerBody,
            data: dataPayload,
          });
        }

        await this.firebase.sendPushNotification({
          target: `/topics/customer_${customerId}`,
          title: customerTitle,
          body: customerBody,
          data: dataPayload,
        });
      } catch (err) {
        console.warn('Customer reminder notice:', err.message);
      }
    }

    // 2. Notify Driver
    if (driverId && db) {
      try {
        const driverSnap = await clientGetDoc(clientDoc(db, 'drivers', driverId));
        const token = driverSnap.data()?.fcmToken;

        await clientAddDoc(clientCollection(db, 'drivers', driverId, 'inbox_notifications'), {
          title: driverTitle,
          body: driverBody,
          bookingId,
          sentAt: clientServerTimestamp(),
          isRead: false,
        });

        if (token) {
          await this.firebase.sendPushNotification({
            target: token,
            title: driverTitle,
            body: driverBody,
            data: dataPayload,
          });
        }

        await this.firebase.sendPushNotification({
          target: `/topics/driver_${driverId}`,
          title: driverTitle,
          body: driverBody,
          data: dataPayload,
        });
      } catch (err) {
        console.warn('Driver reminder notice:', err.message);
      }
    }

    return { success: true };
  }

  /**
   * 4. User Engagement Campaign: Send Tours & Travel Push Notification with Hindi jokes and locations
   */
  async sendTravelEngagementCampaign(campaignOverride = null) {
    const db = this.getDb();
    const campaign =
      campaignOverride ||
      travelCampaigns[Math.floor(Math.random() * travelCampaigns.length)];

    console.log(`[NotificationService] Broadcasting Travel Campaign: ${campaign.title} (${campaign.place})`);

    const title = campaign.title;
    const body = `${campaign.body}\n💡 "${campaign.hindiJoke}"`;
    const imageUrl = campaign.imageUrl;

    const dataPayload = {
      type: 'travel_campaign',
      campaignId: campaign.id,
      place: campaign.place,
      district: campaign.district,
      suggestedVehicle: campaign.suggestedVehicle || 'suv',
    };

    if (db) {
      // 1. Record broadcast in 'notifications' collection
      try {
        await clientAddDoc(clientCollection(db, 'notifications'), {
          title,
          body,
          imageUrl,
          targetAudience: 'customers',
          type: 'travel_campaign',
          campaignId: campaign.id,
          place: campaign.place,
          district: campaign.district,
          status: 'delivered',
          sentAt: clientServerTimestamp(),
        });
      } catch (_) {}

      // 2. Also register in 'banner_offers' collection for customer home screen
      try {
        await clientSetDoc(
          clientDoc(db, 'banner_offers', `campaign_${campaign.id}`),
          {
            title,
            description: body,
            imageUrl,
            target: 'customers',
            place: campaign.place,
            district: campaign.district,
            isActive: true,
            createdAt: clientServerTimestamp(),
          },
          { merge: true }
        );
      } catch (_) {}
    }

    // 3. Dispatch to customers topic and all_users topic
    await this.firebase.sendPushNotification({
      target: '/topics/customers',
      title,
      body,
      imageUrl,
      data: dataPayload,
    });

    await this.firebase.sendPushNotification({
      target: '/topics/all_users',
      title,
      body,
      imageUrl,
      data: dataPayload,
    });

    // 4. Send to Customer inboxes
    if (db) {
      try {
        const usersSnap = await clientGetDocs(clientCollection(db, 'users'));
        for (const uDoc of usersSnap.docs) {
          const u = uDoc.data();
          const token = u.fcmToken;

          try {
            await clientAddDoc(
              clientCollection(db, 'users', uDoc.id, 'inbox_notifications'),
              {
                title,
                body,
                imageUrl,
                sentAt: clientServerTimestamp(),
                isRead: false,
                type: 'travel_campaign',
              }
            );
          } catch (_) {}

          if (token) {
            await this.firebase.sendPushNotification({
              target: token,
              title,
              body,
              imageUrl,
              data: dataPayload,
            });
          }
        }
      } catch (e) {
        console.warn('Customer bulk send notice:', e.message);
      }
    }

    return {
      success: true,
      campaign,
      message: `Travel campaign "${campaign.title}" dispatched successfully`,
    };
  }

  /**
   * 5. General Admin Custom Broadcast
   */
  async sendAdminBroadcast({ title, body, imageUrl, targetAudience = 'all', extraData = {} }) {
    const db = this.getDb();
    console.log(`[NotificationService] Admin Broadcast: "${title}" to audience "${targetAudience}"`);

    let notifId = null;
    if (db) {
      try {
        const docRef = await clientAddDoc(clientCollection(db, 'notifications'), {
          title,
          body,
          imageUrl: imageUrl || null,
          targetAudience,
          type: 'broadcast',
          status: 'delivered',
          sentAt: clientServerTimestamp(),
        });
        notifId = docRef.id;
      } catch (_) {}
    }

    const topic =
      targetAudience === 'drivers'
        ? '/topics/drivers'
        : targetAudience === 'customers'
        ? '/topics/customers'
        : '/topics/all_users';

    const res = await this.firebase.sendPushNotification({
      target: topic,
      title,
      body,
      imageUrl: imageUrl || null,
      data: {
        notificationId: notifId || '',
        targetAudience,
        ...extraData,
      },
    });

    return {
      success: true,
      notificationId: notifId,
      pushResult: res,
    };
  }

  /**
   * 6. Send SMS via APITXT.com GET API
   */
  async sendApitxtSms({ mobile, message, otp }) {
    let cleanMobile = String(mobile || '').replace(/[^0-9]/g, '');
    if (cleanMobile.length === 10) cleanMobile = '91' + cleanMobile;
    const safeOtp = String(otp || Math.floor(100000 + Math.random() * 900000)).replace(/[^0-9]/g, '').slice(-6).padStart(6, '9');
    const authKey = 'sCopxtBHXm_Z2wlY8q5zGWejD0S8MDnrv4K1wI1oKHg';
    const endpoint = 'https://apitxt.com/api/sendOTP';

    try {
      const response = await axios.get(endpoint, {
        params: {
          authkey: authKey,
          mobile: cleanMobile,
          otp: safeOtp,
          message: message || 'District Car: Alert'
        },
        timeout: 10000
      });
      console.log(`✅ [NotificationService:APITXT] SMS delivered to ${cleanMobile}:`, response.data);
      return { success: true, mobile: cleanMobile, data: response.data };
    } catch (err) {
      console.error(`❌ [NotificationService:APITXT] Failed to send SMS to ${cleanMobile}:`, err.message);
      return { success: false, mobile: cleanMobile, error: err.message };
    }
  }

  /**
   * 7. Send APITXT Booking Alert to Both Admin Numbers (+919142127512, +918789601387)
   */
  async sendApitxtBookingAlert({ bookingId, readableId, pickupAddress, destinationAddress, estimatedFare, rideOtp }) {
    const adminNumbers = ['919142127512', '918789601387'];
    const rId = readableId || (bookingId ? bookingId.substring(0, 6).toUpperCase() : 'NEW');
    const shortPickup = (pickupAddress || 'Pickup').length > 25 ? (pickupAddress || 'Pickup').substring(0, 22) + '...' : (pickupAddress || 'Pickup');
    const shortDrop = (destinationAddress || 'Drop').length > 25 ? (destinationAddress || 'Drop').substring(0, 22) + '...' : (destinationAddress || 'Drop');
    const fare = Math.round(Number(estimatedFare || 0));
    const otpCode = String(rideOtp || rId || Math.floor(100000 + Math.random() * 900000)).replace(/[^0-9]/g, '').slice(-6).padStart(6, '9');
    const smsMessage = `District Car: New Booking #${rId}! From: ${shortPickup} To: ${shortDrop} Fare: Rs.${fare}`;

    console.log(`🚨 [NotificationService] Dispatching APITXT SMS for Booking #${rId} to admins (+919142127512, +918789601387)...`);

    const results = [];
    for (const num of adminNumbers) {
      const res = await this.sendApitxtSms({
        mobile: num,
        message: smsMessage,
        otp: otpCode
      });
      results.push(res);
    }
    return results;
  }

  /**
   * 8. Send Targeted Notification (Specific Customer, Specific Driver, or Broadcast)
   */
  async sendCustomNotification({
    targetAudience = 'all_customers',
    targetUserId = null,
    targetUserName = null,
    targetPhone = null,
    title,
    body,
    priority = 'high',
    imageUrl = null,
    extraData = {}
  }) {
    const db = this.getDb();
    let notifId = null;

    if (db) {
      try {
        const docRef = await clientAddDoc(clientCollection(db, 'notifications'), {
          title,
          body,
          imageUrl: imageUrl || null,
          targetAudience,
          targetUserId: targetUserId || null,
          targetUserName: targetUserName || null,
          targetPhone: targetPhone || null,
          priority,
          sentBy: 'Admin HQ',
          sentAt: clientServerTimestamp()
        });
        notifId = docRef.id;

        // Deliver to personal in-app inbox
        if (targetAudience === 'specific_customer' && targetUserId) {
          await clientAddDoc(clientCollection(db, 'users', targetUserId, 'inbox_notifications'), {
            title,
            body,
            priority,
            isRead: false,
            sentAt: clientServerTimestamp()
          }).catch(() => {});
        } else if (targetAudience === 'specific_driver' && targetUserId) {
          await clientAddDoc(clientCollection(db, 'drivers', targetUserId, 'inbox_notifications'), {
            title,
            body,
            priority,
            isRead: false,
            sentAt: clientServerTimestamp()
          }).catch(() => {});
        }
      } catch (e) {
        console.warn('[NotificationService] Firestore notification log notice:', e.message);
      }
    }

    // Determine FCM target
    let target = '/topics/all_users';
    if (targetAudience === 'all_customers') target = '/topics/customers';
    else if (targetAudience === 'all_drivers') target = '/topics/drivers';
    else if (targetUserId) {
      // Look up FCM token if available
      try {
        const col = targetAudience === 'specific_driver' ? 'drivers' : 'users';
        const userSnap = await clientGetDoc(clientDoc(db, col, targetUserId));
        if (userSnap.exists()) {
          const uData = userSnap.data();
          if (uData.fcmToken) target = uData.fcmToken;
        }
      } catch (_) {}
    }

    const pushRes = await this.firebase.sendPushNotification({
      target,
      title,
      body,
      imageUrl,
      data: {
        notificationId: notifId || '',
        targetAudience,
        priority,
        ...extraData
      }
    });

    return {
      success: true,
      notificationId: notifId,
      pushResult: pushRes
    };
  }

}

module.exports = new NotificationService();
