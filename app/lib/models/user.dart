enum UserRole { farmer, owner, both, admin }

class UserModel {
  final String id;
  final String? phoneNumber;
  final String? email;
  final String fullName;
  final UserRole role;
  final String? gnDivision;
  final String preferredLang;
  final String status;

  UserModel({
    required this.id,
    this.phoneNumber,
    this.email,
    required this.fullName,
    required this.role,
    this.gnDivision,
    required this.preferredLang,
    required this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    UserRole parsedRole;
    switch (json['role']) {
      case 'owner':
        parsedRole = UserRole.owner;
        break;
      case 'both':
        parsedRole = UserRole.both;
        break;
      case 'admin':
        parsedRole = UserRole.admin;
        break;
      case 'farmer':
      default:
        parsedRole = UserRole.farmer;
    }

    return UserModel(
      id: json['id'] as String,
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String?,
      fullName: json['full_name'] as String,
      role: parsedRole,
      gnDivision: json['gn_division'] as String?,
      preferredLang: json['preferred_lang'] as String? ?? 'si',
      status: json['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'email': email,
      'full_name': fullName,
      'role': role.name,
      'gn_division': gnDivision,
      'preferred_lang': preferredLang,
      'status': status,
    };
  }
}
