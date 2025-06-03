import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:frontend/constants/api_endpoints.dart';
import 'package:frontend/services/token_service.dart';
import 'package:frontend/models/document.dart';

class DocumentService {
  final TokenService _tokenService = TokenService();

  Future<List<DeclarationDocument>> getDeclarationDocuments(int declarationId) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('${ApiEndpoints.declarations}/$declarationId/documents'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((doc) => DeclarationDocument.fromJson(doc)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la récupération des documents');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<void> uploadDocument(int declarationDocumentId, File file) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiEndpoints.declarations}/documents/$declarationDocumentId/upload'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add the file
      var stream = http.ByteStream(file.openRead());
      var length = await file.length();
      var multipartFile = http.MultipartFile(
        'documentFile',
        stream,
        length,
        filename: file.path.split('/').last,
        contentType: _getContentType(file.path),
      );
      request.files.add(multipartFile);

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return; // Success
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors du téléchargement du document');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erreur de connexion: $e');
    }
  }

  MediaType _getContentType(String filePath) {
    String extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'doc':
        return MediaType('application', 'msword');
      case 'docx':
        return MediaType('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document');
      case 'svg':
        return MediaType('image', 'svg+xml');
      case 'heic':
        return MediaType('image', 'heic');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  Future<Map<String, dynamic>> getDeclarationDocumentStatus(int declarationId) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('${ApiEndpoints.declarations}/$declarationId/documents/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la récupération du statut des documents');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erreur de connexion: $e');
    }
  }
}