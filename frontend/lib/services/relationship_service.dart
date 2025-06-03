import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/constants/api_endpoints.dart';
import 'package:frontend/models/relationship.dart';
import 'package:frontend/services/token_service.dart';

class RelationshipService {
  final TokenService _tokenService = TokenService();

  Future<List<Relationship>> getAllRelationships() async {
    final token = await _tokenService.getToken();
    if (token == null) {
      throw Exception('Token not found. Please login again.');
    }

    final response = await http.get(
      Uri.parse(ApiEndpoints.relationship),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<Relationship> relationships = body.map((dynamic item) => Relationship.fromJson(item)).toList();
      return relationships;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Unauthorized: Invalid token');
    } else {
      throw Exception('Failed to load relationships: ${response.statusCode}');
    }
  }
}
