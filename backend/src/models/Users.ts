import { RowDataPacket } from 'mysql2';

export enum Role {
    USER = 'user',
    ADMIN = 'admin'
}

interface BaseUser {
    email: string;
    password_hash: string;
    role: Role;
    first_name: string | null;
    last_name: string | null;
}

export interface Users extends BaseUser {
    user_id: number;
    created_at: Date;
    updated_at: Date | null;
    deleted_at: Date | null;
}


export interface UserRow extends Users, RowDataPacket {}


export type CreateUserInput = Omit<BaseUser, 'role'> & {
    role?: Role;
};


export type UpdateUserInput = Partial<Omit<BaseUser, 'user_id'>>;