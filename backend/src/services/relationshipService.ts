import pool from '../config/db'; 
import {Relationship, RelationshipRow} from '../models/Relationship'; 
import {PoolConnection, RowDataPacket} from 'mysql2/promise';
import {ServiceErorr} from '../services/usersService';

export const getAllRelationships = async (): Promise<Relationship[]> => {
    let connection = await pool.getConnection(); 
    try { 
        connection = await pool.getConnection(); 
        const sql = 'SELECT * FROM relationships';
        const [rows] = await connection.query<RowDataPacket[]>(sql); 
        if (rows.length === 0) {
            throw new ServiceErorr('No relationships found', 404);
        } 
        return rows as Relationship[]; 
    } catch (error:any) { 
        console.error('Error fetching relationships:', error);
        throw new ServiceErorr('Error fetching relationships', 500);
    } finally {
        if (connection) {
            connection.release();
        }
    } 
}
