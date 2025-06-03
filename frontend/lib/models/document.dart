class Document {
  final int documentTypeId;
  final String documentName;
  final bool isMandatory;

  Document({
    required this.documentTypeId,
    required this.documentName,
    required this.isMandatory,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      documentTypeId: json['document_type_id'],
      documentName: json['document_name'],
      isMandatory: json['is_mandatory'] ?? false,
    );
  }
}

enum DocumentStatus {
  pending,
  uploaded,
  approved,
  rejected
}

class DeclarationDocument {
  final int declarationDocumentId;
  final int documentTypeId;
  final String documentName;
  final DocumentStatus status;
  final String? uploadedFilePath;
  final DateTime? uploadedAt;
  final String? rejectionReason;
  final bool isMandatory;

  DeclarationDocument({
    required this.declarationDocumentId,
    required this.documentTypeId,
    required this.documentName,
    required this.status,
    this.uploadedFilePath,
    this.uploadedAt,
    this.rejectionReason,
    required this.isMandatory,
  });

  factory DeclarationDocument.fromJson(Map<String, dynamic> json) {
    return DeclarationDocument(
      declarationDocumentId: json['declaration_document_id'],
      documentTypeId: json['document_type_id'],
      documentName: json['document_name'],
      status: _parseDocumentStatus(json['status']),
      uploadedFilePath: json['uploaded_file_path'],
      uploadedAt: json['uploaded_at'] != null ? DateTime.parse(json['uploaded_at']) : null,
      rejectionReason: json['rejection_reason'],
      isMandatory: json['is_mandatory'] ?? false,
    );
  }

  static DocumentStatus _parseDocumentStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'uploaded':
        return DocumentStatus.uploaded;
      case 'approved':
        return DocumentStatus.approved;
      case 'rejected':
        return DocumentStatus.rejected;
      default:
        return DocumentStatus.pending;
    }
  }
}

class DeclarationResponse {
  final bool success;
  final String message;
  final Declaration declaration;
  final List<DeclarationDocument> documents;
  final bool isExisting;

  DeclarationResponse({
    required this.success,
    required this.message,
    required this.declaration,
    required this.documents,
    required this.isExisting,
  });

  factory DeclarationResponse.fromJson(Map<String, dynamic> json) {
    return DeclarationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      declaration: Declaration.fromJson(json['declaration']),
      documents: (json['documents'] as List<dynamic>?)
          ?.map((doc) => DeclarationDocument.fromJson(doc))
          .toList() ?? [],
      isExisting: json['isExisting'] ?? false,
    );
  }
}

class Declaration {
  final int declarationId;
  final int applicantUserId;
  final String decujusPensionNumber;
  final int relationshipId;
  final int deathCauseId;
  final DateTime declarationDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Declaration({
    required this.declarationId,
    required this.applicantUserId,
    required this.decujusPensionNumber,
    required this.relationshipId,
    required this.deathCauseId,
    required this.declarationDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Declaration.fromJson(Map<String, dynamic> json) {
    return Declaration(
      declarationId: json['declaration_id'],
      applicantUserId: json['applicant_user_id'],
      decujusPensionNumber: json['decujus_pension_number'],
      relationshipId: json['relationship_id'],
      deathCauseId: json['death_cause_id'],
      declarationDate: DateTime.parse(json['declaration_date']),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}