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

export const createInitialDeclarationDocumentRecords = async (declarationId: number, relationshipId: number): Promise<void> => {
 
    let connection: PoolConnection | undefined;
     

    try { 
   
    const requiredDocuments = await getRequiredDocumentsForRelationship(relationshipId);

    if (!requiredDocuments || requiredDocuments.length === 0) {
        return; 
    }

    connection = await pool.getConnection();
    await connection.beginTransaction();

    const sql = ` INSERT INTO declaration_documents (declaration_id, document_type_id, status) VALUES (?, ?, 'pending'); ` 
    console.log(`Creating ${requiredDocuments.length} initial document records for declaration ${declarationId}`);

    for (const document of requiredDocuments) {
        const { document_type_id } = document; 
        await connection.execute(sql, [declarationId, document_type_id]);    
    }

    await connection.commit();
    console.log(`Successfully created initial document records for declaration ${declarationId}`); 

    } catch (error: any) {
        console.error(`Error creating initial declaration document records for declaration ${declarationId}:`, error.message); // Log with declaration ID
        if (connection) {
            try {
                 await connection.rollback();
                 console.log(`Transaction rolled back for declaration ${declarationId}`); // Optional log
            } catch (rollbackError: any) {
                console.error(`Error rolling back transaction for declaration ${declarationId}:`, rollbackError.message);
            }
        }
        if (error instanceof ServiceErorr) {
            throw error; 
        }
        throw new ServiceErorr('Error creating initial declaration document records.', 500);
    }
    finally {
        if (connection) {
            connection.release();
        }
    }
}

interface DeclarationDocumentStatusRow extends RowDataPacket {
    declaration_document_id: number;
    document_type_id: number;
    document_name: string;
    status: DeclarationDocumentStatus; // Use the enum type
    uploaded_file_path: string | null;
    uploaded_at: Date | null;
    rejection_reason: string | null;
    is_mandatory: 0 | 1; // Raw type from DB
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
        const sql = `UPDATE declaration_documents 
        SET 
            status = 'uploaded', 
            uploaded_file_path = ?, 
            -- original_filename = ?, -- We don't have this column in declaration_documents
            uploaded_at = CURRENT_TIMESTAMP 
        WHERE declaration_document_id = ?;`
    
        const [result] = await connection.query(sql, [filePath, declarationDocumentId]);
        const affectedRows = (result as { affectedRows: number }).affectedRows;
        if (affectedRows === 0) {
            throw new ServiceErorr(`No document found with ID ${declarationDocumentId}`, 404);
        }
        console.log(`Document with ID ${declarationDocumentId} updated successfully.`);
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