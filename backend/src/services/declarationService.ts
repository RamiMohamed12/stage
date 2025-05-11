import pool from '../config/db';
import {PoolConnection, RowDataPacket, ResultSetHeader} from 'mysql2/promise';
import {ServiceErorr} from '../services/usersService';
import { createInitialDeclarationDocumentRecords } from './documentService';
import {CreateDeclarationInput, Declarations} from '../models/Declarations';

export const createDeclaration = async (declaration: CreateDeclarationInput): Promise<Declarations> => {
    
    let connection: PoolConnection | undefined; 
    try { 
        connection = await pool.getConnection();
        await connection.beginTransaction();
        const sql = `INSERT INTO declarations (applicant_user_id, decujus_pension_number, relationship_id, death_cause_id, declaration_date, status) 
        VALUES (?, ?, ?, ?, ?, ?)`;
        const [result] = await connection.query<ResultSetHeader>(sql, [
            declaration.applicant_user_id,
            declaration.decujus_pension_number,
            declaration.relationship_id,
            declaration.death_cause_id,
            declaration.declaration_date,
            declaration.status
        ]);
        if (result.affectedRows === 0) {
            throw new ServiceErorr('Failed to create declaration', 500);
        }
        const declarationId = (result as any).insertId; // Get the inserted declaration ID
        // Create initial declaration document records
        await createInitialDeclarationDocumentRecords(declarationId, declaration.relationship_id);
        await connection.commit();
        return {
            declaration_id: declarationId,
            applicant_user_id: declaration.applicant_user_id,
            decujus_pension_number: declaration.decujus_pension_number,
            relationship_id: declaration.relationship_id,
            death_cause_id: declaration.death_cause_id,
            declaration_date: declaration.declaration_date,
            status: declaration.status,
            created_at: new Date(),
            updated_at: new Date()
        } as Declarations; // Return the created declaration
    } catch (error) {
        if (connection) {
            await connection.rollback();
        }
        if (error instanceof ServiceErorr) {
            throw error; // Re-throw known service errors
        } else {
            throw new ServiceErorr('Failed to create declaration', 500);
        }
}   finally {
        if (connection) {
            connection.release();
        }
    }
} 

export const getDeclarationById = async (declarationId: number): Promise<Declarations | null> => {
    let connection: PoolConnection | undefined;
    try {
        connection = await pool.getConnection();
        const sql = `SELECT * FROM declarations WHERE declaration_id = ?`;
        const [rows] = await connection.query<RowDataPacket[]>(sql, [declarationId]);
        if (rows.length === 0) {
            return null; // No declaration found
        }
        return rows[0] as Declarations; // Return the first row as a Declarations object
    } catch (error) {
        throw new ServiceErorr('Failed to retrieve declaration', 500);
    } finally {
        if (connection) {
            connection.release();
        }
    }
}
 
export const getAllDeclarations = async (): Promise<Declarations[]> => {
    let connection: PoolConnection | undefined;
    try {
        connection = await pool.getConnection();
        const sql = `SELECT * FROM declarations`;
        const [rows] = await connection.query<RowDataPacket[]>(sql);
        return rows as Declarations[]; // Return all declarations
    } catch (error) {
        throw new ServiceErorr('Failed to retrieve declarations', 500);
    } finally {
        if (connection) {
            connection.release();
        }
    }
}

