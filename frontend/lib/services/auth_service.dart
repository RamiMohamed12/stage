import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_endpoints.dart';
import './token_service.dart'; // Import TokenService

class AuthService {
  final TokenService _tokenService = TokenService(); // Instantiate TokenService

  static Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final Map<String, dynamic> responseBody = json.decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': responseBody};
    } else {
      return {'success': false, 'message': responseBody['message'] ?? 'An unknown error occurred', 'errors': responseBody['errors']};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async { // Made login non-static
    try {
      final res = await http.post(
        Uri.parse('${ApiEndpoints.user}/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );
      final result = await _handleResponse(res);
      if (result['success'] && result['data'] != null && result['data']['token'] != null) {
        await _tokenService.saveToken(result['data']['token']);
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> signup({ // Made signup non-static
    required String email,
    required String password,
    String? firstName,
    String? lastName,
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
        Uri.parse('${ApiEndpoints.user}/signup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      final result = await _handleResponse(res);
      if (result['success'] && result['data'] != null && result['data']['token'] != null) {
        await _tokenService.saveToken(result['data']['token']);
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<void> logout() async {
    await _tokenService.deleteToken();
    // Potentially notify backend about logout if necessary
  }
}