class Booking {
  final String id;
  final String slotId;
  final String farmerId;
  final String? landLocation;
  final double landSizeAcres;
  final String status; // 'requested' | 'confirmed' | 'rejected' | 'in_progress' | 'completed' | 'cancelled'
  final String requestedAt;
  final String? respondedAt;
  final String? completedAt;
  final String? cancellationReason;

  Booking({
    required this.id,
    required this.slotId,
    required this.farmerId,
    this.landLocation,
    required this.landSizeAcres,
    required this.status,
    required this.requestedAt,
    this.respondedAt,
    this.completedAt,
    this.cancellationReason,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      slotId: json['slot_id'] as String,
      farmerId: json['farmer_id'] as String,
      landLocation: json['land_location'] as String?,
      landSizeAcres: double.parse(json['land_size_acres'].toString()),
      status: json['status'] as String,
      requestedAt: json['requested_at'] as String,
      respondedAt: json['responded_at'] as String?,
      completedAt: json['completed_at'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slot_id': slotId,
      'farmer_id': farmerId,
      'land_location': landLocation,
      'land_size_acres': landSizeAcres,
      'status': status,
      'requested_at': requestedAt,
      'responded_at': respondedAt,
      'completed_at': completedAt,
      'cancellation_reason': cancellationReason,
    };
  }
}
