class Decujus {
  final int id;
  final String pensionNumber;
  final String firstName;
  final String lastName;
  final String dateOfBirth; // Keep as String, parse to DateTime in UI if needed
  final int agencyId;
  final bool isPensionActive;

  Decujus({
    required this.id,
    required this.pensionNumber,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.agencyId,
    required this.isPensionActive,
  });

  factory Decujus.fromJson(Map<String, dynamic> json) {
    return Decujus(
      id: json['decujus_id'] as int? ?? json['id'] as int, // Handle both 'id' and 'decujus_id'
      pensionNumber: json['pension_number'] as String,
      firstName: json['first_name'] as String? ?? '', // Handle potential null
      lastName: json['last_name'] as String? ?? '', // Handle potential null
      dateOfBirth: json['date_of_birth'] as String? ?? '', // Handle potential null
      agencyId: json['agency_id'] as int,
      isPensionActive: json['is_pension_active'] == 1 || json['is_pension_active'] == true, // Handle 0/1 or true/false
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pension_number': pensionNumber,
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth,
      'agency_id': agencyId,
      'is_pension_active': isPensionActive,
    };
  }
}
