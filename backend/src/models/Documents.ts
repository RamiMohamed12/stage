export interface Documents {

    document_id: number; 
    declaration_id:number; 
    file_path: string; 
    original_filename: string | null; 
    upload_timestamp: Date; 

}

// input type for creating a document
export type CreateDocumentInput = Omit<Documents, 'document_id' | 'upload_timestamp'>;

// input type for updating a document 
export type UpdateDocumentInput = Partial<Pick<Documents, 'file_path' | 'original_filename'>>;