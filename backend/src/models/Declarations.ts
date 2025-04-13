export enum DeclarationStatus {
    
    SUBMITTED = 'submitted',
    PROCESSING = 'processing',
    APPROVED = 'approved',
    REJECTED = 'rejected',
    REQUIRES_INFO = 'requires_info'

}

export interface Declarations {

    declaration_id: number; 
    applicant_user_id: number; 
    decujus_pension_id: string;
    declaration_date: Date; 
    status: DeclarationStatus;
    created_at: string | Date;  
    updated_at: string | Date;

} 

