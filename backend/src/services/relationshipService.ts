import pool from '../config/db'; 
// Ensure Relationship model is imported if you use its type, otherwise remove or use 'any'
// import {Relationship} from '../models/Relationship'; 
import {PoolConnection, RowDataPacket} from 'mysql2/promise';
import {ServiceErorr} from '../services/usersService';

export const getAllRelationships = async (): Promise<any[]> => { // Return Promise<any[]> as the structure is for frontend
    let connection: PoolConnection | undefined; 
    try { 
        connection = await pool.getConnection(); 
        // Explicitly select the columns needed
        const sql = 'SELECT id, description FROM relationships';
        const [rows] = await connection.query<RowDataPacket[]>(sql); 

        console.log('[relationshipService] Raw rows from DB:', JSON.stringify(rows, null, 2)); // Log raw rows

        if (rows.length === 0) {
            console.log('[relationshipService] No relationships found, returning empty array.');
            return []; // Return empty array if no data
        } 
        
        const mappedRelationships = rows.map(row => {
            // Ensure row.description is accessed correctly.
            // The database output shows 'description' as the column name.
            return {
                relationship_id: row.id, 
                relationship_name: row.description 
            };
        });

        console.log('[relationshipService] Mapped relationships to be sent:', JSON.stringify(mappedRelationships, null, 2)); // Log mapped rows
        
        return mappedRelationships; 

    } catch (error:any) { 
        console.error('[relationshipService] Error fetching relationships:', error);
        // Avoid throwing ServiceErorr here if the frontend expects an array,
        // or ensure frontend handles errors gracefully for this specific call.
        // For now, rethrowing to see the error if it occurs.
        throw new ServiceErorr(error.message || 'Error fetching relationships', error.statusCode || 500);
    } finally {
        if (connection) {
            connection.release();
        }
    } 
}
