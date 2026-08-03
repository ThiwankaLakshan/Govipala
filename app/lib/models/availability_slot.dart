class AvailabilitySlot {
  final String id;
  final String machineId;
  final String slotDate; // yyyy-MM-dd
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final String status; // 'open' | 'pending' | 'booked' | 'blocked'

  AvailabilitySlot({
    required this.id,
    required this.machineId,
    required this.slotDate,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      id: json['id'] as String,
      machineId: json['machine_id'] as String,
      slotDate: json['slot_date'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      status: json['status'] as String,
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
