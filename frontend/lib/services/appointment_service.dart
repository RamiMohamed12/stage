import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';
import '../services/token_service.dart';

class AppointmentService {
  final TokenService _tokenService = TokenService();

  // Get user's appointments
  Future<List<Map<String, dynamic>>> getUserAppointments() async {
    final token = await _tokenService.getToken();
    if (token == null) {
      throw Exception('Token not found. Please login again.');
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.appointments}/user'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['appointments']);
        } else {
          throw Exception('Failed to get appointments');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Unauthorized: Invalid token');
      } else {
        throw Exception('Failed to get appointments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting appointments: ${e.toString()}');
    }
  }

  // Check if user has any active appointments (scheduled status)
  Future<Map<String, dynamic>?> getActiveAppointment() async {
    try {
      final appointments = await getUserAppointments();
      
      // Find the most recent scheduled appointment
      final activeAppointments = appointments.where((appointment) => 
        appointment['status'] == 'scheduled'
      ).toList();
      
      if (activeAppointments.isNotEmpty) {
        // Sort by appointment date and time to get the most recent/upcoming one
        activeAppointments.sort((a, b) {
          final dateA = DateTime.parse('${a['appointment_date']} ${a['appointment_time']}');
          final dateB = DateTime.parse('${b['appointment_date']} ${b['appointment_time']}');
          return dateA.compareTo(dateB);
        });
        
        return activeAppointments.first;
      }
      
      return null;
    } catch (e) {
      print('Error checking for active appointments: $e');
      return null;
    }
  }

  // Get appointment by declaration ID
  Future<Map<String, dynamic>> getAppointmentByDeclarationId(int declarationId) async {
    final token = await _tokenService.getToken();
    if (token == null) {
      throw Exception('Token not found. Please login again.');
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.appointments}/declaration/$declarationId'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // The backend returns the appointment object directly.
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        throw Exception('No appointment found for this declaration.');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Unauthorized: Invalid token');
      } else {
        throw Exception('Failed to get appointment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting appointment: ${e.toString()}');
    }
  }
}