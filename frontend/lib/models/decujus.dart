class Decujus {
  final int id;
  final String pensionNumber;
  final String firstName;
  final String lastName;
  final String dateOfBirth; // Keep as String, parse to DateTime in UI if needed
  final int agencyId;

  Decujus({
    required this.id,
    required this.pensionNumber,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.agencyId,
  });

  factory Decujus.fromJson(Map<String, dynamic> json) {
    return Decujus(
      id: json['id'] as int,
      pensionNumber: json['pension_number'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      dateOfBirth: json['date_of_birth'] as String,
      agencyId: json['agency_id'] as int,
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
    };
  }
}
