import { validationResult } from "express-validator";
import { Request, Response, NextFunction } from "express";

export const handleValidationErrors = (req: Request, res: Response, next: NextFunction) => {
    try {
    const errors = validationResult(req);
    if (errors.isEmpty()) {
        return next(); // No validation errors, proceed to the next middleware
        }   else { 
            return res.status(400).json({errors: errors.array()}); // Return validation errors as JSON response
        }
    } catch (error){    
        throw new Error('Internal Server Error: An error occurred while processing the request.');
    }
}