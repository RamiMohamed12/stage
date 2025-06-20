class AppointmentModel {
  final int appointmentId;
  final int declarationId;
  final int userId;
  final int adminId;
  final DateTime appointmentDate;
  final String appointmentTime;
  final String location;
  final String? notes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? declarantName;
  final String? declarantEmail;
  final String? adminName;
  final String? adminEmail;
  final String? declarationPensionNumber;

  AppointmentModel({
    required this.appointmentId,
    required this.declarationId,
    required this.userId,
    required this.adminId,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.location,
    this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.declarantName,
    this.declarantEmail,
    this.adminName,
    this.adminEmail,
    this.declarationPensionNumber,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      appointmentId: json['appointment_id'] ?? 0,
      declarationId: json['declaration_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      adminId: json['admin_id'] ?? 0,
      appointmentDate: DateTime.parse(json['appointment_date']),
      appointmentTime: json['appointment_time'] ?? '',
      location: json['location'] ?? '',
      notes: json['notes'],
      status: json['status'] ?? 'scheduled',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      declarantName: json['declarant_name'],
      declarantEmail: json['declarant_email'],
      adminName: json['admin_name'],
      adminEmail: json['admin_email'],
      declarationPensionNumber: json['declaration_pension_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appointment_id': appointmentId,
      'declaration_id': declarationId,
      'user_id': userId,
      'admin_id': adminId,
      'appointment_date': appointmentDate.toIso8601String(),
      'appointment_time': appointmentTime,
      'location': location,
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'declarant_name': declarantName,
      'declarant_email': declarantEmail,
      'admin_name': adminName,
      'admin_email': adminEmail,
      'declaration_pension_number': declarationPensionNumber,
    };
  }

  // Format appointment date and time for display
  String get formattedDateTime {
    final dateStr = '${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year}';
    final timeStr = appointmentTime.substring(0, 5); // Remove seconds if present
    return '$dateStr à $timeStr';
  }

  // Get status display text in French
  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return 'Planifié';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  // Check if appointment is in the future
  bool get isFuture {
    final now = DateTime.now();
    final appointmentDateTime = DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
      int.parse(appointmentTime.split(':')[0]),
      int.parse(appointmentTime.split(':')[1]),
    );
    return appointmentDateTime.isAfter(now);
  }
}