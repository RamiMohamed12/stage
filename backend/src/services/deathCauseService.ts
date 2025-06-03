import pool from '../config/db';
// DeathCause model is imported but its camelCase structure is not what we send.
// import {DeathCause, DeathCauseRow} from '../models/DeathCause'; 
import { PoolConnection, RowDataPacket } from 'mysql2/promise';
import {ServiceErorr} from '../services/usersService';

export const getAllDeathCauses = async (): Promise<any[]> => { // Changed return type to Promise<any[]>

    let connection: PoolConnection | undefined; 
    try { 

        connection = await pool.getConnection(); 
        const sql = 'SELECT id, cause_name FROM death_causes'; // Be explicit with columns
        const [rows]= await connection.query<RowDataPacket[]>(sql);
        if (rows.length === 0) {
            // Consider if this should be an error or an empty array
            // For dropdowns, an empty array is often fine.
            return [];
            // throw new ServiceErorr('No death causes found in the database.', 404); 
        }
        // Map database rows to the structure expected by the frontend (snake_case)
        return rows.map(row => ({
            death_cause_id: row.id,
            cause_name: row.cause_name
        })); // Removed 'as DeathCause[]'
    } catch (error:any) {
        console.error('Error retrieving death causes:', error.message); 
        throw new ServiceErorr('Error retrieving death causes.', 500); 
    }
    finally {
        if (connection) {
            connection.release(); 
        }
    }   
}