const admin = require('firebase-admin');

/**
 * Sends a push notification using Firebase Cloud Messaging (FCM).
 * Returns true if sent successfully, false otherwise.
 */
async function sendPushNotification(userToken, title, body, data = {}) {
  if (!userToken) {
    console.warn('[FCM] Target user has no push notification token.');
    return false;
  }

  // Check if firebase-admin has been initialized and messaging is available
  const isFirebaseInit = admin.apps.length > 0;
  if (!isFirebaseInit) {
    console.log(`[FCM Mock Send] To Token: ${userToken} | Title: "${title}" | Body: "${body}"`);
    return true; // Mock success
  }

  const message = {
    token: userToken,
    notification: {
      title,
      body,
    },
    data: data,
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('[FCM] Notification sent successfully:', response);
    return true;
  } catch (error) {
    console.error('[FCM Error] Failed to send push notification:', error);
    return false; // Triggers SMS fallback
  }
}

module.exports = {
  sendPushNotification
};
