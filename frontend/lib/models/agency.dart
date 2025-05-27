
class Agency {
  final int agencyId;
  final String nameAgency;

  Agency({
    required this.agencyId,
    required this.nameAgency,
  });

  factory Agency.fromJson(Map<String, dynamic> json) {
    return Agency(
      agencyId: json['agency_id'] as int,
      nameAgency: json['name_agency'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agency_id': agencyId,
      'name_agency': nameAgency,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Agency &&
          runtimeType == other.runtimeType &&
          agencyId == other.agencyId &&
          nameAgency == other.nameAgency;

  @override
  int get hashCode => agencyId.hashCode ^ nameAgency.hashCode;

  @override
  String toString() {
    return 'Agency{agencyId: $agencyId, nameAgency: $nameAgency}';
  }
}
