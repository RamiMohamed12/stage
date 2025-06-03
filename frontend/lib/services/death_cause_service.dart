import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/constants/api_endpoints.dart';
import 'package:frontend/models/death_cause.dart';
import 'package:frontend/services/token_service.dart';

class DeathCauseService {
  final TokenService _tokenService = TokenService();

  Future<List<DeathCause>> getAllDeathCauses() async {
    final token = await _tokenService.getToken();
    if (token == null) {
      throw Exception('Token not found. Please login again.');
    }

    final response = await http.get(
      Uri.parse(ApiEndpoints.deathCauses),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<DeathCause> deathCauses = body.map((dynamic item) => DeathCause.fromJson(item)).toList();
      return deathCauses;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Unauthorized: Invalid token');
    } else {
      throw Exception('Failed to load death causes: ${response.statusCode}');
    }
  }
}
