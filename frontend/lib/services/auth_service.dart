import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_endpoints.dart';
import './token_service.dart'; // Import TokenService
import './notification_service.dart'; // Import NotificationService

class AuthService {
  final TokenService _tokenService = TokenService(); // Instantiate TokenService
  final NotificationService _notificationService = NotificationService(); // Instantiate NotificationService

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
        final token = result['data']['token'];
        await _tokenService.saveToken(token);
        // Set auth token for notification service
        _notificationService.setAuthToken(token);
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
        final token = result['data']['token'];
        await _tokenService.saveToken(token);
        // Set auth token for notification service
        _notificationService.setAuthToken(token);
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Initialize notification service with existing token
  Future<void> initializeNotificationService() async {
    final token = await _tokenService.getToken();
    if (token != null) {
      _notificationService.setAuthToken(token);
    }
  }

  // Add getToken method to expose TokenService functionality
  Future<String?> getToken() async {
    return await _tokenService.getToken();
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _tokenService.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await _tokenService.deleteToken();
    // Clear notification service token
    _notificationService.setAuthToken('');
    // Potentially notify backend about logout if necessary
  }
}