// we declare the role as enums 
export enum Role { 
    USER = 'user',
    ADMIN = 'admin',
}

// we declare the Users interface here
export interface Users { 

    user_id: number; 
    email: string; 
    password_hash: string; 
    role: Role;
    first_name: string;
    last_name: string;
    created_at: string | Date;
    updated_at: string | Date;
    deleted_at: string | Date | null; // we use null for not deleted 
    
}

// input type for creating a user
export type CreateUserInput = Omit<Users, 'user_id' | 'created_at' | 'updated_at' | 'deleted_at'> & {
    role?: Role; // Use Role enum, make optional if relying on DB default
};

// input type for updating a user
export type UpdateUserInput = Partial<Omit<Users, 'user_id' | 'created_at' | 'updated_at' | 'deleted_at'>>;