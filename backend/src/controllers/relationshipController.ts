import {Request, Response,NextFunction} from 'express';
import * as relationshipService from '../services/relationshipService';
import * as documentService from '../services/documentService';
import {ServiceErorr} from '../services/usersService';
import {Relationship} from '../models/Relationship'; 


export const handleGetAllRelationship = async (req: Request, res: Response, next: NextFunction): Promise<void> => { 
    try { 
        const relationships = await relationshipService.getAllRelationships();
        res.status(200).json(relationships);
    } catch (error: unknown) { 
        console.error("Controller error during relationship retrieval:", error);
        if (error instanceof ServiceErorr) { 
            res.status(500).json({ error: error.message });
        } else { 
            res.status(500).json({ error: 'Internal server error' });
        }
    } 
}

export const handleGetRequiredDocumentsForRelationship = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const relationshipId = parseInt(req.params.relationshipId, 10);
        
        if (isNaN(relationshipId)) {
            res.status(400).json({ message: 'Invalid relationship ID' });
            return;
        }

        const requiredDocuments = await documentService.getRequiredDocumentsForRelationship(relationshipId);
        res.status(200).json(requiredDocuments);
    } catch (error: unknown) {
        console.error("Controller error during required documents retrieval:", error);
        if (error instanceof ServiceErorr) {
            res.status(error.statusCode || 500).json({ error: error.message });
        } else {
            res.status(500).json({ error: 'Internal server error' });
        }
    }
}
