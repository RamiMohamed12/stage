class DecujusVerificationPayload {
  final String pensionNumber;
  final String firstName;
  final String lastName;
  final String dateOfBirth; // Format YYYY-MM-DD
  final int agencyId;

  DecujusVerificationPayload({
    required this.pensionNumber,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.agencyId,
  });

  Map<String, dynamic> toJson() {
    return {
      'pension_number': pensionNumber,
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth,
      'agency_id': agencyId,
    };
  }
}
