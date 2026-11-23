import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null && _token != null;

  /// Load session from local storage on app start
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('govi_auth_token');

    if (_token != null) {
      ApiService.authToken = _token;
      try {
        _currentUser = await ApiService.getMe();
      } catch (_) {
        // Token might be expired or backend unreachable
      }
    }
    notifyListeners();
  }

  /// Verify phone OTP (or mock dev auth)
  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    _isLoading = true;
    notifyListeners();

    try {
      // In pilot / dev environment: generate standard auth token
      final devToken = 'dev_farmer_$phoneNumber';
      _token = devToken;
      ApiService.authToken = devToken;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('govi_auth_token', devToken);

      // Check if user already exists
      _currentUser = await ApiService.getMe();
      _isLoading = false;
      notifyListeners();
      return _currentUser != null; // True if registered, false if registration needed
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Complete registration
  Future<void> register({
    required String fullName,
    required UserRole role,
    required String gnDivision,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await ApiService.registerUser(
        fullName: fullName,
        role: role,
        gnDivision: gnDivision,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Logout
  Future<void> logout() async {
    _currentUser = null;
    _token = null;
    ApiService.authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('govi_auth_token');
    notifyListeners();
  }
}
