import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService with ChangeNotifier {
  static const String baseUrl = 'http://10.0.2.2:8000';

  bool _isAuthenticated = false;
  String? _token;

  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;

  Future<bool> signup(String username, String password, String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/users/'),
        body: {'username': username, 'password': password, 'email': email},
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        debugPrint('Signup failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Signup error: $e');
    }
    return false;
  }

  Future<bool> login(String username, String password) async {
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

        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Login error: $e');
    }
    return false;
  }

  Future<void> logout() async {
    // Optionally call /auth/token/logout/ on backend
    _isAuthenticated = false;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
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
