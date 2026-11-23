import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/admin_stats.dart';
import '../models/audit_log.dart';
import '../models/user.dart';
import '../models/machine.dart';

class AdminApiService {
  static String? adminToken = 'dev_admin_admin@govipala.lk';

  static Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (adminToken != null) 'Authorization': 'Bearer $adminToken',
    };
  }

  /// Fetch dashboard stats
  static Future<AdminDashboardStats> fetchStats() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/admin/stats'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return AdminDashboardStats.fromJson(data);
    } else {
      throw Exception('Failed to load admin stats: ${response.statusCode}');
    }
  }

  /// Fetch users with filters
  static Future<List<UserModel>> fetchUsers({
    String? role,
    String? status,
    String? gnDivision,
    String? query,
  }) async {
    final queryParams = <String, String>{};
    if (role != null && role.isNotEmpty) queryParams['role'] = role;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (gnDivision != null && gnDivision.isNotEmpty) queryParams['gn_division'] = gnDivision;
    if (query != null && query.isNotEmpty) queryParams['q'] = query;

    final uri = Uri.parse('${ApiService.baseUrl}/admin/users').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['users'] as List<dynamic>? ?? [];
      return list.map((json) => UserModel.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load users: ${response.statusCode}');
    }
  }

  /// Update user status (active, suspended, deleted) with mandatory reason
  static Future<UserModel> updateUserStatus(
    String userId, {
    required String status,
    required String reason,
  }) async {
    final response = await http.patch(
      Uri.parse('${ApiService.baseUrl}/admin/users/$userId/status'),
      headers: _headers(),
      body: jsonEncode({
        'status': status,
        'reason': reason,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Failed to update user status');
    }
  }

  /// Create a user on someone's behalf
  static Future<UserModel> createUser({
    required String fullName,
    required String role,
    String? phoneNumber,
    String? email,
    String? gnDivision,
    String preferredLang = 'si',
    String? reason,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/admin/users'),
      headers: _headers(),
      body: jsonEncode({
        'full_name': fullName,
        'role': role,
        'phone_number': phoneNumber,
        'email': email,
        'gn_division': gnDivision,
        'preferred_lang': preferredLang,
        'reason': reason,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Failed to create user');
    }
  }

  /// Fetch machines
  static Future<List<MachineModel>> fetchMachines({
    String? machineType,
    bool? isActive,
    String? query,
  }) async {
    final queryParams = <String, String>{};
    if (machineType != null && machineType.isNotEmpty) queryParams['machine_type'] = machineType;
    if (isActive != null) queryParams['is_active'] = isActive.toString();
    if (query != null && query.isNotEmpty) queryParams['q'] = query;

    final uri = Uri.parse('${ApiService.baseUrl}/admin/machines').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['machines'] as List<dynamic>? ?? [];
      return list.map((json) => MachineModel.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load machines: ${response.statusCode}');
    }
  }

  /// Deactivate a machine on owner's behalf
  static Future<void> deactivateMachine(
    String machineId, {
    required String reason,
  }) async {
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/admin/machines/$machineId'),
      headers: _headers(),
      body: jsonEncode({'reason': reason}),
    );

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Failed to deactivate machine');
    }
  }

  /// Fetch audit logs
  static Future<List<AuditLogItem>> fetchAuditLogs({
    String? targetTable,
    String? adminId,
  }) async {
    final queryParams = <String, String>{};
    if (targetTable != null && targetTable.isNotEmpty) queryParams['target_table'] = targetTable;
    if (adminId != null && adminId.isNotEmpty) queryParams['admin_id'] = adminId;

    final uri = Uri.parse('${ApiService.baseUrl}/admin/audit-log').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['logs'] as List<dynamic>? ?? [];
      return list.map((json) => AuditLogItem.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load audit logs: ${response.statusCode}');
    }
  }
}
