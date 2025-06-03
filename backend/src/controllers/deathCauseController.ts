import {Request, Response, NextFunction} from "express";
import * as deathCauseService from '../services/deathCauseService';
import {ServiceErorr} from '../services/usersService'; 

export const handleGetAllDeathCauses = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const deathCausesData = await deathCauseService.getAllDeathCauses(); // Type of deathCausesData is now any[]
        res.status(200).json(deathCausesData);
    } catch (error: unknown) {
        console.error('Controller error during death cause retrieval:', error);
        if (error instanceof ServiceErorr) {
            res.status(error.statusCode).json({ message: error.message });
        } else {
            res.status(500).json({ message: 'Internal server error' });
        }
    }
}

