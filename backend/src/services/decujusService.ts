import pool from '../config/db'; 
import {Decujus, DecujusRow} from '../models/Decujus';
import { PoolConnection, RowDataPacket } from 'mysql2/promise';
import {ServiceErorr} from '../services/usersService';

interface VerifyDecujusInput { 
    pension_number: string; 
    first_name: string | null; 
    last_name: string | null; 
    date_of_birth: Date | null; 
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
        // first we check by pension number only 
        const checksql = 'SELECT * FROM decujus WHERE pension_number = ?';
        const [rows] = await connection.query<RowDataPacket[]>(checksql, [input.pension_number]);

        // if there is no matching record we give a message error 
        if (rows.length === 0){ 
            return { isValid: false, message: 'No decujus found with the provided pension number.' };
        }

        // we get the decujus record 
        const decujus = rows[0] as DecujusRow;

        // we check the first_name and last_name, both are converted to lower case to avoid case sensitivity issues
        if (input.first_name && decujus.first_name && 
            input.first_name.toLowerCase() !== decujus.first_name.toLowerCase()) {
            return { isValid: false, message: 'First name does not match our records.' };
        }

        if (input.last_name && decujus.last_name && 
            input.last_name.toLowerCase() !== decujus.last_name.toLowerCase()) {
            return { isValid: false, message: 'Last name does not match our records.' };
        }
        
        // we check the date of birth. 
        if (input.date_of_birth && decujus.date_of_birth) {
         
            const inputDate = typeof input.date_of_birth === 'string' 
                ? new Date(input.date_of_birth).toISOString().split('T')[0] 
                : input.date_of_birth.toISOString().split('T')[0];
                
       
            const dbDate = decujus.date_of_birth instanceof Date 
                ? decujus.date_of_birth.toISOString().split('T')[0]
                : new Date(decujus.date_of_birth).toISOString().split('T')[0];
            
            if (inputDate !== dbDate) {
                return { isValid: false, message: 'Date of birth does not match our records.' };
            }
        }

        // all checks passed - verification successful
        return {
            isValid: true,
            details: {
                pension_number: decujus.pension_number,
                first_name: decujus.first_name,
                last_name: decujus.last_name,
                date_of_birth: decujus.date_of_birth,
                agency: decujus.agency,
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