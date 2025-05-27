import pool from '../config/db';
// Import Agency model if you want to return the agency name
import { Agency } from '../models/Agency'; 
import {Decujus, DecujusRow} from '../models/Decujus';
import { PoolConnection, RowDataPacket, ResultSetHeader } from 'mysql2/promise';
import {ServiceErorr} from '../services/usersService';

interface VerifyDecujusInput {
    pension_number: string;
    first_name: string | null;
    last_name: string | null;
    date_of_birth: Date | null;
    agency_id: number | null; 
}

// Define an interface for the result of the JOIN query
interface DecujusWithAgencyRow extends DecujusRow {
    name_agency: string | null; // Add the agency name from the JOIN
}

// Adjust the details returned if needed, maybe include agency name
interface VerifyDecujusResultDetails extends Partial<Decujus> {
    agency_name?: string | null; 
}

interface VerifyDecujusResult {
    isValid: boolean;
    message?: string;
    details?: VerifyDecujusResultDetails; // Use the extended details interface
}


export const verifyDecujus = async (input: VerifyDecujusInput): Promise<VerifyDecujusResult> => {

    let connection: PoolConnection | undefined;
    try {
        connection = await pool.getConnection();
        // Modify SQL to JOIN with agencies and select necessary columns including agency name
        const checksql = `
            SELECT 
                d.decujus_id, d.pension_number, d.first_name, d.last_name, 
                d.date_of_birth, d.agency_id, d.is_pension_active,
                a.name_agency 
            FROM decujus d
            LEFT JOIN agencies a ON d.agency_id = a.agency_id 
            WHERE d.pension_number = ?
        `;
        // Use the new interface for the query result type
        const [rows] = await connection.query<DecujusWithAgencyRow[]>(checksql, [input.pension_number]);

        if (rows.length === 0){
            return { isValid: false, message: 'No decujus found with the provided pension number.' };
        }

        // Cast to the specific row type including agency name
        const decujus = rows[0]; 

 
        if (input.first_name && decujus.first_name &&
            input.first_name.toLowerCase() !== decujus.first_name.toLowerCase()) {
            return { isValid: false, message: 'First name does not match our records.' };
        }
        // Check if input has first_name but DB record doesn't
        if (input.first_name && !decujus.first_name) {
             return { isValid: false, message: 'First name does not match our records (expected no first name).' };
        }
        // Check if input does NOT have first_name but DB record does
        if (!input.first_name && decujus.first_name) {
             return { isValid: false, message: 'First name does not match our records (expected a first name).' };
        }


        if (input.last_name && decujus.last_name &&
            input.last_name.toLowerCase() !== decujus.last_name.toLowerCase()) {
            return { isValid: false, message: 'Last name does not match our records.' };
        }
        // Check if input has last_name but DB record doesn't
        if (input.last_name && !decujus.last_name) {
             return { isValid: false, message: 'Last name does not match our records (expected no last name).' };
        }
        // Check if input does NOT have last_name but DB record does
        if (!input.last_name && decujus.last_name) {
             return { isValid: false, message: 'Last name does not match our records (expected a last name).' };
        }


        if (input.date_of_birth && decujus.date_of_birth) {
            // Ensure dates are compared correctly (comparing Date objects directly might be better)
            const inputDate = new Date(input.date_of_birth.setHours(0, 0, 0, 0)); // Normalize input date
            const dbDate = new Date(decujus.date_of_birth.setHours(0, 0, 0, 0)); // Normalize DB date

            if (inputDate.getTime() !== dbDate.getTime()) {
                return { isValid: false, message: 'Date of birth does not match our records.' };
            }
        }
        // Check if input has DOB but DB record doesn't
        if (input.date_of_birth && !decujus.date_of_birth) {
             return { isValid: false, message: 'Date of birth does not match our records (expected no DOB).' };
        }
         // Check if input does NOT have DOB but DB record does
        if (!input.date_of_birth && decujus.date_of_birth) {
             return { isValid: false, message: 'Date of birth does not match our records (expected a DOB).' };
        }

        // Compare agency_id (the foreign key)
        if (input.agency_id !== null && decujus.agency_id !== null &&
            input.agency_id !== decujus.agency_id) {
            return { isValid: false, message: 'Agency does not match our records.' };
        }
        // Handle case where input provides an agency but DB has null
        if (input.agency_id !== null && decujus.agency_id === null) {
             return { isValid: false, message: 'Agency does not match our records (expected no agency).' };
        }
        // Handle case where input expects no agency but DB has one
        if (input.agency_id === null && decujus.agency_id !== null) {
             return { isValid: false, message: 'Agency does not match our records (expected an agency).' };
        }
      
        // Return details including the agency name from the JOIN
        return {
            isValid: true,
            details: {
                pension_number: decujus.pension_number,
                first_name: decujus.first_name,
                last_name: decujus.last_name,
                date_of_birth: decujus.date_of_birth,
                agency_id: decujus.agency_id, // Return the ID
                agency_name: decujus.name_agency, // Return the name
                is_pension_active: decujus.is_pension_active
            }
        };
    } catch (error) {
        console.error('Error verifying decujus:', error);
        // Re-throw specific ServiceErorr instances
        if (error instanceof ServiceErorr) {
            throw error;
        }
        // Wrap other errors in a generic ServiceErorr
        if (error instanceof Error) {
            throw new ServiceErorr('Error verifying decujus: ' + error.message, 500); 
        }
        // Fallback for non-Error types
        throw new ServiceErorr('Unknown error verifying decujus', 500);
    } finally {
        if(connection) {
            connection.release();
        }
    }
}

export const verifyDecujusByPensionNumber = async (pension_number: string): Promise<Decujus | null> =>{
    let connection : PoolConnection | undefined;
    try {
        connection = await pool.getConnection(); 
        const sql = 'SELECT * FROM decujus WHERE pension_number = ?';
        const  [rows] = await connection.query<DecujusRow[]>(sql, [pension_number]);
        if (rows.length === 0) {
            return null; // No decujus found with the given pension number
        }
        const decujus = rows[0]; // Assuming pension_number is unique, take the first row
        return {
            decujus_id: decujus.decujus_id,
            pension_number: decujus.pension_number,
            first_name: decujus.first_name,
            last_name: decujus.last_name,
            date_of_birth: decujus.date_of_birth ? new Date(decujus.date_of_birth) : null,
            agency_id: decujus.agency_id,
            is_pension_active: typeof decujus.is_pension_active === 'number' ? decujus.is_pension_active === 1 : !!decujus.is_pension_active
        } as Decujus; // Cast to Decujus type


    } catch (error: any) {
        console.error('Error verifying decujus by pension number:', error.message);
        if (error instanceof ServiceErorr) {
            throw error;
        }
        throw new ServiceErorr('Error verifying decujus by pension number: ' + error.message, 500);
    }
}



export const deactivatePension = async (pension_number: string, userId: number): Promise<void> => {
    let connection: PoolConnection | undefined;
    try {
        connection = await pool.getConnection();
        const updateSql = 'UPDATE decujus SET is_pension_active = 0 WHERE pension_number = ? AND is_pension_active = 1';
        const [result] = await connection.query<ResultSetHeader>(updateSql, [pension_number]);

        if (result.affectedRows === 0) {
            const checkSql = 'SELECT is_pension_active FROM decujus WHERE pension_number = ?';
            const [rows] = await connection.query<RowDataPacket[]>(checkSql, [pension_number]);

            if (rows.length === 0) {
                throw new ServiceErorr(`No decujus found with pension number ${pension_number}.`, 404);
            }
            if (rows[0].is_pension_active === 0 || rows[0].is_pension_active === false) {
                return;
            }
            throw new ServiceErorr(`Failed to deactivate pension for ${pension_number}. Record found but update failed.`, 500);
        }
    } catch (error: any) {
        if (error instanceof ServiceErorr) {
            throw error;
        }
        console.error('Error deactivating pension:', error.message);
        throw new ServiceErorr('An unexpected error occurred while deactivating the pension.', 500);
    } finally {
        if (connection) {
            connection.release();
        }
    }
};
