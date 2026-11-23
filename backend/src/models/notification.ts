export interface NotificationRecord {
  id: string;
  user_id: string;
  booking_id: string | null;
  channel: 'push' | 'sms';
  title?: string;
  message: string;
  sent_at: Date;
  delivery_status: 'sent' | 'delivered' | 'failed';
  read?: boolean;
}
