import 'multer';
// Removed incorrect import as 'File' is not exported by 'multer'
import {Role} from '../models/Users';

interface AuthenticatedUser { 
    userId: number; 
    role: Role; 
    iat?: number; 
    exp?:number; 
}

declare global { 
    namespace Express { 
        export interface Request { 
            file?: Express.Multer.File; 
            files?: Express.Multer.File[] | { [fieldname: string]: Express.Multer.File[] };
            user?: AuthenticatedUser; // Add the user property
        }
    }
}

export {}; 