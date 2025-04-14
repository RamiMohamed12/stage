export interface Decujus {

    decujus_id: number;
    pension_number: string; 
    first_name: string; 
    last_name: string;
    date_of_death: Date;
    created_at: string | Date;
    updated_at: string | Date;
    
}

// input type for creating a decujus
export type CreateDecujusInput = Omit<Decujus, 'decujus_id' | 'created_at' | 'updated_at'>;

// input type for updating a decujus
export type UpdateDecujusInput = Partial<CreateDecujusInput>;
