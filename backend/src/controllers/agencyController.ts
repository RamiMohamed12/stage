import {Request, Response, NextFunction} from "express";
import * as agencyService from '../services/agencyService';
import {ServiceErorr} from '../services/usersService'; 
import {Agency} from '../models/Agency'; 

export const handleGetAllAgencies = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const agencies: Agency[] = await agencyService.getAllAgencies();
        res.status(200).json(agencies);
    } catch (error: unknown) {
        console.error('Controller error during agency retrieval:', error);
        if (error instanceof ServiceErorr) {
            res.status(error.statusCode).json({ message: error.message });
        } else {
            res.status(500).json({ message: 'Internal server error' });
        }
    }
}