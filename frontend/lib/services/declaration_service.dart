import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/constants/api_endpoints.dart';
import 'package:frontend/services/token_service.dart';

class DeclarationService {
  final TokenService _tokenService = TokenService();

  // Method to check for existing declarations by pension number
  Future<Map<String, dynamic>> checkExistingDeclaration(String pensionNumber) async {
    final token = await _tokenService.getToken();
    if (token == null) {
      throw Exception('Token not found. Please login again.');
    }

    final response = await http.get(
      Uri.parse('${ApiEndpoints.declarations}/check/$pensionNumber'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Unauthorized: Invalid token');
    } else {
      throw Exception('Failed to check existing declaration: ${response.statusCode}, ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createDeclaration({
    required String decujusPensionNumber,
    required int relationshipId,
    required int deathCauseId,
    DateTime? declarationDate,
  }) async {
    final token = await _tokenService.getToken();
    if (token == null) {
      throw Exception('Token not found. Please login again.');
    }

    final Map<String, dynamic> body = {
      'decujus_pension_number': decujusPensionNumber,
      'relationship_id': relationshipId,
      'death_cause_id': deathCauseId,
    };

    if (declarationDate != null) {
      body['declaration_date'] = declarationDate.toIso8601String();
    }

    final response = await http.post(
      Uri.parse(ApiEndpoints.declarations),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      // Handle both new declarations (201) and existing declarations (200)
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 400) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to create declaration due to invalid input.');
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Unauthorized: Invalid token');
    } else {
      throw Exception('Failed to create declaration: ${response.statusCode}, ${response.body}');
    }
  }

  // Method to get user's declarations and check for pending document reviews
  Future<Map<String, dynamic>?> getUserPendingDeclaration() async {
    final token = await _tokenService.getToken();
    if (token == null) {
      throw Exception('Token not found. Please login again.');
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.declarations}/user/pending'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else if (response.statusCode == 404) {
        // No pending declarations found
        return null;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Unauthorized: Invalid token');
      } else {
        throw Exception('Failed to get pending declarations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error checking pending declarations: ${e.toString()}');
    }
  }
}
