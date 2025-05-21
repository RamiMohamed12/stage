import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  static const String _baseUrl = 'http://192.168.125.17:3000/api/users';

  static Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final Map<String, dynamic> responseBody = json.decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': responseBody};
    } else {
      return {'success': false, 'message': responseBody['message'] ?? 'An unknown error occurred'};
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    String? firstName, // Optional, align with your backend's CreateUserInput
    String? lastName,  // Optional, align with your backend's CreateUserInput
  }) async {
    try {
      final Map<String, dynamic> body = {
        'email': email,
        'password': password,
      };
      if (firstName != null && firstName.isNotEmpty) {
        body['first_name'] = firstName;
      }
      if (lastName != null && lastName.isNotEmpty) {
        body['last_name'] = lastName;
      }

      final res = await http.post(
        Uri.parse('$_baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}