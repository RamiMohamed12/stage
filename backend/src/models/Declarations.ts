// we declare a enum for the status of the declaration
export enum Status  {
    
    SUBMITTED = 'submitted',
    APPROVED = 'approved',
    REJECTED = 'rejected'

}

// this is the interface for the declarations 
export interface Declarations {

   declaration_id:number; 
   applicant_user_id:number; 
   decujus_pension_number:string | null; 
   relationship_id:number; 
   death_cause_id:number | null; 
   declaration_date: Date; 
   status: Status; 
   created_at: Date ;
   updated_at: Date ;
   pension_notified: boolean; 

} 

// --- CORRECTED LINE ---
// Omit 'pension_notified' along with the other auto-generated fields.
export type CreateDeclarationInput = Omit<Declarations, 'declaration_id' | 'created_at' | 'updated_at' | 'declaration_date' | 'status' | 'pension_notified'> & {
    applicant_user_id: number;
    decujus_pension_number: string | null;
    relationship_id: number;
    death_cause_id: number | null; // Optional on input?
    declaration_date: Date; 
    status: Status; 

};

// this is the input type for updating a declaration
// Usually you only update specific fields, often status by admin
export type UpdateDeclarationInput = Partial<Pick<Declarations, 'status' /* add other updatable fields if needed */>>;