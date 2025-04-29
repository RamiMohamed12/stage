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
        
        if (rows.length === 0) {
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

export const createInitialDeclarationDocumentRecords = async (decalarationId: number, relationshipId: number): Promise<void> => {
    
    let connection: PoolConnection | undefined;
    const requiredDocuments = await getRequiredDocumentsForRelationship(relationshipId);
    if (!requiredDocuments || requiredDocuments.length === 0) {
        return; 
    } 

    try { 
   
    connection = await pool.getConnection();
    await connection.beginTransaction();

    const sql = ` INSERT INTO declaration_documents (declaration_id, document_type_id, status) VALUES (?, ?, 'pending'); ` 
    
    for (const document of requiredDocuments) {
        const { document_type_id } = document; 
        await connection.execute(sql, [decalarationId, document_type_id]);    
    }

    if (requiredDocuments.length === 0 ){
        throw new ServiceErorr('No required documents found for the given relationship.', 404);
    }

    await connection.commit();

    } catch (error: any) {
        console.error('Error creating initial declaration document records:', error.message);
        if (connection) {
            await connection.rollback();
        }
        if (error instanceof ServiceErorr) {
            throw error; // Rethrow known errors
        }
        throw new ServiceErorr('Error creating initial declaration document records.', 500);
    }
    finally {
        if (connection) {
            connection.release();
        }
    }
}