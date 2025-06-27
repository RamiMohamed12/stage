class ApiEndpoints {
  // Base URL for the API server
  static const String baseUrl = 'http://192.168.108.17:3000/api';

  // Authentication endpoints
  static const String user = '$baseUrl/users';

  // Resource endpoints
  static const String decujus = '$baseUrl/decujus';
  static const String agencies = '$baseUrl/agencies';
  static const String relationship = '$baseUrl/relationship';
  static const String deathCauses = '$baseUrl/death-causes';
  static const String declarations = '$baseUrl/declarations';
  static const String admin = '$baseUrl/admin';
  static const String notifications = '$baseUrl/notifications';
  static const String appointments = '$baseUrl/appointments';  // Add appointments endpoint
}
