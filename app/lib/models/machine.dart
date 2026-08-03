class Machine {
  final String id;
  final String ownerId;
  final String machineType; // 'four_wheel_tractor' | 'four_wheel_tractor_with_trailer' | 'two_wheel_tractor' | 'two_wheel_tractor_with_trailer' | 'combine_harvester'
  final String? modelName;
  final String? paddyType; // 'mud' | 'dry' (required only for field preparation tractors)
  final double rateAmount;
  final String rateUnit; // 'hour' | 'day' | 'acre'
  final String? photoUrl;
  final List<String> serviceGnDivisions;
  final bool isActive;
  final double? averageRating;
  final String? ownerName;

  Machine({
    required this.id,
    required this.ownerId,
    required this.machineType,
    this.modelName,
    this.paddyType,
    required this.rateAmount,
    required this.rateUnit,
    this.photoUrl,
    required this.serviceGnDivisions,
    this.isActive = true,
    this.averageRating,
    this.ownerName,
  });

  factory Machine.fromJson(Map<String, dynamic> json) {
    return Machine(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      machineType: json['machine_type'] as String,
      modelName: json['model_name'] as String?,
      paddyType: json['paddy_type'] as String?,
      rateAmount: double.parse(json['rate_amount'].toString()),
      rateUnit: json['rate_unit'] as String,
      photoUrl: json['photo_url'] as String?,
      serviceGnDivisions: List<String>.from(json['service_gn_divisions'] ?? []),
      isActive: json['is_active'] as bool? ?? true,
      averageRating: json['average_rating'] != null ? double.tryParse(json['average_rating'].toString()) : null,
      ownerName: json['owner_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'machine_type': machineType,
      'model_name': modelName,
      'paddy_type': paddyType,
      'rate_amount': rateAmount,
      'rate_unit': rateUnit,
      'photo_url': photoUrl,
      'service_gn_divisions': serviceGnDivisions,
      'is_active': isActive,
      'average_rating': averageRating,
      'owner_name': ownerName,
    };
  }
}
