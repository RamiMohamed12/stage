import { Request, Response, NextFunction} from "express";
import pool from "../config/db";
import { ResultSetHeader, RowDataPacket } from 'mysql2';
import { Users } from '../models/Users'; 

