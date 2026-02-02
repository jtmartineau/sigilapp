import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 10.0.2.2 for Android emulator to access localhost
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  Future<List<dynamic>> getSigils(String token) async {
    final url = Uri.parse('$baseUrl/sigils/');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load sigils: ${response.body}');
    }
  }

  Future<void> uploadSigil(
    String incantation,
    File imageFile,
    bool isBurned,
    String? token, {
    double? lat,
    double? long,
    double? burnedLat,
    double? burnedLong,
    String? layoutType,
    int? vertexCount,
    dynamic letterAssignment,
    String? id,
  }) async {
    final url = Uri.parse('$baseUrl/sigils/');
    var request = http.MultipartRequest('POST', url);

    if (token != null) {
      request.headers['Authorization'] = 'Token $token';
    }

    request.fields['incantation'] = incantation;
    request.fields['is_burned'] = isBurned.toString();

    if (id != null) request.fields['id'] = id;

    if (layoutType != null) request.fields['layout_type'] = layoutType;
    if (vertexCount != null)
      request.fields['vertex_count'] = vertexCount.toString();
    if (letterAssignment != null)
      request.fields['letter_assignment'] = jsonEncode(letterAssignment);

    if (lat != null) request.fields['created_lat'] = lat.toString();
    if (long != null) request.fields['created_long'] = long.toString();
    if (burnedLat != null) request.fields['burned_lat'] = burnedLat.toString();
    if (burnedLong != null)
      request.fields['burned_long'] = burnedLong.toString();

    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    var response = await request.send();
    if (response.statusCode != 201) {
      final respStr = await response.stream.bytesToString();
      throw Exception('Failed to upload sigil: $respStr');
    }
  }

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

  Future<void> burnSigil(
    String id,
    String? token, {
    double? burnedLat,
    double? burnedLong,
  }) async {
    final url = Uri.parse('$baseUrl/sigils/$id/burn/');

    final body = {
      'is_burned': 'true',
      if (burnedLat != null) 'burned_lat': burnedLat.toString(),
      if (burnedLong != null) 'burned_long': burnedLong.toString(),
    };

    final headers = {if (token != null) 'Authorization': 'Token $token'};

    var request = http.MultipartRequest('PATCH', url);
    request.fields.addAll(body);
    if (token != null) {
      request.headers.addAll(headers);
    }

    var response = await request.send();

    if (response.statusCode != 200) {
      final respStr = await response.stream.bytesToString();
      throw Exception('Failed to burn sigil: $respStr');
    }
  }
}
