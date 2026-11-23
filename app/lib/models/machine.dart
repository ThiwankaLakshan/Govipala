enum MachineType {
  fourWheelTractor('four_wheel_tractor', 'හතර රෝද ට්‍රැක්ටර්', '4-Wheel Tractor'),
  twoWheelTractor('two_wheel_tractor', 'අත් ට්‍රැක්ටර්', '2-Wheel Hand Tractor'),
  combineHarvester('combine_harvester', 'අස්වනු නෙලන යන්ත්‍ර', 'Combine Harvester'),
  waterPump('water_pump', 'ජල පොම්ප', 'Water Pump');

  final String value;
  final String sinhalaLabel;
  final String englishLabel;

  const MachineType(this.value, this.sinhalaLabel, this.englishLabel);

  static MachineType fromValue(String value) {
    return MachineType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MachineType.fourWheelTractor,
    );
  }
}

enum DriveType {
  twoWheel('2wd', '2WD (දෙරෝද ධාවනය)'),
  fourWheel('4wd', '4WD (සිව් රෝද ධාවනය)');

  final String value;
  final String label;

  const DriveType(this.value, this.label);

  static DriveType? fromValue(String? value) {
    if (value == null) return null;
    return DriveType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DriveType.twoWheel,
    );
  }
}

enum RateUnit {
  hour('hour', 'පැයකට (Hour)'),
  day('day', 'දිනකට (Day)'),
  acre('acre', 'අක්කරයකට (Acre)');

  final String value;
  final String label;

  const RateUnit(this.value, this.label);

  static RateUnit fromValue(String value) {
    return RateUnit.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RateUnit.hour,
    );
  }
}

class MachineModel {
  final String id;
  final String ownerId;
  final MachineType machineType;
  final String brand;
  final DriveType? driveType;
  final String? modelName;
  final double rateAmount;
  final RateUnit rateUnit;
  final String? photoUrl;
  final List<String> serviceGnDivisions;
  final bool isActive;
  final DateTime createdAt;
  final String? ownerName;
  final String? ownerPhone;
  final String? ownerGnDivision;
  final double averageRating;
  final int reviewCount;

  MachineModel({
    required this.id,
    required this.ownerId,
    required this.machineType,
    required this.brand,
    this.driveType,
    this.modelName,
    required this.rateAmount,
    required this.rateUnit,
    this.photoUrl,
    required this.serviceGnDivisions,
    required this.isActive,
    required this.createdAt,
    this.ownerName,
    this.ownerPhone,
    this.ownerGnDivision,
    this.averageRating = 0.0,
    this.reviewCount = 0,
  });

  String get displayTitle => '$brand ${machineType.sinhalaLabel}';

  String get machineTypeSinhala => machineType.sinhalaLabel;

  String get formattedRate => 'රු. ${rateAmount.toStringAsFixed(0)} / ${rateUnit.label}';

  factory MachineModel.fromJson(Map<String, dynamic> json) {
    return MachineModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      machineType: MachineType.fromValue(json['machine_type'] as String),
      brand: json['brand'] as String,
      driveType: DriveType.fromValue(json['drive_type'] as String?),
      modelName: json['model_name'] as String?,
      rateAmount: (json['rate_amount'] is num)
          ? (json['rate_amount'] as num).toDouble()
          : double.tryParse(json['rate_amount'].toString()) ?? 0.0,
      rateUnit: RateUnit.fromValue(json['rate_unit'] as String),
      photoUrl: json['photo_url'] as String?,
      serviceGnDivisions: json['service_gn_divisions'] != null
          ? List<String>.from(json['service_gn_divisions'] as List)
          : [],
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      ownerName: json['owner_name'] as String?,
      ownerPhone: json['owner_phone'] as String?,
      ownerGnDivision: json['owner_gn_division'] as String?,
      averageRating: json['average_rating'] != null
          ? (json['average_rating'] is num
              ? (json['average_rating'] as num).toDouble()
              : double.tryParse(json['average_rating'].toString()) ?? 0.0)
          : 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'machine_type': machineType.value,
      'brand': brand,
      'drive_type': driveType?.value,
      'model_name': modelName,
      'rate_amount': rateAmount,
      'rate_unit': rateUnit.value,
      'photo_url': photoUrl,
      'service_gn_divisions': serviceGnDivisions,
      'is_active': isActive,
    };
  }
}
