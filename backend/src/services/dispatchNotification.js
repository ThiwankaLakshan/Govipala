const db = require('../models/db');
const { sendPushNotification } = require('./notificationService');
const { sendSMS } = require('./smsService');

/**
 * Resolves a recipient's info, attempts to send a Push Notification (FCM),
 * falls back to SMS if FCM fails or token is missing, and logs details in PostgreSQL.
 */
async function dispatchNotification(userId, bookingId, title, body) {
  try {
    // 1. Fetch user phone number from DB
    const userRes = await db.query('SELECT phone_number, full_name FROM users WHERE id = $1', [userId]);
    if (userRes.rows.length === 0) {
      console.error(`[Dispatcher Error] Recipient user ${userId} not found.`);
      return false;
    }

    const user = userRes.rows[0];
    let sentChannel = 'sms';
    let deliveryStatus = 'sent';

    // Mock push token lookup. In production, this would read from a users.fcm_token column.
    // For pilot, we assume push fails or is bypassed if no token exists, triggering SMS fallback.
    const mockUserPushToken = null; 

    let pushSuccess = false;
    if (mockUserPushToken) {
      pushSuccess = await sendPushNotification(mockUserPushToken, title, body, { bookingId });
      if (pushSuccess) {
        sentChannel = 'push';
      }
    }

    // 2. Bypassed/failed push triggers SMS fallback
    if (!pushSuccess) {
      const smsSuccess = await sendSMS(user.phone_number, `${title}: ${body}`);
      if (!smsSuccess) {
        deliveryStatus = 'failed';
      }
    }

    // 3. Log into notifications_log table
    const logQueryText = `
      INSERT INTO notifications_log (user_id, booking_id, channel, message, delivery_status, sent_at)
      VALUES ($1, $2, $3, $4, $5, now())
    `;
    await db.query(logQueryText, [userId, bookingId || null, sentChannel, body, deliveryStatus]);

    return deliveryStatus === 'sent';
  } catch (error) {
    console.error('[Dispatcher Unhandled Error] Failed to process notification dispatch:', error);
    return false;
  }
}

module.exports = dispatchNotification;
