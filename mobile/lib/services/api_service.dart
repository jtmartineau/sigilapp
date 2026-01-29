import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator to access localhost
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  Future<List<String>> processIncantation(
    String incantation,
    String? token,
  ) async {
    final url = Uri.parse('$baseUrl/process-incantation/');

    // For now, we might not have a real token if using the mock auth,
    // so we'll handle that gracefully or ensure we only call this when we have one.
    // In a real app, the token comes from AuthService.

    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'incantation': incantation}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> consonants = data['consonants'];
        return consonants.cast<String>();
      } else {
        throw Exception('Failed to process incantation: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }
}
