import pool from '../config/db';
import {PoolConnection, RowDataPacket, ResultSetHeader} from 'mysql2/promise';
import {ServiceErorr} from '../services/usersService';
import { createInitialDeclarationDocumentRecords } from './documentService';
import {CreateDeclarationInput, Declarations} from '../models/Declarations';
import {Status as DeclarationStatus} from '../models/Declarations';
import { Declaration } from 'typescript';
import { deactivatePension } from './decujusService'; // Import deactivatePension

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
        
        // Create initial declaration document records using the existing connection
        await createInitialDeclarationDocumentRecords(declarationId, declaration.relationship_id, connection);

        // Deactivate the pension for the decujus
        if (declaration.decujus_pension_number) {
            await deactivatePension(declaration.decujus_pension_number, declaration.applicant_user_id);
        } else {
            // This case should ideally not happen if decujus_pension_number is required for declaration
            console.warn('Attempted to create declaration without decujus_pension_number, pension not deactivated.');
        }

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
        console.error('[declarationService] Error in createDeclaration:', error); // <--- ADD DETAILED LOGGING
        if (error instanceof ServiceErorr) {
            throw error; // Re-throw known service errors
        } else {
            // Log the original error message if available
            const errorMessage = error instanceof Error ? error.message : 'Failed to create declaration';
            throw new ServiceErorr(errorMessage, 500);
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

export const updateDeclarationStatus = async (
    declarationId: number,
    status: DeclarationStatus.APPROVED | DeclarationStatus.REJECTED,
    adminId: number
): Promise<void> => {
    let connection: PoolConnection | undefined;
    try {
        connection = await pool.getConnection();
        const sql = `UPDATE declarations SET status = ? WHERE declaration_id = ?`;
        const [result] = await connection.query<ResultSetHeader>(sql, [status, declarationId]);

        if (result.affectedRows === 0) {
            const checkSql = `SELECT COUNT(*) as count FROM declarations WHERE declaration_id = ?`;
            const [checkRows] = await connection.query<any[]>(checkSql, [declarationId]);
            if (checkRows[0].count === 0) {
                throw new ServiceErorr(`Declaration with ID ${declarationId} not found.`, 404);
            }
            throw new ServiceErorr(`Declaration with ID ${declarationId} not found or status already set to '${status}'.`, 404);
        }
    } catch (error) {
        if (error instanceof ServiceErorr) {
            throw error;
        } else {
            const err = error as any;
            throw new ServiceErorr(`Failed to update declaration status: ${err.message || 'Unknown error'}`, 500);
        }
    } finally {
        if (connection) {
            connection.release();
        }
    }
}

// Add new interface for declaration check result
export interface DeclarationCheckResult {
    exists: boolean;
    declaration?: Declarations;
    canCreateNew: boolean;
    message: string;
}

export const checkExistingDeclaration = async (pensionNumber: string, userId: number): Promise<DeclarationCheckResult> => {
    let connection: PoolConnection | undefined;
    try {
        connection = await pool.getConnection();
        const sql = `SELECT * FROM declarations WHERE decujus_pension_number = ? ORDER BY created_at DESC LIMIT 1`;
        const [rows] = await connection.query<RowDataPacket[]>(sql, [pensionNumber]);
        
        if (rows.length === 0) {
            return {
                exists: false,
                canCreateNew: true,
                message: 'No existing declaration found. You can create a new declaration.'
            };
        }
        
        const existingDeclaration = rows[0] as Declarations;
        
        // Check if the existing declaration belongs to the same user
        if (existingDeclaration.applicant_user_id === userId) {
            return {
                exists: true,
                declaration: existingDeclaration,
                canCreateNew: false,
                message: 'You have an existing declaration for this pension number. Redirecting to document upload.'
            };
        } else {
            // Different user has already declared for this pension number
            return {
                exists: true,
                declaration: existingDeclaration,
                canCreateNew: false,
                message: 'A declaration already exists for this pension number by another user.'
            };
        }
        
    } catch (error) {
        console.error('[declarationService] Error in checkExistingDeclaration:', error);
        throw new ServiceErorr('Failed to check existing declaration', 500);
    } finally {
        if (connection) {
            connection.release();
        }
    }
}
