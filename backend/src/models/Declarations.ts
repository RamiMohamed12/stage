// we declare a enum for the status of the declaration
export enum DeclarationStatus {
    
    SUBMITTED = 'submitted',
    PROCESSING = 'processing',
    APPROVED = 'approved',
    REJECTED = 'rejected',
    REQUIRES_INFO = 'requires_info'

}

// this is the interface for the declarations 
export interface Declarations {

    declaration_id: number; 
    applicant_user_id: number; 
    decujus_pension_id: string;
    declaration_date: Date; 
    status: DeclarationStatus;
    created_at: string | Date;  
    updated_at: string | Date;

} 

// this is the input type for creating a declaration

export type CreateDeclarationInput = Omit<Declarations, 'declaration_id' | 'created_at' | 'updated_at'>;

// this is the input type for updating a declaration
export type UpdateDeclarationInput = Partial<CreateDeclarationInput>; 
