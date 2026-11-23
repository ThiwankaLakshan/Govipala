enum ConnectionStateStatus { online, offline, syncing }

class QueuedBooking {
  final String id;
  final String slotId;
  final String landLocation;
  final DateTime createdAt;

  QueuedBooking({
    required this.id,
    required this.slotId,
    required this.landLocation,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'slot_id': slotId,
        'land_location': landLocation,
        'created_at': createdAt.toIso8601String(),
      };

  factory QueuedBooking.fromJson(Map<String, dynamic> json) => QueuedBooking(
        id: json['id'] as String,
        slotId: json['slot_id'] as String,
        landLocation: json['land_location'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
