// we declare the Users interface here
export interface Users { 

    user_id: number; 
    email: string; 
    password_hash: string; 
    first_name: string;
    last_name: string;
    created_at: string | Date;
    updated_at: string | Date;
    
}

// input type for creating a user 
export type CreateUserInput = Omit<Users, 'user_id' | 'created_at' | 'updated_at'>;

// input type for updating a user
export type UpdateUserInput = Partial<CreateUserInput>;

