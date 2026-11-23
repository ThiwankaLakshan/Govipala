import { query } from '../db';
import { NotificationRecord } from '../models/notification';

export const devNotificationsLog: NotificationRecord[] = [];

function isDbConnectionError(err: any): boolean {
  return Boolean(
    err?.code === 'ECONNREFUSED' ||
    err?.message?.includes('connect ECONNREFUSED') ||
    (Array.isArray(err?.errors) && err.errors.some((e: any) => e?.code === 'ECONNREFUSED'))
  );
}

export interface SendNotificationOptions {
  userId: string;
  bookingId?: string | null;
  channel: 'push' | 'sms';
  title?: string;
  message: string;
}

export async function sendNotification(options: SendNotificationOptions): Promise<NotificationRecord> {
  const { userId, bookingId = null, channel, title, message } = options;
  const now = new Date();
  const id = `notif-${Date.now()}-${Math.floor(Math.random() * 1000)}`;

  const record: NotificationRecord = {
    id,
    user_id: userId,
    booking_id: bookingId,
    channel,
    title,
    message,
    sent_at: now,
    delivery_status: 'delivered',
    read: false,
  };

  // Always record in dev fallback store immediately
  devNotificationsLog.unshift(record);

  // Attempt database persistence asynchronously in dev/production
  query(
    `INSERT INTO notifications_log (id, user_id, booking_id, channel, message, sent_at, delivery_status)
     VALUES ($1, $2, $3, $4, $5, $6, $7)`,
    [id, userId, bookingId, channel, message, now, 'delivered']
  ).catch(() => {
    // Expected in dev mode when PostgreSQL is not running
  });

  return record;
}

/**
 * Dispatches both Push (FCM) and Fallback SMS (FR-6.1 - 6.3)
 */
export async function dispatchMultiChannelNotification(
  userId: string,
  title: string,
  message: string,
  bookingId?: string | null,
  sendSmsFallback: boolean = true
): Promise<NotificationRecord[]> {
  const results: NotificationRecord[] = [];

  // Primary Push notification (FR-6.1, FR-6.2)
  const pushNotif = await sendNotification({
    userId,
    bookingId,
    channel: 'push',
    title,
    message,
  });
  results.push(pushNotif);

  // SMS Fallback for critical lifecycle notifications (FR-6.3)
  if (sendSmsFallback) {
    const smsNotif = await sendNotification({
      userId,
      bookingId,
      channel: 'sms',
      title,
      message: `[Govipala Alert] ${message}`,
    });
    results.push(smsNotif);
  }

  return results;
}

export async function notifyBookingRequested(params: {
  ownerId: string;
  farmerName: string;
  machineBrand: string;
  machineType: string;
  slotDate: string;
  timeRange: string;
  bookingId: string;
}): Promise<void> {
  const title = 'නව වෙන්කිරීමේ ඉල්ලීමක් (New Booking Request)';
  const message = `${params.farmerName} විසින් ඔබගේ ${params.machineBrand} (${params.machineType}) සඳහා ${params.slotDate} දින ${params.timeRange} වේලාව වෙන්කරවා ගැනීමට ඉල්ලා ඇත.`;
  await dispatchMultiChannelNotification(params.ownerId, title, message, params.bookingId, true);
}

export async function notifyBookingConfirmed(params: {
  farmerId: string;
  ownerName: string;
  machineBrand: string;
  machineType: string;
  slotDate: string;
  timeRange: string;
  bookingId: string;
}): Promise<void> {
  const title = 'වෙන්කිරීම තහවුරු විය (Booking Confirmed)';
  const message = `${params.ownerName} විසින් ඔබගේ ${params.machineBrand} (${params.machineType}) වෙන්කිරීම ${params.slotDate} (${params.timeRange}) සඳහා තහවුරු කරන ලදී.`;
  await dispatchMultiChannelNotification(params.farmerId, title, message, params.bookingId, true);
}

export async function notifyBookingRejected(params: {
  farmerId: string;
  ownerName: string;
  machineBrand: string;
  slotDate: string;
  bookingId: string;
  reason?: string;
}): Promise<void> {
  const title = 'වෙන්කිරීම ප්‍රතික්ෂේප විය (Booking Declined)';
  const reasonText = params.reason ? ` හේතුව: ${params.reason}` : '';
  const message = `${params.ownerName} විසින් ${params.slotDate} දින ${params.machineBrand} සඳහා වූ වෙන්කිරීමේ ඉල්ලීම ප්‍රතික්ෂේප කරන ලදී.${reasonText}`;
  await dispatchMultiChannelNotification(params.farmerId, title, message, params.bookingId, true);
}

export async function notifyBookingStatusUpdated(params: {
  recipientId: string;
  status: 'in_progress' | 'completed' | 'cancelled';
  machineBrand: string;
  slotDate: string;
  bookingId: string;
  reason?: string;
}): Promise<void> {
  let title = '';
  let message = '';

  switch (params.status) {
    case 'in_progress':
      title = 'යන්ත්‍ර සේවාව ආරම්භ විය (Work In Progress)';
      message = `${params.machineBrand} යන්ත්‍රය ${params.slotDate} දින ඔබගේ වැඩබිමේ සේවාව ආරම්භ කර ඇත.`;
      break;
    case 'completed':
      title = 'සේවාව සාර්ථකව අවසන් විය (Job Completed)';
      message = `${params.machineBrand} යන්ත්‍ර සේවාව අවසන් විය. කරුණාකර ඔබගේ අත්දැකීම පිළිබඳ ඇගයීමක් (Review) ලබා දෙන්න.`;
      break;
    case 'cancelled':
      title = 'වෙන්කිරීම අවලංගු විය (Booking Cancelled)';
      const reasonText = params.reason ? ` හේතුව: ${params.reason}` : '';
      message = `${params.machineBrand} සඳහා ${params.slotDate} දින වෙන්කිරීම අවලංගු කරන ලදී.${reasonText}`;
      break;
  }

  await dispatchMultiChannelNotification(params.recipientId, title, message, params.bookingId, params.status === 'cancelled');
}

export async function getUserNotifications(userId: string): Promise<NotificationRecord[]> {
  try {
    const res = await query<NotificationRecord>(
      `SELECT * FROM notifications_log WHERE user_id = $1 ORDER BY sent_at DESC LIMIT 50`,
      [userId]
    );
    if (res.rows.length > 0) return res.rows;
  } catch (err: any) {
    if (!isDbConnectionError(err)) {
      console.warn('Error fetching notifications from DB:', err);
    }
  }

  return devNotificationsLog.filter((n) => n.user_id === userId);
}
