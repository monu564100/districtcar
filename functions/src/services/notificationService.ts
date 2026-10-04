import * as admin from 'firebase-admin';

export class NotificationService {
  /**
   * Sends FCM push notification to a specific user and records it in Firestore
   */
  static async sendToUser(
    userId: string,
    title: string,
    body: string,
    data: Record<string, string> = {}
  ): Promise<void> {
    const db = admin.firestore();

    // 1. Record notification in Firestore subcollection/collection
    await db.collection('notifications').add({
      userId,
      title,
      body,
      data,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 2. Fetch user's registered FCM tokens
    const userDoc = await db.collection('users').doc(userId).get();
    let fcmToken: string | undefined = userDoc.data()?.fcmToken;

    if (!fcmToken) {
      // Check drivers collection if not found in users
      const driverDoc = await db.collection('drivers').doc(userId).get();
      fcmToken = driverDoc.data()?.fcmToken;
    }

    if (fcmToken) {
      try {
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title,
            body,
          },
          data: {
            ...data,
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
          android: {
            priority: 'high',
            notification: {
              sound: 'default',
              channelId: 'district_car_high_importance',
            },
          },
          apns: {
            payload: {
              aps: {
                sound: 'default',
                badge: 1,
              },
            },
          },
        });
      } catch (err) {
        console.warn(`Failed to deliver FCM push to user ${userId}:`, err);
      }
    }
  }
}
