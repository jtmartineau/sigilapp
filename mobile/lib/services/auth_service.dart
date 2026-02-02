import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'sigil_storage_service.dart';
import 'api_service.dart';

class AuthService with ChangeNotifier {
  static const String baseUrl = 'http://10.0.2.2:8000';

  bool _isAuthenticated = false;
  String? _token;

  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;

  Future<String?> signup(String username, String password, String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/users/'),
        body: {'username': username, 'password': password, 'email': email},
      );

      if (response.statusCode == 201) {
        return null; // Success
      } else {
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map<String, dynamic>) {
            if (errorData.containsKey('username')) {
              return errorData['username'][0];
            }
            if (errorData.containsKey('email')) {
              return errorData['email'][0];
            }
            if (errorData.containsKey('password')) {
              return errorData['password'][0];
            }
            if (errorData.containsKey('non_field_errors')) {
              return errorData['non_field_errors'][0];
            }
            // Return the first value of the first key
            return errorData.values.first.toString();
          }
          return 'Signup failed: ${response.body}';
        } catch (_) {
          return 'Signup failed: ${response.statusCode}';
        }
      }
    } catch (e) {
      debugPrint('Signup error: $e');
      return 'Connection error. Please check your internet.';
    }
  }

  Future<String?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/token/login/'),
        body: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['auth_token'];
        _isAuthenticated = true;

        // Save token for future sessions
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);

        // Fetch and sync sigils from backend
        try {
          final sigils = await ApiService().getSigils(_token!);
          await SigilStorageService().syncSigils(sigils);
        } catch (e) {
          debugPrint('Error syncing sigils during login: $e');
          // Start with fresh state if sync fails
          await SigilStorageService().clearSigils();
        }

        notifyListeners();
        return null; // Success
      } else {
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map<String, dynamic>) {
            if (errorData.containsKey('non_field_errors')) {
              return errorData['non_field_errors'][0];
            }
            // Return the first value of the first key
            return errorData.values.first.toString();
          }
          return 'Login failed: ${response.body}';
        } catch (_) {
          return 'Login failed: ${response.statusCode}';
        }
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return 'Connection error. Please check your internet.';
    }
  }

  Future<void> logout() async {
    // Optionally call /auth/token/logout/ on backend
    _isAuthenticated = false;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    // Clear local data
    await SigilStorageService().clearSigils();

    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('auth_token')) {
      _token = prefs.getString('auth_token');
      _isAuthenticated = true;
      notifyListeners();
    }
  }
}
