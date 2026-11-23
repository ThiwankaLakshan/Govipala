import { Request, Response } from 'express';
import { getUserNotifications, devNotificationsLog } from '../services/notificationService';
import { query } from '../db';
import { NotificationRecord } from '../models/notification';

export async function getMyNotifications(req: Request, res: Response): Promise<void> {
  if (!req.user) {
    res.status(401).json({ error: 'unauthorized', message: 'Authentication required.' });
    return;
  }

  const list = await getUserNotifications(req.user.id);
  res.status(200).json(list);
}

export async function getAdminNotificationLog(req: Request, res: Response): Promise<void> {
  const { channel, user_id } = req.query;

  try {
    let sql = `SELECT * FROM notifications_log WHERE 1=1`;
    const params: any[] = [];
    let idx = 1;

    if (channel) {
      sql += ` AND channel = $${idx++}`;
      params.push(channel);
    }
    if (user_id) {
      sql += ` AND user_id = $${idx++}`;
      params.push(user_id);
    }

    sql += ` ORDER BY sent_at DESC LIMIT 100`;

    const result = await query<NotificationRecord>(sql, params);
    if (result.rows.length > 0) {
      res.status(200).json(result.rows);
      return;
    }
  } catch (_) {
    // Fallback to dev log
  }

  let filtered = [...devNotificationsLog];
  if (channel) filtered = filtered.filter((n) => n.channel === channel);
  if (user_id) filtered = filtered.filter((n) => n.user_id === user_id);

  res.status(200).json(filtered);
}
