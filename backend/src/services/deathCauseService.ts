import pool from '../config/db';
import {DeathCause, DeathCauseRow} from '../models/DeathCause';
import { PoolConnection, RowDataPacket } from 'mysql2/promise';
import {ServiceErorr} from '../services/usersService';

export const getAllDeathCauses = async (): Promise<DeathCause[]> => {

    let connection: PoolConnection | undefined; 
    try { 

        connection = await pool.getConnection(); 
        const sql = 'SELECT * FROM death_cause'; 
        const [rows]= await connection.query<RowDataPacket[]>(sql);
        if (rows.length === 0) {
            throw new ServiceErorr('No death causes found in the database.', 404); 
        }
        return rows as DeathCause[]; 
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