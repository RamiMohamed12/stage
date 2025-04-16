import { validationResult } from "express-validator";
import { Request, Response, NextFunction } from "express";

export const handleValidationErrors = (req: Request, res: Response, next: NextFunction): void => { // Add :void return type
    try {
     const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({errors: errors.array()});
      return; 
    }
    next();
    return; 
      } catch (error) {
          console.error('Error in validation middleware:', error);
          res.status(500).json({ message: 'Internal Server Error' });
          return; 
      }
};