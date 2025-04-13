import express, { Express, Request, Response } from 'express';
import cors from 'cors';
import pool from './config/db';
import dotenv from 'dotenv';
dotenv.config();

const app: Express = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Test route
app.get('/', async (req: Request, res: Response) => {
  try {
    const [rows] = await pool.query('SELECT 1 as test');
    res.json({ message: 'Server is running', dbTest: rows });
  } catch (error) {
    res.status(500).json({ error: 'Database connection failed' });
  }
});

// Start server
app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});

export default app;