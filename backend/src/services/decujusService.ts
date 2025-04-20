import pool from '../config/db';
import {Decujus, DecujusRow} from '../models/Decujus';
import { PoolConnection, RowDataPacket } from 'mysql2/promise';
import {ServiceErorr} from '../services/usersService';

interface VerifyDecujusInput {
    pension_number: string;
    first_name: string | null;
    last_name: string | null;
    date_of_birth: Date | null;
    agency_id: number | null; 
}

interface VerifyDecujusResult {
    isValid: boolean;
    message?: string;
    details?: Partial<Decujus>;
}


export const verifyDecujus = async (input: VerifyDecujusInput): Promise<VerifyDecujusResult> => {

    let connection: PoolConnection | undefined;
    try {
        connection = await pool.getConnection();
        const checksql = 'SELECT * FROM decujus WHERE pension_number = ?';
        const [rows] = await connection.query<RowDataPacket[]>(checksql, [input.pension_number]);

        if (rows.length === 0){
            return { isValid: false, message: 'No decujus found with the provided pension number.' };
        }

        const decujus = rows[0] as DecujusRow;

 
        if (input.first_name && decujus.first_name &&
            input.first_name.toLowerCase() !== decujus.first_name.toLowerCase()) {
            return { isValid: false, message: 'First name does not match our records.' };
        }
        if (input.first_name && !decujus.first_name) {
             return { isValid: false, message: 'First name does not match our records (expected no name).' };
        }

        if (input.last_name && decujus.last_name &&
            input.last_name.toLowerCase() !== decujus.last_name.toLowerCase()) {
            return { isValid: false, message: 'Last name does not match our records.' };
        }
        if (input.last_name && !decujus.last_name) {
             return { isValid: false, message: 'Last name does not match our records (expected no name).' };
        }

        if (input.date_of_birth && decujus.date_of_birth) {
            const inputDateStr = input.date_of_birth.toISOString().split('T')[0];
            const dbDateStr = decujus.date_of_birth.toISOString().split('T')[0];

            if (inputDateStr !== dbDateStr) {
                return { isValid: false, message: 'Date of birth does not match our records.' };
            }
        }
        if (input.date_of_birth && !decujus.date_of_birth) {
             return { isValid: false, message: 'Date of birth does not match our records (expected no DOB).' };
        }

        if (input.agency_id && decujus.agency &&
            input.agency_id !== decujus.agency_id) {
            return { isValid: false, message: 'Agency does not match our records.' };
        }
        // Handle case where input provides an agency but DB has null
        if (input.agency_id && !decujus.agency_id) {
             return { isValid: false, message: 'Agency does not match our records (expected no agency).' };
        }
      
        return {
            isValid: true,
            details: {
                pension_number: decujus.pension_number,
                first_name: decujus.first_name,
                last_name: decujus.last_name,
                date_of_birth: decujus.date_of_birth,
                agency_id: decujus.agency,
                is_pension_active: decujus.is_pension_active
            }
        };
    } catch (error) {
        console.error('Error verifying decujus:', error);
        if (error instanceof ServiceErorr) {
            throw error;
        }
        if (error instanceof Error) {
            throw new ServiceErorr('Error verifying decujus: ' + error.message, 500); // wrap unknown errors
        }
        throw new ServiceErorr('Unknown error verifying decujus', 500);
    } finally {
        if(connection) {
            connection.release();
        }
    }
}