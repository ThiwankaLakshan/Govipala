class AvailabilitySlotModel {
  final String id;
  final String machineId;
  final String slotDate; // YYYY-MM-DD
  final String startTime; // HH:MM:SS
  final String endTime; // HH:MM:SS
  final String status; // open, pending, booked, blocked
  final DateTime? createdAt;

  const AvailabilitySlotModel({
    required this.id,
    required this.machineId,
    required this.slotDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.createdAt,
  });

  bool get isOpen => status == 'open';
  bool get isPending => status == 'pending';
  bool get isBooked => status == 'booked';
  bool get isBlocked => status == 'blocked';

  String get formattedStartTime {
    final parts = startTime.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return startTime;
  }

  String get formattedEndTime {
    final parts = endTime.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return endTime;
  }

  String get formattedTimeRange => '$formattedStartTime - $formattedEndTime';

  String get statusSinhala {
    switch (status) {
      case 'open':
        return 'ලබාගත හැක (Open)';
      case 'pending':
        return 'තහවුරු කිරීම අපේක්ෂාවෙන් (Pending)';
      case 'booked':
        return 'වෙන්කරවා ගෙන ඇත (Booked)';
      case 'blocked':
        return 'අවහිර කර ඇත (Blocked)';
      default:
        return status;
    }
  }

  factory AvailabilitySlotModel.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlotModel(
      id: json['id'] as String? ?? '',
      machineId: json['machine_id'] as String? ?? '',
      slotDate: json['slot_date'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'machine_id': machineId,
      'slot_date': slotDate,
      'start_time': startTime,
      'end_time': endTime,
      'status': status,
    };
  }
}
