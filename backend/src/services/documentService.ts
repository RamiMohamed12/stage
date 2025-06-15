import pool from '../config/db';
import {PoolConnection, RowDataPacket} from 'mysql2/promise';
import {ServiceErorr} from '../services/usersService';
import {RequiredDocumentInfo} from '../models/RelationshipRequiredDocuments';
import {
    DeclarationDocuments,
    DeclarationDocumentStatus,
    CreateDeclarationDocumentInput,
    UpdateDeclarationDocumentUploadInput,
    DeclarationDocumentStatusInfo
} from '../models/DeclarationDocuments';
import {DocumentTypes} from '../models/DocumentTypes';
import {Declarations} from '../models/Declarations';


export const getRequiredDocumentsForRelationship= async (relationshipId: number): Promise<RequiredDocumentInfo[]> => {

    let connection : PoolConnection | undefined; 
    try  {
     
        connection = await pool.getConnection(); 
        const sql = ` SELECT 
            dt.document_type_id, 
            dt.name, 
            dt.description, 
            rrd.is_mandatory 
            FROM relationship_required_documents rrd
            JOIN document_types dt ON rrd.document_type_id = dt.document_type_id
            WHERE rrd.relationship_id = ?;
        `;
        
        interface RequiredDocumentRow extends RowDataPacket { 
            document_type_id: number;
            name: string;
            description: string | null;
            is_mandatory: 0 | 1; 
        }


        const [rows] = await connection.query<RowDataPacket[]>(sql, [relationshipId]);
        
        if ((rows as RowDataPacket[]).length === 0) {
            return []; // No required documents found for the given relationship
        }
        const requiredDocuments: RequiredDocumentInfo[] = (rows as RequiredDocumentRow[]).map((row) => ({
            document_type_id: row.document_type_id,
            name: row.name,
            description: row.description, 
            is_mandatory: row.is_mandatory === 1 // Correct conversion
        })); 
        return requiredDocuments;

    } catch (error: any) {
        console.error('Error retrieving required documents:', error.message);
        if (error instanceof ServiceErorr) {
            throw error; // Rethrow known errors
        }
        throw new ServiceErorr('Error retrieving required documents.', 500);
    }
    finally {
        if (connection) {
            connection.release();
        }
    }
} 

export const createInitialDeclarationDocumentRecords = async (
    declarationId: number, 
    relationshipId: number, 
    existingConnection?: PoolConnection
): Promise<void> => {
    // First, get required documents outside of any transaction to minimize transaction time
    const requiredDocuments = await getRequiredDocumentsForRelationship(relationshipId);

    if (!requiredDocuments || requiredDocuments.length === 0) {
        console.log(`No required documents found for relationship ${relationshipId}, skipping initial document creation for declaration ${declarationId}`);
        return; 
    }

    // Prepare batch insert data outside transaction
    const values: (number | string)[] = [];
    const sqlPlaceholders: string[] = [];

    console.log(`Preparing ${requiredDocuments.length} initial document records for declaration ${declarationId}`);

    for (const document of requiredDocuments) {
        sqlPlaceholders.push('(?, ?, \'pending\')');
        values.push(declarationId, document.document_type_id);
    }

    if (sqlPlaceholders.length === 0) {
        console.log(`No documents were prepared for batch insert for declaration ${declarationId}.`);
        return;
    }

    const sql = `INSERT INTO declaration_documents (declaration_id, document_type_id, status) VALUES ${sqlPlaceholders.join(', ')};`;

    let connection: PoolConnection | undefined;
    let shouldReleaseConnection = false;
    
    try {
        // Use existing connection if provided, otherwise get a new one
        if (existingConnection) {
            connection = existingConnection;
        } else {
            connection = await pool.getConnection();
            shouldReleaseConnection = true;
            // Set a shorter lock wait timeout for this specific operation
            await connection.execute('SET SESSION innodb_lock_wait_timeout = 5');
        }
        
        // Use a simple execute - transaction is handled by the caller if existingConnection is provided
        await connection.execute(sql, values);
        
        console.log(`Successfully created ${requiredDocuments.length} initial document records for declaration ${declarationId} in a batch.`); 
        
    } catch (error: any) {
        console.error(`Error creating initial declaration document records for declaration ${declarationId}:`, error.message);
        
        if (error instanceof ServiceErorr) {
            throw error; 
        }
        throw new ServiceErorr('Error creating initial declaration document records.', 500);
        
    } finally {
        // Only release connection if we created it ourselves
        if (connection && shouldReleaseConnection) {
            connection.release();
        }
    }
}


export const getDeclarationDocumentsStatus = async (declarationId: number): Promise<DeclarationDocumentStatusInfo[]> => {

    let connection: PoolConnection | undefined; 

    try { 
        connection = await pool.getConnection(); 
        const sql = ` SELECT 
        dd.declaration_document_id, 
        dd.document_type_id, 
        dt.name AS document_name, 
        dd.status, 
        dd.uploaded_file_path, 
        dd.uploaded_at, 
        dd.rejection_reason,
        rrd.is_mandatory -- Get mandatory status based on the relationship linked to the declaration
        FROM declaration_documents dd
        JOIN document_types dt ON dd.document_type_id = dt.document_type_id
        JOIN declarations d ON dd.declaration_id = d.declaration_id -- Join declarations to get relationship_id
        JOIN relationship_required_documents rrd ON d.relationship_id = rrd.relationship_id AND dd.document_type_id = rrd.document_type_id -- Join based on relationship AND document type
        WHERE dd.declaration_id = ?;`

        const [rows] = await connection.query<RowDataPacket[]>(sql, [declarationId]);
        if (rows.length === 0) {
            console.log(`No documents found for declaration ID ${declarationId}`); // Log if no documents found
            return []; 
        }

        const declarationDocuments: DeclarationDocumentStatusInfo[] = rows.map((row) => ({
            declaration_document_id: row.declaration_document_id,
            document_type_id: row.document_type_id,
            document_name: row.document_name,
            status: row.status, // Already correct type due to interface
            uploaded_file_path: row.uploaded_file_path,
            uploaded_at: row.uploaded_at,
            rejection_reason: row.rejection_reason,
            is_mandatory: row.is_mandatory === 1 // Correct conversion from 0|1 to boolean
        }));

        return declarationDocuments;
    
    } catch (error: any) {
        console.error('Error retrieving declaration documents status:', error.message);
        if (error instanceof ServiceErorr) {
            throw error; // Rethrow known errors
        }
        throw new ServiceErorr('Error retrieving declaration documents status.', 500);
    }
    finally {
        if (connection) {
            connection.release();
        }
    }
}

export const updateDocumentOnUpload = async (declarationDocumentId: number, filePath: string, originalFilename: string | null): Promise<void> => {  

    let connection: PoolConnection | undefined; 
    try { 
        connection = await pool.getConnection();
        
        // Convert absolute file path to relative path for HTTP serving
        // Extract just the filename from the full path
        const filename = filePath.split('/').pop() || filePath.split('\\').pop() || filePath;
        const relativePath = `/uploads/${filename}`;
        
        const sql = `UPDATE declaration_documents 
        SET 
            status = 'uploaded', 
            uploaded_file_path = ?, 
            uploaded_at = CURRENT_TIMESTAMP 
        WHERE declaration_document_id = ?;`
    
        const [result] = await connection.query(sql, [relativePath, declarationDocumentId]);
        const affectedRows = (result as { affectedRows: number }).affectedRows;
        if (affectedRows === 0) {
            throw new ServiceErorr(`No document found with ID ${declarationDocumentId}`, 404);
        }
        console.log(`Document with ID ${declarationDocumentId} updated successfully with path: ${relativePath}`);
    } catch (error: any) {
        console.error('Error updating document on upload:', error.message);
        if (error instanceof ServiceErorr) {
            throw error; // Rethrow known errors
        }
        throw new ServiceErorr('Error updating document on upload.', 500);
    }
    finally {
        if (connection) {
            connection.release();
        }
    }
} 

export const reviewDocument = async (declarationDocumentId: number, adminId: number, newStatus:'verified' | 'rejected', rejectionReason: string | null): Promise<void> => {

    let connection: PoolConnection | undefined; 
    try  {
        connection = await pool.getConnection(); 
        const sql = `UPDATE declaration_documents
        SET
            status = ?,
            reviewed_by_admin_id = ?,
            reviewed_at = CURRENT_TIMESTAMP,
            rejection_reason = ? 
        WHERE declaration_document_id = ?;`
        if (newStatus === 'rejected' && !rejectionReason) {
            throw new ServiceErorr('Rejection reason is required when status is "rejected".', 400);
        }

        const reasonToStore = newStatus === 'rejected' ? rejectionReason: null; 

        const [result] = await connection.query(sql, [newStatus, adminId, reasonToStore, declarationDocumentId]);
        const affectedRows = (result as { affectedRows: number }).affectedRows;
        if (affectedRows === 0) {
            throw new ServiceErorr(`No document found with ID ${declarationDocumentId}`, 404);
        }
        console.log(`Document with ID ${declarationDocumentId} reviewed successfully.`);
    } catch (error: any) {
        console.error('Error reviewing document:', error.message);
        if (error instanceof ServiceErorr) {
            throw error; // Rethrow known errors
        }
        throw new ServiceErorr('Error reviewing document.', 500);
    }
    finally {
        if (connection) {
            connection.release();
        }
    }
}

export const checkAllMandatoryDocumentsVerified = async (declarationId: number): Promise<boolean> => {

    let connection: PoolConnection | undefined; 
    try { 
        connection = await pool.getConnection(); 
        const sql = `SELECT 
        (COUNT(CASE WHEN rrd.is_mandatory = 1 THEN dd.document_type_id END) = 0) OR -- Case 1: No mandatory documents exist for this relationship ( COUNT(CASE WHEN rrd.is_mandatory = 1 THEN dd.document_type_id END) > 0 AND -- Case 2: Mandatory documents exist
            COUNT(CASE WHEN rrd.is_mandatory = 1 AND dd.status != 'verified' THEN dd.document_type_id END) = 0 -- And none of them are in a non-verified state
        ) AS all_verified
        FROM declaration_documents dd
        JOIN declarations d ON dd.declaration_id = d.declaration_id
        JOIN relationship_required_documents rrd 
            ON d.relationship_id = rrd.relationship_id AND dd.document_type_id = rrd.document_type_id
        WHERE dd.declaration_id = ?;`
        const [rows] = await connection.query<RowDataPacket[]>(sql, [declarationId]);
        if (rows.length === 0) {
            console.warn(`No documents found for declaration ID ${declarationId}`); // Log if no documents found
            return false; 
        }
        const verifiedResult = (rows[0] as { all_verified: 0 | 1 }).all_verified;
        if (!verifiedResult) {
            console.log(`Not all mandatory documents are verified for declaration ID ${declarationId}`); // Log if not all documents are verified
            return false; 
        }
        console.log(`All mandatory documents are verified for declaration ID ${declarationId}`); // Log if all documents are verified
        return true;
    } catch (error: any) {
        console.error('Error checking mandatory documents verification:', error.message);
        if (error instanceof ServiceErorr) {
            throw error; // Rethrow known errors
        }
        throw new ServiceErorr('Error checking mandatory documents verification.', 500);

    } finally {
        if (connection) {
            connection.release();
        }
    }
}

export const getApplicantUserIdForDeclarationDocument = async (declarationDocumentId: number): Promise<number | null> => {
    
    let connection: PoolConnection | undefined; 
    try { 
        connection = await pool.getConnection(); 
        const sql = `
            SELECT d.applicant_user_id
            FROM declaration_documents dd
            JOIN declarations d ON dd.declaration_id = d.declaration_id
            WHERE dd.declaration_document_id = ?;` 
        const [rows] = await connection.query<RowDataPacket[]>(sql, [declarationDocumentId]);
        if (rows.length === 0 ){ 
            return null; 
        }
        return rows[0].applicant_user_id as number; 
    } catch (error: any) {
        console.error('Error fetching applicant user ID for declaration for declaration document: ', error.message);
        if (!(error instanceof ServiceErorr)){ 
            throw new ServiceErorr('Error fetching applicant user ID for declaration document.', 500); 
        }
    } finally { 
        if (connection) {
            connection.release(); 
        }
    }
    return null; // Ensure all code paths return a value
}