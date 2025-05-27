import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/models/decujus_verification_payload.dart';
import 'package:frontend/models/decujus_verification_result.dart';
import 'package:frontend/config/api_config.dart';
import 'package:frontend/services/token_service.dart';
import 'dart:developer' as developer; // Import for log

class DecujusService {
  final TokenService _tokenService = TokenService();

  Future<DecujusVerificationResult> verifyDecujus(
      DecujusVerificationPayload payload) async {
    final token = await _tokenService.getToken();
    developer.log('DecujusService: Token: $token', name: 'com.example.frontend.DecujusService');
    if (token == null) {
      developer.log('DecujusService: Token not found. Please login again.', name: 'com.example.frontend.DecujusService', error: 'Token is null');
      throw Exception('Token not found. Please login again.');
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/decujus/verify');
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
    final body = jsonEncode(payload.toJson());

    developer.log('DecujusService: Sending POST request to $url', name: 'com.example.frontend.DecujusService');
    developer.log('DecujusService: Headers: $headers', name: 'com.example.frontend.DecujusService');
    developer.log('DecujusService: Body: $body', name: 'com.example.frontend.DecujusService');

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      developer.log('DecujusService: Response status code: ${response.statusCode}', name: 'com.example.frontend.DecujusService');
      developer.log('DecujusService: Response body: ${response.body}', name: 'com.example.frontend.DecujusService');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedBody = jsonDecode(response.body);
        developer.log('DecujusService: Decoded response body: $decodedBody', name: 'com.example.frontend.DecujusService');
        if (decodedBody is Map<String, dynamic>) {
          if (decodedBody.containsKey('success')) {
            developer.log('DecujusService: "success" field type: ${decodedBody['success'].runtimeType}', name: 'com.example.frontend.DecujusService');
            developer.log('DecujusService: "success" field value: ${decodedBody['success']}', name: 'com.example.frontend.DecujusService');
          } else {
            developer.log('DecujusService: "success" field is missing in response', name: 'com.example.frontend.DecujusService', error: 'Missing success field');
          }
          return DecujusVerificationResult.fromJson(decodedBody);
        } else {
          developer.log('DecujusService: Decoded body is not a Map<String, dynamic>. Type: ${decodedBody.runtimeType}', name: 'com.example.frontend.DecujusService', error: 'Invalid JSON structure');
          throw Exception('Invalid response format from server.');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        developer.log('DecujusService: Unauthorized access. Status: ${response.statusCode}', name: 'com.example.frontend.DecujusService', error: response.body);
        throw Exception('Unauthorized: Invalid token or insufficient permissions.');
      } else if (response.statusCode == 400) {
        final responseBody = jsonDecode(response.body);
        developer.log('DecujusService: Invalid input. Status: ${response.statusCode}, Body: $responseBody', name: 'com.example.frontend.DecujusService', error: response.body);
        throw Exception(responseBody['message'] ?? 'Invalid input for decujus verification.');
      } else if (response.statusCode == 404) {
        final responseBody = jsonDecode(response.body);
        developer.log('DecujusService: Decujus not found. Status: ${response.statusCode}, Body: $responseBody', name: 'com.example.frontend.DecujusService', error: response.body);
        throw Exception(responseBody['message'] ?? 'Decujus not found.');
      } else {
        developer.log('DecujusService: Failed to verify decujus. Status: ${response.statusCode}, Body: ${response.body}', name: 'com.example.frontend.DecujusService', error: response.body);
        throw Exception('Failed to verify decujus. Status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      developer.log('DecujusService: Error during decujus verification: $e', name: 'com.example.frontend.DecujusService', error: e, stackTrace: stackTrace);
      developer.log('DecujusService: Payload sent: $body', name: 'com.example.frontend.DecujusService');
      rethrow;
    }
  }
}
