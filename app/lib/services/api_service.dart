import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/machine.dart';
import '../models/availability_slot.dart';
import '../models/booking.dart';
import '../models/notification.dart';
import '../models/review.dart';

class ApiService {
  // Uses localhost:3000 for web/desktop and 10.0.2.2:3000 for Android emulator
  static String baseUrl = kIsWeb
      ? 'http://localhost:3000/api/v1'
      : 'http://10.0.2.2:3000/api/v1';

  static String? authToken;

  static Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };
  }

  /// Fetch Padaviya GN divisions
  static Future<List<String>> asyncFetchGnDivisions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/locations/gn-divisions'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['gn_divisions']);
      }
    } catch (_) {}
    return [
      'Padaviya Town',
      'Sripura',
      'Buddhangala',
      'Parakramapura',
      'Ruwanpura',
      'Sudarshanagama',
      'Jayanthiwewa',
    ];
  }

  /// Fetch logged-in user profile (GET /users/me)
  static Future<UserModel?> getMe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  /// Register new user (POST /users/register)
  static Future<UserModel> registerUser({
    required String fullName,
    required UserRole role,
    required String gnDivision,
    String preferredLang = 'si',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/register'),
      headers: _headers(),
      body: jsonEncode({
        'full_name': fullName,
        'role': role.name,
        'gn_division': gnDivision,
        'preferred_lang': preferredLang,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Registration failed.');
    }
  }

  // ============================================
  // AUTH & LOGIN API
  // ============================================

  /// Fetch demo credentials for all roles (GET /auth/demo-credentials)
  static Future<Map<String, dynamic>> fetchDemoCredentials() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/demo-credentials'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}

    // Fallback demo credentials
    return {
      'farmer': {
        'phone': '077 555 1122',
        'password': 'farmer123',
        'name': 'අනුර කුමාර (Anura Kumara)',
        'gn_division': 'Padaviya East',
      },
      'owner': {
        'phone': '077 123 4567',
        'password': 'owner123',
        'name': 'සුනිල් පෙරේරා (Sunil Perera)',
        'gn_division': 'Padaviya Town',
      },
      'admin': {
        'email': 'admin@govipala.lk',
        'password': 'admin123',
        'name': 'පරිපාලක (Govipala Admin)',
      },
    };
  }

  /// Login with role, identifier (phone or email), and password (POST /auth/login)
  static Future<Map<String, dynamic>> loginUser({
    required String role,
    required String identifier,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers(),
      body: jsonEncode({
        'role': role,
        'identifier': identifier,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'] as String;
      authToken = token;
      final user = UserModel.fromJson(data['user']);
      return {
        'token': token,
        'user': user,
        'message': data['message'],
      };
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Login failed. Please verify credentials.');
    }
  }

  /// Direct register without SMS OTP requirement (POST /auth/register)
  static Future<Map<String, dynamic>> directRegisterUser({
    required String fullName,
    required UserRole role,
    required String phoneNumber,
    required String gnDivision,
    String? password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers(),
      body: jsonEncode({
        'full_name': fullName,
        'role': role.name,
        'phone_number': phoneNumber,
        'gn_division': gnDivision,
        if (password != null) 'password': password,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'] as String;
      authToken = token;
      final user = UserModel.fromJson(data['user']);
      return {
        'token': token,
        'user': user,
        'message': data['message'],
      };
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Registration failed.');
    }
  }

  // ============================================
  // MACHINES API (Phase 2)
  // ============================================

  /// Fetch machines matching filters (GET /machines)
  static Future<List<MachineModel>> fetchMachines({
    MachineType? machineType,
    String? gnDivision,
    String? ownerId,
    bool? isActive,
  }) async {
    final queryParams = <String, String>{};
    if (machineType != null) queryParams['machine_type'] = machineType.value;
    if (gnDivision != null && gnDivision.isNotEmpty) queryParams['gn_division'] = gnDivision;
    if (ownerId != null) queryParams['owner_id'] = ownerId;
    if (isActive != null) queryParams['is_active'] = isActive.toString();

    final uri = Uri.parse('$baseUrl/machines').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((json) => MachineModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load machines.');
    }
  }

  /// Fetch machine by ID with upcoming availability (GET /machines/:id)
  static Future<MachineModel> fetchMachineById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/machines/$id'), headers: _headers());
    if (response.statusCode == 200) {
      return MachineModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Machine not found.');
    }
  }

  /// Create a machine listing (POST /machines)
  static Future<MachineModel> createMachine({
    required MachineType machineType,
    required String brand,
    DriveType? driveType,
    String? modelName,
    required double rateAmount,
    required RateUnit rateUnit,
    String? photoUrl,
    required List<String> serviceGnDivisions,
  }) async {
    final body = <String, dynamic>{
      'machine_type': machineType.value,
      'brand': brand,
      'rate_amount': rateAmount,
      'rate_unit': rateUnit.value,
      'service_gn_divisions': serviceGnDivisions,
      if (driveType != null) 'drive_type': driveType.value,
      if (modelName != null && modelName.isNotEmpty) 'model_name': modelName,
      if (photoUrl != null && photoUrl.isNotEmpty) 'photo_url': photoUrl,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/machines'),
      headers: _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      return MachineModel.fromJson(jsonDecode(response.body));
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Failed to list machine.');
    }
  }

  /// Update machine listing (PATCH /machines/:id)
  static Future<MachineModel> updateMachine({
    required String id,
    MachineType? machineType,
    String? brand,
    DriveType? driveType,
    String? modelName,
    double? rateAmount,
    RateUnit? rateUnit,
    String? photoUrl,
    List<String>? serviceGnDivisions,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{
      if (machineType != null) 'machine_type': machineType.value,
      if (brand != null) 'brand': brand,
      if (driveType != null) 'drive_type': driveType.value,
      if (modelName != null) 'model_name': modelName,
      if (rateAmount != null) 'rate_amount': rateAmount,
      if (rateUnit != null) 'rate_unit': rateUnit.value,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (serviceGnDivisions != null) 'service_gn_divisions': serviceGnDivisions,
      if (isActive != null) 'is_active': isActive,
    };

    final response = await http.patch(
      Uri.parse('$baseUrl/machines/$id'),
      headers: _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return MachineModel.fromJson(jsonDecode(response.body));
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Failed to update machine.');
    }
  }

  /// Deactivate machine (DELETE /machines/:id)
  static Future<void> deleteMachine(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/machines/$id'), headers: _headers());
    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Failed to deactivate machine.');
    }
  }

  // ============================================
  // AVAILABILITY SLOTS (Phase 3)
  // ============================================

  /// Fetch availability slots for a machine
  static Future<List<AvailabilitySlotModel>> fetchMachineSlots(
    String machineId, {
    String? from,
    String? to,
  }) async {
    final queryParams = <String, String>{};
    if (from != null) queryParams['from'] = from;
    if (to != null) queryParams['to'] = to;

    final uri = Uri.parse('$baseUrl/machines/$machineId/availability').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((json) => AvailabilitySlotModel.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load availability slots: ${response.statusCode}');
    }
  }

  /// Create availability slots (Owner)
  static Future<int> createAvailabilitySlots(
    String machineId,
    List<Map<String, dynamic>> slots,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/machines/$machineId/availability'),
      headers: _headers(),
      body: jsonEncode({'slots': slots}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['created'] as int? ?? slots.length;
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Failed to add availability slots.');
    }
  }

  /// Delete an open slot (Owner)
  static Future<void> deleteAvailabilitySlot(String slotId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/availability/$slotId'),
      headers: _headers(),
    );

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Failed to delete slot.');
    }
  }

  // ============================================
  // BOOKINGS (Phase 3)
  // ============================================

  /// Create a booking request on an open slot (Farmer)
  static Future<BookingModel> createBooking({
    required String slotId,
    required String landLocation,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: _headers(),
      body: jsonEncode({
        'slot_id': slotId,
        'land_location': landLocation,
      }),
    );

    if (response.statusCode == 201) {
      return BookingModel.fromJson(jsonDecode(response.body));
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Failed to request booking.');
    }
  }

  /// Fetch user bookings (as farmer or as owner)
  static Future<List<BookingModel>> fetchMyBookings({required String asRole}) async {
    final uri = Uri.parse('$baseUrl/bookings/mine').replace(queryParameters: {'as': asRole});
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((json) => BookingModel.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load bookings: ${response.statusCode}');
    }
  }

  /// Owner responds to booking request (confirm or reject)
  static Future<void> respondToBooking(
    String bookingId, {
    required String action,
    String? reason,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/bookings/$bookingId/respond'),
      headers: _headers(),
      body: jsonEncode({
        'action': action,
        if (reason != null) 'reason': reason,
      }),
    );

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Failed to respond to booking.');
    }
  }

  /// Update booking lifecycle status (in_progress, completed, cancelled)
  static Future<void> updateBookingStatus(
    String bookingId, {
    required String status,
    String? reason,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/bookings/$bookingId/status'),
      headers: _headers(),
      body: jsonEncode({
        'status': status,
        if (reason != null) 'reason': reason,
      }),
    );

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Failed to update booking status.');
    }
  }

  // ============================================
  // NOTIFICATIONS (Phase 4)
  // ============================================

  /// Fetch user notifications (Push + SMS fallback history)
  static Future<List<NotificationModel>> fetchMyNotifications() async {
    final response = await http.get(Uri.parse('$baseUrl/notifications/mine'), headers: _headers());

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((json) => NotificationModel.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load notifications: ${response.statusCode}');
    }
  }

  // ============================================
  // RATINGS & REVIEWS (Phase 5)
  // ============================================

  /// Submit a review for a completed booking (FR-7.1)
  static Future<ReviewModel> createBookingReview(
    String bookingId, {
    required int rating,
    String? comment,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bookings/$bookingId/review'),
      headers: _headers(),
      body: jsonEncode({
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
      }),
    );

    if (response.statusCode == 201) {
      return ReviewModel.fromJson(jsonDecode(response.body));
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Failed to submit review.');
    }
  }

  /// Fetch reviews for a specific machine (FR-7.2)
  static Future<ReviewsListResponse> fetchMachineReviews(String machineId) async {
    final response = await http.get(Uri.parse('$baseUrl/machines/$machineId/reviews'), headers: _headers());

    if (response.statusCode == 200) {
      return ReviewsListResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to load machine reviews: ${response.statusCode}');
    }
  }

  /// Fetch public reviews for a user (FR-7.2)
  static Future<ReviewsListResponse> fetchUserReviews(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$userId/reviews'), headers: _headers());

    if (response.statusCode == 200) {
      return ReviewsListResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to load user reviews: ${response.statusCode}');
    }
  }
}
