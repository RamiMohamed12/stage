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

export const authenticateToken = (req: Request, res: Response, next: NextFunction) => {

    const headerAuth = req.headers['authorization'];
    try {
        if( headerAuth && headerAuth.startsWith('Bearer ')) { 
            const token = headerAuth.slice(7); 
            const  payload =  verifyToken(token); 
            if(payload){
                req.user = payload; // Attach the user to the request object
                next(); 
            }
            else {
                return res.status(401).json({ message: 'Unauthorized: Invalid or expired Token.' });
            } 
    } else { 
        return res.status(401).json({ message: 'Unauthorized: Missing or invalid token format.' });
    }
  } catch (error){
        console.error('Error in authentication middleware:', error);
        return res.status(500).json({ message: 'Internal Server Error.' });
    }

}

export const checkRole = (allowedRoles: Role[]) => {
    return (req: Request, res: Response, next: NextFunction) => {
        try {
            // First check if user exists (should exist after authenticateToken)
            if (!req.user) {
                return res.status(401).json({ 
                    message: 'Unauthorized: Authentication required'
                });
            }

            // Check if user's role is in the allowed roles array
            if (!allowedRoles.includes(req.user.role)) {
                return res.status(403).json({ 
                    message: 'Forbidden: Insufficient permissions'
                });
            }

            // User has an allowed role
            next();
        } catch (error) {
            console.error('Error in role authorization middleware:', error);
            return res.status(500).json({ 
                message: 'Internal Server Error' 
            });
        }
    };
};