import * as jwt from 'jsonwebtoken';
import dotenv from 'dotenv';
import { Role } from '../models/Users';

dotenv.config();

const secret = process.env.JWT_SECRET;
const expiresIn = process.env.JWT_EXPIRES_IN;

if (!secret) {
    throw new Error('FATAL ERROR: JWT_SECRET is not defined in environment variables');
}

export interface JwtPayload {
    userId: number;
    role: Role;
    iat?: number;
    exp?: number;
}

export const generateToken = (userId: number, userRole: Role): string => {
    const payload: Omit<JwtPayload, 'iat' | 'exp'> = {
        userId,
        role: userRole
    };

    try {
        const options: jwt.SignOptions = {};
        if (expiresIn) {
            options.expiresIn = expiresIn as jwt.SignOptions['expiresIn'];
        }

        return jwt.sign(payload, secret, options);
    } catch (error) {
        console.error('Error signing JWT:', error);
        throw new Error('Failed to generate authentication token');
    }
};

export const verifyToken = (token: string): JwtPayload | null => {
    if (!token) return null;

    try {
        const decoded = jwt.verify(token, secret);

        if (typeof decoded === 'object' && decoded !== null && 
            'userId' in decoded && 'role' in decoded) {
            return decoded as JwtPayload;
        }
        
        console.error('Invalid token payload structure:', decoded);
        return null;

    } catch (error) {
        if (error instanceof jwt.TokenExpiredError) {
            console.log('Token expired:', error.expiredAt);
        } else if (error instanceof jwt.JsonWebTokenError) {
            console.log('Invalid token:', error.message);
        } else {
            console.error('Token verification error:', error);
        }
        return null;
    }
};