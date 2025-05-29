import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';
import 'token_service.dart';

class DecujusService {
  final TokenService _tokenService = TokenService();

  Future<Map<String, dynamic>> verifyDecujusByPensionNumber(String pensionNumber) async {
    final token = await _tokenService.getToken();
    
    if (token == null) {
      throw Exception('Token not found. Please login again.');
    }

    final url = Uri.parse('${ApiEndpoints.baseUrl}/decujus/$pensionNumber');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'exists': true,
          'data': data,
          'message': 'Decujus trouvé avec succès'
        };
      } else if (response.statusCode == 404) {
        return {
          'success': true,
          'exists': false,
          'data': null,
          'message': 'Aucun decujus trouvé avec ce numéro de pension'
        };
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'exists': false,
          'data': null,
          'message': 'Numéro de pension invalide'
        };
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Non autorisé: Token invalide');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Non autorisé')) {
        rethrow;
      }
      throw Exception('Erreur de connexion: ${e.toString()}');
    }
  }
}
