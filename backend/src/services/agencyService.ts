import pool from '../config/db';
import {Agency, AgencyRow} from '../models/Agency';
import { PoolConnection, RowDataPacket } from 'mysql2/promise';
import {ServiceErorr} from '../services/usersService';

// function to get all the agencies from the database 
// and return them as an array of Agency objects
export const getAllAgencies = async (): Promise<Agency[]> => {
    
    let connection: PoolConnection | undefined; 
    try{
        connection = await pool.getConnection();
        const sql = 'SELECT * FROM agencies ORDER BY name_agency ASC';
        const [rows] = await connection.query<RowDataPacket[]>(sql);
        if (rows.length === 0){
            throw new ServiceErorr('No agencies found in the database.', 404);
        }
        return rows as Agency[]; 
    } catch (error:any) {
        console.error('Error retrieving agencies:', error.message);
        throw new ServiceErorr('Error retrieving agencies.', 500);
    } finally {
        if (connection) {
            connection.release(); 
        }
    }
}

export const turnAgencyIdIntoName = async (agencyId: number): Promise<string> => {
    let connection: PoolConnection | undefined;

    try { 
        connection = await pool.getConnection();
        const sql = 'SELECT name_agency FROM agencies WHERE agency_id = ?';
        const [rows] = await connection.query<RowDataPacket[]>(sql, [agencyId]);
        if (rows.length === 0) {
            throw new ServiceErorr('Agency not found.', 404);
        }
        const agencyRow = rows[0] as AgencyRow;
        return agencyRow.name_agency; // Return the name of the agency
    }
    catch (error: any) {
        console.error('Error retrieving agency name:', error.message);
        throw new ServiceErorr('Error retrieving agency name.', 500);
    } finally {
        if (connection) {
            connection.release();
        }
    }
}

export const turnAgencyNameIntoId = async (agencyName: string): Promise<number> => { 
    let connection: PoolConnection | undefined; 
    try { 
        connection = await pool.getConnection(); 
        const sql = 'SELECT agency_id FROM agencies WHERE name_agency = ?'; 
        const [rows] = await connection.query<RowDataPacket[]>(sql,[agencyName]); 
        if (rows.length === 0 ){ 
            throw new ServiceErorr('Agency not found.', 404); 
        } 
        const agencyRow = rows[0] as AgencyRow; 
        return agencyRow.agency_id; 
    } catch (error: any) {
        console.error('Error retrieving agency ID:', error.message);
        throw new ServiceErorr('Error retrieving agency ID.', 500); 
    } finally {
        if (connection){
            connection.release()
        }
    }
}