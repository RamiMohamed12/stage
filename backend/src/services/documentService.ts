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
        
        interface RqquiredDocumentRow extends RowDataPacket { 
            document_type_id: number;
            name: string;
            description: string | null;
            is_mandatory: 0 | 1; 
        }


        const [rows] = await connection.query<RowDataPacket[]>(sql, [relationshipId]);
        
        if (rows.length === 0) {
            throw new ServiceErorr('No required documents found for the specified relationship.', 404);
        }
                const requiredDocuments: RequiredDocumentInfo[] = rows.map((row: any) => ({
            document_type_id: row.document_type_id,
            name: row.name,
            description: row.description, 
            is_mandatory: row.is_mandatory === 1
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

