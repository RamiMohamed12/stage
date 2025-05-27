import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/agency.dart';
import 'token_service.dart'; // Import TokenService

class AgencyService {
  final TokenService _tokenService = TokenService(); // Instantiate TokenService

  Future<List<Agency>> fetchAgencies() async {
    final token = await _tokenService.getToken();
    print('[AgencyService] Token from TokenService: $token'); // Log the token

    if (token == null) {
      print('[AgencyService] Token not found in storage.');
      throw Exception('Token not found. Please login again.');
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/agencies');
    print('[AgencyService] Fetching agencies from: $url'); // Log URL
    print('[AgencyService] Authorization Header: Bearer $token'); // Log header

    http.Response response;
    try {
      response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      print('[AgencyService] HTTP request failed: $e');
      throw Exception('Network error or server unreachable: ${e.toString()}');
    }

    print('[AgencyService] Response Status Code: ${response.statusCode}'); // Log status code
    print('[AgencyService] Response Body: ${response.body}'); // Log response body

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<Agency> agencies = body.map((dynamic item) => Agency.fromJson(item)).toList();
      return agencies;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      print('[AgencyService] Authentication error: Status ${response.statusCode}');
      throw Exception('Unauthorized: Invalid token or insufficient permissions. Server says: ${response.body}');
    } else {
      // Attempt to parse error message from response body
      String errorMessage = 'Failed to load agencies. Status code: ${response.statusCode}';
      try {
        var decodedBody = jsonDecode(response.body);
        if (decodedBody != null && decodedBody['message'] != null) {
          errorMessage = decodedBody['message'];
        }
      } catch (e) {
        // Ignore if body is not JSON or doesn't contain 'message'
        print('[AgencyService] Could not parse error message from response body: $e');
      }
      print('[AgencyService] Failed to load agencies: Status ${response.statusCode}, Body: ${response.body}');
      throw Exception(errorMessage);
    }
  }
}