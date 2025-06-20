import { Request, Response, NextFunction } from "express";
import * as decujusService from '../services/decujusService';
import { ServiceErorr } from '../services/usersService'; // Assuming ServiceError is defined here or imported correctly

export const handleVerifyDecujus = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const { pension_number, first_name, last_name, date_of_birth, agency_id } = req.body;

        if (!pension_number) {
            res.status(400).json({ isValid: false, message: 'Pension number is required.' });
            return;
        }

        const verificationData = {
            pension_number,
            first_name: first_name || null,
            last_name: last_name || null,
            date_of_birth: date_of_birth ? new Date(date_of_birth) : null,
            agency_id: agency_id ? parseInt(String(agency_id),10)  : null 
        };

        if (agency_id && isNaN(verificationData.agency_id as number)) {
            res.status(400).json({ isValid: false, message: 'Agency ID must be a number.' });
            return;
        }
        
        const result = await decujusService.verifyDecujus(verificationData);

        if (result.isValid) {
            res.status(200).json(result);
        } else {
          
            const statusCode = result.message?.includes('not found') ? 404 : 400;
            res.status(statusCode).json(result);
        }

    } catch (error) {
        console.error('Controller error during decujus verification:', error);

        next(error); 
    }
};

export const handleVerifyDecujusByPensionNumber = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const { pension_number } = req.params;

        if (!pension_number) {
            res.status(400).json({ message: 'Pension number is required.' });
            return;
        }

        const decujus = await decujusService.verifyDecujusByPensionNumber(pension_number);

        if (!decujus) {
            res.status(404).json({ message: 'Decujus not found.' });
            return;
        }

        res.status(200).json(decujus);
    } catch (error) {
        console.error('Controller error during decujus retrieval:', error);
        
        next(error); 
    }
}

export const handleGetDecujusByPensionAndAgency = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const { pension_number, agency_id } = req.params;

        if (!pension_number) {
            res.status(400).json({ message: 'Pension number is required.' });
            return;
        }
        if (!agency_id) {
            res.status(400).json({ message: 'Agency ID is required.' });
            return;
        }

        const agencyIdNumber = parseInt(agency_id, 10);
        if (isNaN(agencyIdNumber)) {
            res.status(400).json({ message: 'Agency ID must be a number.' });
            return;
        }

        const decujus = await decujusService.getDecujusByPensionNumberAndAgencyId(pension_number, agencyIdNumber);

        if (!decujus) {
            res.status(404).json({ message: 'Decujus not found for the given pension number and agency ID.' });
            return;
        }

        res.status(200).json(decujus);
    } catch (error) {
        console.error('Controller error during decujus retrieval by pension and agency:', error);
        next(error);
    }
};
