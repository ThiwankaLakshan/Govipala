class BookingModel {
  final String id;
  final String slotId;
  final String farmerId;
  final String? landLocation;
  final String status; // requested, confirmed, rejected, in_progress, completed, cancelled
  final String? createdByAdmin;
  final DateTime requestedAt;
  final DateTime? respondedAt;
  final DateTime? completedAt;
  final String? cancellationReason;

  // Joined display details
  final String? farmerName;
  final String? farmerPhone;
  final String? farmerGnDivision;
  final String? ownerId;
  final String? ownerName;
  final String? ownerPhone;
  final String? machineId;
  final String? machineBrand;
  final String? machineModel;
  final String? machineType;
  final String? driveType;
  final double? rateAmount;
  final String? rateUnit;
  final String? slotDate;
  final String? startTime;
  final String? endTime;

  const BookingModel({
    required this.id,
    required this.slotId,
    required this.farmerId,
    this.landLocation,
    required this.status,
    this.createdByAdmin,
    required this.requestedAt,
    this.respondedAt,
    this.completedAt,
    this.cancellationReason,
    this.farmerName,
    this.farmerPhone,
    this.farmerGnDivision,
    this.ownerId,
    this.ownerName,
    this.ownerPhone,
    this.machineId,
    this.machineBrand,
    this.machineModel,
    this.machineType,
    this.driveType,
    this.rateAmount,
    this.rateUnit,
    this.slotDate,
    this.startTime,
    this.endTime,
  });

  bool get isRequested => status == 'requested';
  bool get isConfirmed => status == 'confirmed';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';

  String get statusSinhala {
    switch (status) {
      case 'requested':
        return 'ඉල්ලීම යවා ඇත (Pending)';
      case 'confirmed':
        return 'තහවුරු කරන ලදී (Confirmed)';
      case 'in_progress':
        return 'ක්‍රියාත්මක වෙමින් පවතී (In Progress)';
      case 'completed':
        return 'සම්පූර්ණයි (Completed)';
      case 'rejected':
        return 'ප්‍රතික්ෂේප විය (Rejected)';
      case 'cancelled':
        return 'අවලංගු විය (Cancelled)';
      default:
        return status;
    }
  }

  String get formattedRate {
    if (rateAmount == null) return '';
    final rateStr = 'රු. ${rateAmount!.toStringAsFixed(0)}';
    switch (rateUnit) {
      case 'hour':
        return '$rateStr / පැය (Hour)';
      case 'day':
        return '$rateStr / දින (Day)';
      case 'acre':
        return '$rateStr / අක්කර (Acre)';
      default:
        return rateStr;
    }
  }

  String get formattedTimeRange {
    if (startTime == null || endTime == null) return '';
    final sParts = startTime!.split(':');
    final eParts = endTime!.split(':');
    final sStr = sParts.length >= 2 ? '${sParts[0]}:${sParts[1]}' : startTime!;
    final eStr = eParts.length >= 2 ? '${eParts[0]}:${eParts[1]}' : endTime!;
    return '$sStr - $eStr';
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String? ?? '',
      slotId: json['slot_id'] as String? ?? '',
      farmerId: json['farmer_id'] as String? ?? '',
      landLocation: json['land_location'] as String?,
      status: json['status'] as String? ?? 'requested',
      createdByAdmin: json['created_by_admin'] as String?,
      requestedAt: json['requested_at'] != null
          ? DateTime.tryParse(json['requested_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      respondedAt: json['responded_at'] != null
          ? DateTime.tryParse(json['responded_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      cancellationReason: json['cancellation_reason'] as String?,
      farmerName: json['farmer_name'] as String?,
      farmerPhone: json['farmer_phone'] as String?,
      farmerGnDivision: json['farmer_gn_division'] as String?,
      ownerId: json['owner_id'] as String?,
      ownerName: json['owner_name'] as String?,
      ownerPhone: json['owner_phone'] as String?,
      machineId: json['machine_id'] as String?,
      machineBrand: json['machine_brand'] as String?,
      machineModel: json['machine_model'] as String?,
      machineType: json['machine_type'] as String?,
      driveType: json['drive_type'] as String?,
      rateAmount: json['rate_amount'] != null ? (json['rate_amount'] as num).toDouble() : null,
      rateUnit: json['rate_unit'] as String?,
      slotDate: json['slot_date'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slot_id': slotId,
      'farmer_id': farmerId,
      'land_location': landLocation,
      'status': status,
      'created_by_admin': createdByAdmin,
      'requested_at': requestedAt.toIso8601String(),
      'cancellation_reason': cancellationReason,
    };
  }
}
