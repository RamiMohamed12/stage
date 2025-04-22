import {Request, Response,NextFunction} from 'express';
import * as relationshipService from '../services/relationshipService';
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
