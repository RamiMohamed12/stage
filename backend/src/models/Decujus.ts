import { RowDataPacket } from 'mysql2/promise'; 

export interface Decujus {

    decujus_id: number;
    pension_number: string; 
    first_name: string | null; 
    last_name: string | null;
    date_of_birth: Date | null;
    agency_id: number | null;
    is_pension_active: boolean; 
    created_at: string | Date;
    updated_at: string | Date;
    
}

export interface DecujusRow extends Decujus, RowDataPacket {}

export type CreateDecujusInput = Omit<Decujus, 'decujus_id' | 'created_at' | 'updated_at' | 'is_pension_active'> & {
    is_pension_active?: boolean;
};

// input type for updating a decujus
export type UpdateDecujusInput = Partial<Omit<Decujus, 'decujus_id' | 'created_at' | 'updated_at'>>;