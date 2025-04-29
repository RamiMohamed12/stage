export enum DeclarationDocumentStatus {
    PENDING = 'pending',
    UPLOADED = 'uploaded',
    VERIFIED = 'verified',
    REJECTED = 'rejected'
}

export interface DeclarationDocuments {
    declaration_document_id: number;
    declaration_id: number;
    document_type_id: number;
    status: DeclarationDocumentStatus;
    uploaded_file_path: string | null;
    uploaded_at: Date | null;
    reviewed_by_admin_id: number | null;
    reviewed_at: Date | null;
    rejection_reason: string | null;
    created_at: Date; // Default is CURRENT_TIMESTAMP, so likely not null on read
    updated_at: Date; // Default is CURRENT_TIMESTAMP, so likely not null on read
}

// Input for creating a record (usually internal)
export type CreateDeclarationDocumentInput = Pick<DeclarationDocuments, 'declaration_id' | 'document_type_id'> & {
    status?: DeclarationDocumentStatus; // Optional, defaults to 'pending' in DB
};

// Input for updating status after upload
export type UpdateDeclarationDocumentUploadInput = Pick<DeclarationDocuments, 'status' | 'uploaded_file_path' | 'uploaded_at'>;

// Input for admin review update
export type UpdateDeclarationDocumentReviewInput = Pick<DeclarationDocuments, 'status' | 'reviewed_by_admin_id' | 'reviewed_at' | 'rejection_reason'>;

// Interface for showing status to user (joined with document_types)
export interface DeclarationDocumentStatusInfo {
    declaration_document_id: number;
    document_type_id: number;
    document_name: string; // From document_types table
    status: DeclarationDocumentStatus;
    uploaded_file_path: string | null;
    uploaded_at: Date | null;
    rejection_reason: string | null;
    is_mandatory: boolean; // From relationship_required_documents table
}