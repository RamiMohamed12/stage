import pool from '../config/db';
// Import Agency model if you want to return the agency name
import { Agency } from '../models/Agency'; 
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