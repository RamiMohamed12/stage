import 'package:http/http.dart' as http;
import 'dart:convert';

class AgencyService {
  // Adjust the base URL and endpoint to match your backend API
  static const String _baseUrl = 'http://192.168.125.17:3000/api'; 

  // Helper function to handle HTTP responses (similar to AuthService)
  // This is a generic handler. If fetchAgencies returns a List directly at the root,
  // special handling might be needed or the screen adapts.
  static Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    try {
      final dynamic responseBody = json.decode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // The 'data' field will hold whatever json.decode parsed (Map or List)
        return {'success': true, 'data': responseBody};
      } else {
        // Assuming error responses are JSON objects with a 'message' field
        if (responseBody is Map<String, dynamic>) {
          return {'success': false, 'message': responseBody['message'] ?? 'An unknown error occurred'};
        }
        return {'success': false, 'message': 'Server error with non-JSON response: ${response.statusCode}'};
      }
    } catch (e) {
      // This catch is for when json.decode fails or other parsing issues
      return {'success': false, 'message': 'Error parsing server response: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> fetchAgencies(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/agencies'), // Ensure this is your correct endpoint for agencies
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Assuming Bearer token authentication
        },
      );
      // The _handleResponse will return a map like:
      // {'success': true, 'data': <parsed_json_body_from_server>}
      // or {'success': false, 'message': <error_message>}
      // Your AgencyScreen expects result['data'] to be a List or it will show an error.
      // Ensure your backend returns a JSON array for this endpoint, or an object
      // that contains the array (e.g., {"agencies": [...]}) and adjust AgencyScreen if needed.
      return await _handleResponse(response); 
    } catch (e) {
      // Catch network errors or other exceptions during the request
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}