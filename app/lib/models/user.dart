class User {
  final String id;
  final String phoneNumber;
  final String firebaseUid;
  final String fullName;
  final String role; // 'owner' | 'farmer' | 'both'
  final String gnDivision;
  final String preferredLang;

  User({
    required this.id,
    required this.phoneNumber,
    required this.firebaseUid,
    required this.fullName,
    required this.role,
    required this.gnDivision,
    this.preferredLang = 'en',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      phoneNumber: json['phone_number'] as String,
      firebaseUid: json['firebase_uid'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      gnDivision: json['gn_division'] as String,
      preferredLang: json['preferred_lang'] as String? ?? 'en',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'firebase_uid': firebaseUid,
      'full_name': fullName,
      'role': role,
      'gn_division': gnDivision,
      'preferred_lang': preferredLang,
    };
  }
}
