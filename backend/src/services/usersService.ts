import pool from '../config/db';
import { Users, CreateUserInput, UpdateUserInput } from '../models/Users';
import { RowDataPacket, ResultSetHeader } from 'mysql2';
import { PoolConnection } from 'mysql2/promise';

// custom error for the service 
export class ServiceErorr extends Error{ 
    constructor(message: string, public statusCode: number = 500) {
        super(message); 
        this.name = "ServiceError"; 
    }
}

export const getUserbyId = async (userId: number): Promise<Users | null> => {
    let connection: PoolConnection | undefined; // use PoolConnection type for connection
    try { 
        connection = await pool.getConnection();
        const sql = "SELECT user_id,email,first_name,last_name,created_at,updated_at FROM users WHERE user_id = ?";
        const [rows] = await connection.execute<RowDataPacket[]>(sql, [userId]);
        if (rows.length === 0) {
            return null; // user not found
        }
        return rows[0] as Users; // cast to Users
    } catch (error: any) {
        console.error("Error in getUserById service: ", error);
        throw new ServiceErorr("Failed to get user.", 500); // internal server error
    } finally { 
        if (connection) {
            connection.release(); // release the connection back to the pool
        }
    }
}


export const createUser = async (user: CreateUserInput): Promise<Users> => {
    const {email} = user; 
    let connection: PoolConnection | undefined; // use PoolConnection type for connection
    try { 
        connection = await pool.getConnection(); 
        const checkSql = 'SELECT user_id FROM users WHERE email = ?';
        const[existing] =  await connection.execute<RowDataPacket[]>(checkSql, [email]);
        if (existing.length > 0) {
            throw new ServiceErorr('Email Already used.', 409); // conflict error
        }

        const insertSql = 'INSERT INTO users (email, password_hash, first_name, last_name) VALUES (?, ?, ?, ?)';
        const[result] = await connection.execute<ResultSetHeader>(insertSql, [user.email, user.password_hash, user.first_name, user.last_name]);
        if(result.affectedRows === 0) {
            throw new ServiceErorr('Failed to create user.', 500); // internal server error
        }
    
        const newUser = await getUserbyId(result.insertId);
        if (!newUser) {
            throw new ServiceErorr('Failed to retrieve new user.', 500); // internal server error
        }
        return newUser;
    } catch(error: any){    
    
       console.log("Error while creating user: ", error);
       if (error instanceof ServiceErorr) {
            throw error; // rethrow the custom error
        }
        throw new ServiceErorr('Internal server error.', 500); // internal server error

        
    } finally {
        if (connection) {
            connection.release(); // release the connection back to the pool
        }
    }
}

export const getAllUsers = async (): Promise<Users[]> => {
    let connection: PoolConnection | undefined; // use PoolConnection type for connection
    try  {
        connection = await pool.getConnection();
        const sql = "SELECT user_id, email, first_name, last_name, created_at, updated_at FROM users";
        const [rows] = await connection.execute<RowDataPacket[]>(sql);
        return rows as Users[]; // cast to Users[]

    } catch (error: any){
        console.error("Error in getAllUsers service: ", error); 
        throw new ServiceErorr("Failed to get users.", 500); // internal server error

    } finally {
        if(connection) {
            connection.release(); // release the connection back to the pool
        }
    }
} 

export const updateUser = async (userId: number, user: UpdateUserInput): Promise<Users> => {

    const updateFields = Object.keys(user);
    if (updateFields.length === 0) {
        throw new ServiceErorr('No fields provided for update.', 400);
    }

    let connection: PoolConnection | undefined;

    try {
        connection = await pool.getConnection();
        await connection.beginTransaction();

        // Get existing user data and lock the row for update
        const [existingUserRows] = await connection.execute<RowDataPacket[]>(
            'SELECT * FROM users WHERE user_id = ? FOR UPDATE',
            [userId]
        );

        if (existingUserRows.length === 0) {
             await connection.rollback();
             throw new ServiceErorr(`User with ID ${userId} not found.`, 404);
        }
        const existingUser = existingUserRows[0] as Users;

        // --- Prepare update ---
        const updates: string[] = []; 
        const values: any[] = [];   
        let requiresUpdate = false;  

        // Email: Check if provided, different, and unique if changing
        if (user.email !== undefined && user.email !== existingUser.email) {
            const [existingEmailCheck] = await connection.execute<RowDataPacket[]>(
                'SELECT user_id FROM users WHERE email = ? AND user_id != ?',
                [user.email, userId]
            );
            if (existingEmailCheck.length > 0) {
                await connection.rollback();
                throw new ServiceErorr(`Email ${user.email} is already in use.`, 409); // 409 Conflict
            }
            // Add email to the update list
            updates.push('email = ?');
            values.push(user.email);
            requiresUpdate = true;
        }

        // Password: Add if provided
        if (user.password_hash !== undefined) {
            updates.push('password_hash = ?');
            values.push(user.password_hash);
            requiresUpdate = true; 
        }

        // First Name: Add if provided AND different from current
        if (user.first_name !== undefined && user.first_name !== existingUser.first_name) {
            updates.push('first_name = ?');
            values.push(user.first_name);
            requiresUpdate = true;
        }

        // Last Name: Add if provided AND different from current
        if (user.last_name !== undefined && user.last_name !== existingUser.last_name) {
            updates.push('last_name = ?');
            values.push(user.last_name);
            requiresUpdate = true;
        }

        let updatedUserData : Users; 

        if (requiresUpdate) {
             if (updates.length === 0) {
                  await connection.rollback();
                  console.error("Internal logic error: requiresUpdate is true, but updates array is empty.");
                  throw new ServiceErorr("Internal server error during update.", 500);
             }

            values.push(userId); 

            const sql = `UPDATE users SET ${updates.join(', ')} WHERE user_id = ?`;
            const [result] = await connection.execute<ResultSetHeader>(sql, values);

            if (result.affectedRows === 0) {
                 await connection.rollback();
                 console.warn(`User ${userId} update failed unexpectedly (0 rows affected).`);
                 throw new ServiceErorr(`Failed to update user ${userId} (unexpectedly).`, 500);
            }

             const [refetchedRows] = await connection.execute<RowDataPacket[]>(
                 'SELECT * FROM users WHERE user_id = ?', [userId]
             );
             if (refetchedRows.length === 0) { // Should not happen if update succeeded
                  await connection.rollback();
                  throw new ServiceErorr(`User ${userId} not found after update.`, 500);
             }
             updatedUserData = refetchedRows[0] as Users;

        } else {
             console.log(`No actual field changes for user ${userId}. Skipping UPDATE.`);
             updatedUserData = existingUser; // Use the data we already fetched
        }

        await connection.commit();

        return updatedUserData;

    } catch (error: unknown) {
        if (connection) {
            try {
                await connection.rollback();
            } catch (rollbackError) {
                console.error(`Failed to rollback transaction:`, rollbackError);
            }
        }

        console.error(`Error updating user ${userId}:`, error); 

        if (error instanceof ServiceErorr) {
            throw error;
        }
         if (error instanceof Error) {
             throw new ServiceErorr(`Failed to update user ${userId}: ${error.message}`, 500);
        }
        throw new ServiceErorr(`An unknown error occurred while updating user ${userId}.`, 500);

    } finally {
        if (connection) {
            connection.release();
        }
    }
}

// we use a soft deletion method were we update the users deleted_at timestamp because of forgien key constraints 

export const deleteUser = async (userId: number): Promise<void> => {
    let connection: PoolConnection | undefined;

    try {
        connection = await pool.getConnection();
        await connection.beginTransaction();

        // update the user's deleted_at timestamp if they are not already deleted
        const [result] = await connection.execute<ResultSetHeader>(
            'UPDATE users SET deleted_at = NOW() WHERE user_id = ? AND deleted_at IS NULL',
            [userId]
        );

        // Check if the update operation affected any row
        if (result.affectedRows === 0) {
            // If no rows were affected, check if the user exists but was already deleted, or if they don't exist at all.
            const [existingUsers] = await connection.execute<RowDataPacket[]>(
                'SELECT user_id, deleted_at FROM users WHERE user_id = ?',
                [userId]
            );

            await connection.rollback(); // No change was made, so rollback

            if (existingUsers.length === 0) {
                // User not found
                throw new ServiceErorr(`User with ID ${userId} not found.`, 404);
            } else if (existingUsers[0].deleted_at !== null) {
                // User found, but already marked as deleted
                throw new ServiceErorr(`User with ID ${userId} is already marked as deleted.`, 409); // 409 Conflict
            } else {
                 // This case should be rare: user exists, is not deleted, but UPDATE failed.
                 throw new ServiceErorr(`Failed to soft-delete user ${userId}. Update failed unexpectedly.`, 500);
            }
        }

        await connection.commit();
        console.log(`Successfully soft-deleted user ${userId} (set deleted_at).`);

    } catch (error: unknown) {
        // Rollback transaction if an error occurred
        if (connection) {
            try {
                await connection.rollback();
                console.log(`Transaction rolled back for user ${userId} soft-deletion attempt.`);
            } catch (rollbackError) {
                console.error(`Failed to rollback transaction for user ${userId}:`, rollbackError);
            }
        }

        console.error(`Error soft-deleting user ${userId}:`, error);

        if (error instanceof ServiceErorr) {
            throw error;
        }
        if (error instanceof Error) {
            throw new ServiceErorr(`Failed to soft-delete user ${userId}: ${error.message}`, 500);
        }
        throw new ServiceErorr(`An unknown error occurred while soft-deleting user ${userId}.`, 500);

    } finally {
        if (connection) {
            connection.release();
        }
    }
}