import 'package:frontend/models/decujus.dart';

class DecujusVerificationResult {
  final bool success;
  final String message;
  final Decujus? decujus; // Nullable if verification fails or decujus not found

  DecujusVerificationResult({
    required this.success,
    required this.message,
    this.decujus,
  });

  factory DecujusVerificationResult.fromJson(Map<String, dynamic> json) {
    return DecujusVerificationResult(
      success: json['success'] == true, // Safely check for true, defaults to false if null or not true
      message: json['message'] as String? ?? 'No message provided', // Handle potential null message
      decujus: json['decujus'] != null && json['decujus'] is Map<String, dynamic>
          ? Decujus.fromJson(json['decujus'] as Map<String, dynamic>)
          : null,
    );
  }
}
