import pool from '../config/db';
import {PoolConnection, RowDataPacket, ResultSetHeader} from 'mysql2/promise';
import {ServiceErorr} from '../services/usersService';
import { createInitialDeclarationDocumentRecords } from './documentService';
import {CreateDeclarationInput, Declarations} from '../models/Declarations';
import {Status as DeclarationStatus} from '../models/Declarations';
import { Declaration } from 'typescript';
import { deactivatePension } from './decujusService'; // Import deactivatePension

// New interface for admin dashboard declarations with user info
export interface AdminDeclarationView {
    declaration_id: number;
    applicant_user_id: number;
    decujus_pension_number: string | null;
    relationship_id: number;
    death_cause_id: number | null;
    declaration_date: Date;
    status: DeclarationStatus;
    created_at: Date;
    updated_at: Date;
    declarant_name: string;
    declarant_email: string;
    user_first_name: string | null;
    user_last_name: string | null;
    total_documents: number;
    pending_documents: number;
    uploaded_documents: number;
    verified_documents: number;
    rejected_documents: number;
    mandatory_documents: number;
    mandatory_verified: number;
}

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

export const getUserPendingDeclaration = async (userId: number): Promise<Declarations | null> => {
    let connection: PoolConnection | undefined;
    try {
        connection = await pool.getConnection();
        
        // Get user's most recent declaration that has uploaded documents still under review
        const sql = `
            SELECT DISTINCT d.*
            FROM declarations d
            JOIN declaration_documents dd ON d.declaration_id = dd.declaration_id
            WHERE d.applicant_user_id = ? 
            AND dd.uploaded_file_path IS NOT NULL 
            AND dd.status IN ('pending', 'uploaded')
            ORDER BY d.created_at DESC
            LIMIT 1
        `;
        
        const [rows] = await connection.query<RowDataPacket[]>(sql, [userId]);
        
        if (rows.length === 0) {
            return null;
        }
        
        return rows[0] as Declarations;
        
    } catch (error) {
        console.error('[declarationService] Error in getUserPendingDeclaration:', error);
        throw new ServiceErorr('Failed to get user pending declaration', 500);
    } finally {
        if (connection) {
            connection.release();
        }
    }
}

// New function for admin to get all declarations with user info and document stats
export const getAllDeclarationsForAdmin = async (
    limit: number = 10,
    offset: number = 0,
    status?: string,
    search?: string
): Promise<{ declarations: AdminDeclarationView[]; total: number }> => {
    let connection: PoolConnection | undefined;
    try {
        connection = await pool.getConnection();
        
        // Build WHERE clause for filtering
        let whereClause = 'WHERE 1=1';
        const queryParams: any[] = [];
        
        if (status && status !== 'all') {
            whereClause += ' AND d.status = ?';
            queryParams.push(status);
        }
        
        if (search) {
            whereClause += ' AND (u.first_name LIKE ? OR u.last_name LIKE ? OR u.email LIKE ? OR d.decujus_pension_number LIKE ?)';
            const searchParam = `%${search}%`;
            queryParams.push(searchParam, searchParam, searchParam, searchParam);
        }
        
        // Get total count for pagination
        const countSql = `
            SELECT COUNT(DISTINCT d.declaration_id) as total
            FROM declarations d
            JOIN users u ON d.applicant_user_id = u.user_id
            ${whereClause}
        `;
        
        const [countRows] = await connection.query<RowDataPacket[]>(countSql, queryParams);
        const total = countRows[0].total;
        
        // Get declarations with user info and document statistics
        const sql = `
            SELECT 
                d.declaration_id,
                d.applicant_user_id,
                d.decujus_pension_number,
                d.relationship_id,
                d.death_cause_id,
                d.declaration_date,
                d.status,
                d.created_at,
                d.updated_at,
                u.email as declarant_email,
                u.first_name as user_first_name,
                u.last_name as user_last_name,
                CONCAT(COALESCE(u.first_name, ''), ' ', COALESCE(u.last_name, '')) as declarant_name,
                COUNT(dd.declaration_document_id) as total_documents,
                COUNT(CASE WHEN dd.status = 'pending' THEN 1 END) as pending_documents,
                COUNT(CASE WHEN dd.status = 'uploaded' THEN 1 END) as uploaded_documents,
                COUNT(CASE WHEN dd.status = 'verified' THEN 1 END) as verified_documents,
                COUNT(CASE WHEN dd.status = 'rejected' THEN 1 END) as rejected_documents,
                COUNT(CASE WHEN rrd.is_mandatory = 1 THEN 1 END) as mandatory_documents,
                COUNT(CASE WHEN rrd.is_mandatory = 1 AND dd.status = 'verified' THEN 1 END) as mandatory_verified
            FROM declarations d
            JOIN users u ON d.applicant_user_id = u.user_id
            LEFT JOIN declaration_documents dd ON d.declaration_id = dd.declaration_id
            LEFT JOIN relationship_required_documents rrd ON d.relationship_id = rrd.relationship_id AND dd.document_type_id = rrd.document_type_id
            ${whereClause}
            GROUP BY d.declaration_id, d.applicant_user_id, d.decujus_pension_number, d.relationship_id, 
                     d.death_cause_id, d.declaration_date, d.status, d.created_at, d.updated_at,
                     u.email, u.first_name, u.last_name
            ORDER BY d.created_at DESC
            LIMIT ? OFFSET ?
        `;
        
        const [rows] = await connection.query<RowDataPacket[]>(sql, [...queryParams, limit, offset]);
        
        const declarations = rows.map(row => ({
            declaration_id: row.declaration_id,
            applicant_user_id: row.applicant_user_id,
            decujus_pension_number: row.decujus_pension_number,
            relationship_id: row.relationship_id,
            death_cause_id: row.death_cause_id,
            declaration_date: row.declaration_date,
            status: row.status,
            created_at: row.created_at,
            updated_at: row.updated_at,
            declarant_name: row.declarant_name?.trim() || 'Unknown',
            declarant_email: row.declarant_email,
            user_first_name: row.user_first_name,
            user_last_name: row.user_last_name,
            total_documents: row.total_documents || 0,
            pending_documents: row.pending_documents || 0,
            uploaded_documents: row.uploaded_documents || 0,
            verified_documents: row.verified_documents || 0,
            rejected_documents: row.rejected_documents || 0,
            mandatory_documents: row.mandatory_documents || 0,
            mandatory_verified: row.mandatory_verified || 0
        })) as AdminDeclarationView[];
        
        return {
            declarations,
            total
        };
        
    } catch (error) {
        console.error('[declarationService] Error in getAllDeclarationsForAdmin:', error);
        throw new ServiceErorr('Failed to get declarations for admin', 500);
    } finally {
        if (connection) {
            connection.release();
        }
    }
};

