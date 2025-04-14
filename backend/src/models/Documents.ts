export interface Documents {

    document_id: number; 
    declaration_id: number;
    document_type: string;
    file_path: string; 
    original_filename: string;
    upload_timestamp: string | Date; 
    ocr_extracted_text_arabic: string; 

}

// input type for creating a document
export type CreateDocumentInput = Omit<Documents, 'document_id' | 'upload_timestamp'>;

// input type for updating a document
export type UpdateDocumentInput = Partial<CreateDocumentInput>;
