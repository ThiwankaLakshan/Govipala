class NotificationModel {
  final String id;
  final String userId;
  final String? bookingId;
  final String channel; // 'push' | 'sms'
  final String? title;
  final String message;
  final DateTime sentAt;
  final String deliveryStatus;
  final bool read;

  const NotificationModel({
    required this.id,
    required this.userId,
    this.bookingId,
    required this.channel,
    this.title,
    required this.message,
    required this.sentAt,
    required this.deliveryStatus,
    this.read = false,
  });

  bool get isPush => channel == 'push';
  bool get isSms => channel == 'sms';

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      bookingId: json['booking_id'] as String?,
      channel: json['channel'] as String? ?? 'push',
      title: json['title'] as String?,
      message: json['message'] as String? ?? '',
      sentAt: json['sent_at'] != null
          ? DateTime.tryParse(json['sent_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      deliveryStatus: json['delivery_status'] as String? ?? 'delivered',
      read: json['read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'booking_id': bookingId,
      'channel': channel,
      'title': title,
      'message': message,
      'sent_at': sentAt.toIso8601String(),
      'delivery_status': deliveryStatus,
      'read': read,
    };
  }
}
