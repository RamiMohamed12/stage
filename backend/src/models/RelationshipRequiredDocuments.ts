export interface RelationshipRequiredDocuments {
    relationship_required_document_id: number;
    relationship_id: number;
    document_type_id: number;
    is_mandatory: boolean;     
    created_at: Date | null; 
    updated_at: Date | null; 
}

export interface RequiredDocumentInfo {

    document_type_id: number;
    name: string;
    description: string | null;
    is_mandatory: boolean;

}