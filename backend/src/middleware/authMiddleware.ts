import {Request, Response, NextFunction} from 'express';
import { verifyToken } from '../utils/jwtUtils';
import {JwtPayload} from '../utils/jwtUtils';
import {Role} from '../models/Users'; 

declare global {
    namespace Express {
      interface Request {
        user?: JwtPayload; // Add the user property
      }
    }
}


export const authenticateToken = (req: Request, res: Response, next: NextFunction): void => { // Add :void return type

    const headerAuth = req.headers['authorization'];
    try {
        if( headerAuth && headerAuth.startsWith('Bearer ')) {
            const token = headerAuth.slice(7);
            const payload = verifyToken(token);
            if(payload){
                req.user = payload; // Attach the user payload to the request object
                next();
                return; // Return after calling next()
            }
            else {
                res.status(401).json({ message: 'Unauthorized: Invalid or expired Token.' });
                return; // Add return;
            }
    } else {
        res.status(401).json({ message: 'Unauthorized: Missing or invalid token format.' });
        return; // Add return;
    }
  } catch (error){
        console.error('Error in authentication middleware:', error);
        res.status(500).json({ message: 'Internal Server Error.' });
        return; // Add return;
    }
}

export const checkRole = (allowedRoles: Role[]) => {
    return (req: Request, res: Response, next: NextFunction): void => {
        try {
            // First check if user exists (should exist after authenticateToken)
            if (!req.user) {
                // This return ends the function execution for this path
                res.status(401).json({
                    message: 'Unauthorized: Authentication required'
                });
                return; // Explicitly return after sending response
            }

            // Check if user's role is in the allowed roles array
            if (!allowedRoles.includes(req.user.role)) {
                 // This return ends the function execution for this path
                res.status(403).json({
                    message: 'Forbidden: Insufficient permissions'
                });
                return; // Explicitly return after sending response
            }

            // User has an allowed role, pass control to the next middleware/handler
            next();
            // Implicit void return here is correct

        } catch (error) {
            console.error('Error in role authorization middleware:', error);
            res.status(500).json({
                message: 'Internal Server Error'
            });
            return; 
        }
   
    };
};