import pool from '../config/db';
import { Users, CreateUserInput, UpdateUserInput, Role } from '../models/Users';
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
    let connection: PoolConnection | undefined; 
    try {
        connection = await pool.getConnection();
        // we use deleted_at IS NULL at the end to check if the user is bein soft deleted or not   
        const sql = "SELECT user_id, email, password_hash, role, first_name, last_name, created_at, updated_at, deleted_at FROM users WHERE user_id = ? AND deleted_at IS NULL";
        const [rows] = await connection.execute<RowDataPacket[]>(sql, [userId]);
        if (rows.length === 0) {
            return null; // user not found or soft-deleted
        }
        return rows[0] as Users;
    } catch (error: any) {
        console.error("Error in getUserById service: ", error);
        throw new ServiceErorr("Failed to get user by ID.", 500); // internal server error
    } finally {
        if (connection) {
            connection.release(); 
        }
    }
}

// createUser service to create a new user in the database
export const createUser = async (user: CreateUserInput): Promise<Users> => {
    const { email, password_hash, first_name, last_name, role = Role.USER } = user; 
    let connection: PoolConnection | undefined; 

    try {
        connection = await pool.getConnection();

        // we check if the email is used by active account or not
        const checkSql = 'SELECT user_id FROM users WHERE email = ? AND deleted_at IS NULL';
        const [existing] = await connection.execute<RowDataPacket[]>(checkSql, [email]);

        // if the existing sql query returns any rows, it means the email is already used by an active account
        if (existing.length > 0) {
            throw new ServiceErorr('Email already used by an active account.', 409); 
        }

        // we try to insert a new user into the database
        // we use a prepared statement to prevent sql injection attacks
        const insertSql = 'INSERT INTO users (email, password_hash, first_name, last_name, role) VALUES (?, ?, ?, ?, ?)';
        const values = [email, password_hash, first_name, last_name, role]; 

        const [result] = await connection.execute<ResultSetHeader>(insertSql, values);

        // if the insert operation did not affect any rows, it means the user was not created
        if (result.affectedRows === 0) {
            throw new ServiceErorr('Failed to create user.', 500); // Internal server error
        }

        // Fetch the newly created user (ensure getUserbyId selects the role field too)
        const newUser = await getUserbyId(result.insertId);
        if (!newUser) {
            // This case might indicate an issue with getUserbyId or a race condition
            throw new ServiceErorr('Failed to retrieve newly created user.', 500);
        }

        return newUser;

    } catch (error: any) {
        console.error("Error while creating user: ", error); // Log the actual error
        if (error instanceof ServiceErorr) {
            throw error; // Re-throw the custom error
        }
        throw new ServiceErorr('An internal error occurred while creating the user.', 500);

    } finally {
        if (connection) {
            connection.release(); 
        }
    }
}


// getUserByEmail service to get a user by email from the database
export const getUserByEmail = async (email: string): Promise<Users | null> => {
    let connection: PoolConnection | undefined;
    try {
        connection = await pool.getConnection();
        const sql = "SELECT user_id, email, password_hash, role, first_name, last_name, created_at, updated_at, deleted_at FROM users WHERE email = ? AND deleted_at IS NULL";
        const [rows] = await connection.execute<RowDataPacket[]>(sql, [email]);
        if (rows.length === 0) {
            return null; // user not found or soft-deleted
        }
        // Ensure the fetched data is correctly cast, including the role
        return rows[0] as Users;
    } catch (error: any) {
        console.error("Error in getUserByEmail service: ", error);
        throw new ServiceErorr("Failed to get user by email.", 500); // internal server error
    } finally {
        if (connection) {
            connection.release(); 
        }
    }
}

//getAllUsers service to get all users from the database
export const getAllUsers = async (): Promise<Users[]> => {
    let connection: PoolConnection | undefined;
    try  {
        connection = await pool.getConnection();
        const sql = "SELECT user_id, email, role, first_name, last_name, created_at, updated_at FROM users WHERE deleted_at IS NULL";
        const [rows] = await connection.execute<RowDataPacket[]>(sql);
        return rows as Users[];

    } catch (error: any){
        console.error("Error in getAllUsers service: ", error);
        throw new ServiceErorr("Failed to get all users.", 500); // internal server error

    } finally {
        if(connection) {
            connection.release(); 
        }
    }
}

// updateUser service to update a user in the database
export const updateUser = async (userId: number, userUpdateData: UpdateUserInput): Promise<Users> => {

    // we check if there's anything to update
    const updateFields = Object.keys(userUpdateData);
    if (updateFields.length === 0) {
         const currentUser = await getUserbyId(userId);
         if (!currentUser) {
             throw new ServiceErorr(`User with ID ${userId} not found or is deleted.`, 404);
         }
         console.log(`No fields provided for update for user ${userId}. Returning current data.`);
         return currentUser;
    }

    let connection: PoolConnection | undefined;

    try {
        connection = await pool.getConnection();
        await connection.beginTransaction();

        // get existing user data and lock the row for update (ensure role is selected and user is not deleted)
        const [existingUserRows] = await connection.execute<RowDataPacket[]>(
            'SELECT user_id, email, password_hash, role, first_name, last_name, created_at, updated_at, deleted_at FROM users WHERE user_id = ? AND deleted_at IS NULL FOR UPDATE',
            [userId]
        );

        if (existingUserRows.length === 0) {
             await connection.rollback();
             // Check if user exists but is deleted
             const [deletedCheck] = await connection.execute<RowDataPacket[]>('SELECT user_id FROM users WHERE user_id = ?', [userId]);
             if (deletedCheck.length > 0) {
                 throw new ServiceErorr(`User with ID ${userId} has been deleted and cannot be updated.`, 404);
             } else {
                 throw new ServiceErorr(`User with ID ${userId} not found.`, 404);
             }
        }
        const existingUser = existingUserRows[0] as Users;

        const updates: string[] = [];
        const values: (string | number | null | Date | Role)[] = []; // Type the values array
        let requiresUpdate = false;

        if (userUpdateData.email !== undefined && userUpdateData.email !== existingUser.email) {
            const [existingEmailCheck] = await connection.execute<RowDataPacket[]>(
                'SELECT user_id FROM users WHERE email = ? AND user_id != ? AND deleted_at IS NULL',
                [userUpdateData.email, userId]
            );
            if (existingEmailCheck.length > 0) {
                await connection.rollback();
                throw new ServiceErorr(`Email ${userUpdateData.email} is already in use by another active user.`, 409); // 409 Conflict
            }
            updates.push('email = ?');
            values.push(userUpdateData.email);
            requiresUpdate = true;
        }

        // Password: Add if provided (Hashing should happen in controller/before calling service)
        if (userUpdateData.password_hash !== undefined) {
             // Basic check: ensure it's not empty if provided
             if (!userUpdateData.password_hash) {
                 await connection.rollback();
                 throw new ServiceErorr('Password cannot be empty.', 400);
             }
            updates.push('password_hash = ?');
            values.push(userUpdateData.password_hash); // Assume already hashed
            requiresUpdate = true;
        }

        // Role: Add if provided AND different from current
        if (userUpdateData.role !== undefined && userUpdateData.role !== existingUser.role) {
             // Add validation if needed (e.g., only admins can change roles) - This logic belongs more in the controller/middleware layer
            updates.push('role = ?');
            values.push(userUpdateData.role); // Use the Role enum value
            requiresUpdate = true;
        }


        // First Name: Add if provided AND different from current (handle null)
        if (userUpdateData.first_name !== undefined && userUpdateData.first_name !== existingUser.first_name) {
            updates.push('first_name = ?');
            values.push(userUpdateData.first_name);
            requiresUpdate = true;
        }

        // Last Name: Add if provided AND different from current (handle null)
        if (userUpdateData.last_name !== undefined && userUpdateData.last_name !== existingUser.last_name) {
            updates.push('last_name = ?');
            values.push(userUpdateData.last_name);
            requiresUpdate = true;
        }

        let updatedUserData : Users;

        if (requiresUpdate) {
             // Add updated_at automatically (DB might handle this, but explicit is fine)
             updates.push('updated_at = NOW()');
             // Add the userId for the WHERE clause
             values.push(userId);

            const sql = `UPDATE users SET ${updates.join(', ')} WHERE user_id = ? AND deleted_at IS NULL`;
            const [result] = await connection.execute<ResultSetHeader>(sql, values);

            if (result.affectedRows === 0) {
                 // This could happen if the user was deleted between the SELECT FOR UPDATE and the UPDATE
                 await connection.rollback();
                 console.warn(`User ${userId} update affected 0 rows. User might have been deleted concurrently.`);
                 // Check again if the user exists to give a more specific error
                 const [checkAgain] = await connection.execute<RowDataPacket[]>('SELECT deleted_at FROM users WHERE user_id = ?', [userId]);
                 if (checkAgain.length === 0) {
                     throw new ServiceErorr(`User with ID ${userId} not found (possibly deleted during update).`, 404);
                 } else if (checkAgain[0].deleted_at !== null) {
                     throw new ServiceErorr(`User with ID ${userId} was deleted during the update process.`, 409); // Conflict
                 } else {
                     throw new ServiceErorr(`Failed to update user ${userId}. Update affected 0 rows unexpectedly.`, 500);
                 }
            }

             // Re-fetch the updated user data to return the complete, current state
             const [refetchedRows] = await connection.execute<RowDataPacket[]>(
                 'SELECT user_id, email, password_hash, role, first_name, last_name, created_at, updated_at, deleted_at FROM users WHERE user_id = ?', [userId]
             );
             if (refetchedRows.length === 0) { // Should not happen if update succeeded
                  await connection.rollback();
                  throw new ServiceErorr(`User ${userId} could not be found immediately after successful update.`, 500);
             }
             updatedUserData = refetchedRows[0] as Users;

        } else {
             console.log(`No actual field changes detected for user ${userId}. Skipping UPDATE query.`);
             updatedUserData = existingUser; // Return the data we already fetched
        }

        await connection.commit();
        return updatedUserData;

    } catch (error: unknown) {
        if (connection) {
            try {
                await connection.rollback();
            } catch (rollbackError) {
                console.error(`Failed to rollback transaction during user update for ${userId}:`, rollbackError);
            }
        }

        console.error(`Error updating user ${userId}:`, error);

        if (error instanceof ServiceErorr) {
            throw error; // Re-throw known service errors
        }
         // Log unexpected errors before throwing a generic one
         if (error instanceof Error) {
             console.error("Unexpected Error Details:", error.message, error.stack);
             throw new ServiceErorr(`Failed to update user ${userId} due to an internal error.`, 500);
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

export const createAdmin = async (user: CreateUserInput): Promise<Users> => {
    const { email, password_hash, first_name, last_name } = user;
    let connection: PoolConnection | undefined;

    try {
        connection = await pool.getConnection();
        await connection.beginTransaction();

        // Check if the email is already used by an active account
        const checkSql = 'SELECT user_id FROM users WHERE email = ? AND deleted_at IS NULL';
        const [existing] = await connection.execute<RowDataPacket[]>(checkSql, [email]);

        if (existing.length > 0) {
            await connection.rollback();
            throw new ServiceErorr('Email already used by an active account.', 409);
        }

        // Insert new admin user with ADMIN role
        const insertSql = 'INSERT INTO users (email, password_hash, first_name, last_name, role) VALUES (?, ?, ?, ?, ?)';
        const values = [email, password_hash, first_name, last_name, Role.ADMIN];

        const [result] = await connection.execute<ResultSetHeader>(insertSql, values);

        if (result.affectedRows === 0) {
            await connection.rollback();
            throw new ServiceErorr('Failed to create admin user.', 500);
        }

        // Fetch the newly created admin user
        const [newUserRows] = await connection.execute<RowDataPacket[]>(
            'SELECT user_id, email, role, first_name, last_name, created_at, updated_at FROM users WHERE user_id = ? AND deleted_at IS NULL',
            [result.insertId]
        );

        if (newUserRows.length === 0) {
            await connection.rollback();
            throw new ServiceErorr('Failed to retrieve newly created admin user.', 500);
        }

        const newAdmin = newUserRows[0] as Users;

        await connection.commit();
        console.log(`Successfully created admin user with ID ${newAdmin.user_id} and email ${newAdmin.email}`);
        
        return newAdmin;

    } catch (error: any) {
        if (connection) {
            try {
                await connection.rollback();
            } catch (rollbackError) {
                console.error('Failed to rollback transaction during admin creation:', rollbackError);
            }
        }

        console.error('Error while creating admin user:', error);
        
        if (error instanceof ServiceErorr) {
            throw error;
        }
        throw new ServiceErorr('An internal error occurred while creating the admin user.', 500);

    } finally {
        if (connection) {
            connection.release();
        }
    }
}