class Relationship {
  final int relationshipId;
  final String relationshipName;

  Relationship({
    required this.relationshipId,
    required this.relationshipName,
  });

  factory Relationship.fromJson(Map<String, dynamic> json) {
    return Relationship(
      relationshipId: (json['relationship_id'] ?? 0) as int, // Handle potential null for ID
      relationshipName: json['relationship_name'] as String? ?? '', // Handle potential null for name
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'relationship_id': relationshipId,
      'relationship_name': relationshipName,
    };
  }
}
