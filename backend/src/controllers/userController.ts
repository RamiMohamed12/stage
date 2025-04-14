import { Request, Response, NextFunction} from "express";
import pool from "../config/db";
import { ResultSetHeader, RowDataPacket } from 'mysql2';
import { Users } from '../models/Users'; 

export const createUser = async (req: Request, res: Response, next: NextFunction) => {

    const {email, password_hash, first_name,last_name} = req.body;

    if (!email || !password_hash || !first_name || !last_name) {
        return res.status(400).json({ message: "All fields are required" });
    }

    
    

}