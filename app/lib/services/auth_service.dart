import 'dart:convert';
import 'package:flutter/material.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isProfileRegistered = false;
  String _userRole = '';
  String _authToken = '';
  String _phoneNumber = '';

  bool get isAuthenticated => _isAuthenticated;
  bool get isProfileRegistered => _isProfileRegistered;
  String get userRole => _userRole;
  String get authToken => _authToken;

  Future<void> loginWithPhone(String phoneNumber) async {
    // Store phone number to choose appropriate mock credentials during OTP check
    _phoneNumber = phoneNumber;
    debugPrint('Mock SMS trigger: OTP verification code generated for $phoneNumber');
  }

  Future<bool> verifyOtp(String code) async {
    // Choose appropriate mock token to support role switching in developer modes
    if (_phoneNumber == '+94777777777') {
      _authToken = 'mock-owner-token';
    } else if (_phoneNumber == '+94778888888') {
      _authToken = 'mock-farmer-token';
    } else {
      // Clean numbers for mock UUID token creation
      final cleanNum = _phoneNumber.replaceAll(RegExp(r'\D'), '');
      _authToken = 'mock-uid-$cleanNum';
    }

    _isAuthenticated = true;

    // Check if profile is already registered in the backend
    final apiService = ApiService(_authToken);
    try {
      final response = await apiService.get('/users/me');
      if (response.statusCode == 200) {
        final profile = jsonDecode(response.body);
        _isProfileRegistered = true;
        _userRole = profile['role'] ?? '';
      } else if (response.statusCode == 404) {
        _isProfileRegistered = false;
        _userRole = '';
      }
    } catch (e) {
      debugPrint('Auth service fetch profile error: $e');
      // Bypasses to registration state if profile not found
      _isProfileRegistered = false;
    }

    notifyListeners();
    return true;
  }

  Future<bool> registerProfile({
    required String fullName,
    required String role,
    required String gnDivision,
    String preferredLang = 'en',
  }) async {
    final apiService = ApiService(_authToken);
    final body = {
      'full_name': fullName,
      'role': role,
      'gn_division': gnDivision,
      'preferred_lang': preferredLang,
    };

    try {
      final response = await apiService.post('/users/register', body);
      if (response.statusCode == 201) {
        final profile = jsonDecode(response.body);
        _isProfileRegistered = true;
        _userRole = profile['role'] ?? role;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Registration network error: $e');
    }
    return false;
  }

  void logout() {
    _isAuthenticated = false;
    _isProfileRegistered = false;
    _userRole = '';
    _authToken = '';
    _phoneNumber = '';
    notifyListeners();
  }
}
