class DeathCause {
  final int deathCauseId;
  final String causeName;

  DeathCause({
    required this.deathCauseId,
    required this.causeName,
  });

  factory DeathCause.fromJson(Map<String, dynamic> json) {
    return DeathCause(
      deathCauseId: (json['death_cause_id'] ?? 0) as int, // Handle potential null for ID
      causeName: json['cause_name'] as String? ?? '',     // Handle potential null for name
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'death_cause_id': deathCauseId,
      'cause_name': causeName,
    };
  }
}
