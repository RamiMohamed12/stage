import e, {Request, Response, NextFunction} from "express";
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

export const handleGetAgencyNameById = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    const agencyId = parseInt(req.params.agencyId, 10);
    if (isNaN(agencyId)) {
        res.status(400).json({ message: 'Invalid agency ID' });
        return; 
    }
    try { 
        const agencyName: string = await agencyService.turnAgencyIdIntoName(agencyId);
        res.status(200).json({ name_agency: agencyName });
    }
    catch (error: unknown) {
        console.error('Controller error during agency name retrieval:', error);
        if (error instanceof ServiceErorr) {
          res.status(error.statusCode).json({ message: error.message });
        } else {
            res.status(500).json({ message: 'Internal server error' });
        }
    }
}

export const handleGetAgencyIdbyName = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    const agencyName = req.params.agencyName;
    if (!agencyName) {
        res.status(400).json({ message: 'Agency name is required' });
        return; 
    }
    try {
        const agencyId: number = await agencyService.turnAgencyNameIntoId(agencyName);
        res.status(200).json({ agency_id: agencyId });
    } catch (error: unknown) {
        console.error('Controller error during agency ID retrieval:', error);
        if (error instanceof ServiceErorr) {
            res.status(error.statusCode).json({ message: error.message });
        } else {
            res.status(500).json({ message: 'Internal server error' });
        }
    }
}