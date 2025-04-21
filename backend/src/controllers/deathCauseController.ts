import {Request, Response, NextFunction} from "express";
import * as deathCauseService from '../services/deathCauseService';
import {ServiceErorr} from '../services/usersService'; 
import {DeathCause} from '../models/DeathCause'; 

export const handleGetAllDeathCauses = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const deathCauses: DeathCause[] = await deathCauseService.getAllDeathCauses();
        res.status(200).json(deathCauses);
    } catch (error: unknown) {
        console.error('Controller error during death cause retrieval:', error);
        if (error instanceof ServiceErorr) {
            res.status(error.statusCode).json({ message: error.message });
        } else {
            res.status(500).json({ message: 'Internal server error' });
        }
    }
}

