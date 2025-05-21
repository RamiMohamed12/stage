import express, { Express, Request, Response, NextFunction } from 'express'; // Added NextFunction
import cors from 'cors';
import pool from './config/db'; // Assuming db config is here
import dotenv from 'dotenv';
import decujusRoutes from './routes/decujusRoutes';
import agencyRoutes from './routes/agencyRoutes';
import relationshipRoutes from './routes/relationshipRoutes'; // Import relationship routes
import userRoutes from './routes/userRoutes'; // Adjust path if needed
import deathCauseRoutes from './routes/deathCauseRoutes'; // Import death cause routes
import declarationRoutes from './routes/declarationRoutes'; // Import declaration routes
import adminRoutes from './routes/adminRoutes'; // Import admin routes

dotenv.config();

const app: Express = express();
const port = process.env.PORT ? Number(process.env.PORT): 3000;

// Middleware
app.use(cors()); // Enable Cross-Origin Resource Sharing
app.use(express.json()); // Parse incoming JSON requests
app.use(express.urlencoded({ extended: true })); // Parse URL-encoded requests

// --- Mount API Routes ---
app.use('/api/users', userRoutes);
app.use('/api/decujus', decujusRoutes);
app.use('/api/agencies', agencyRoutes);
app.use('/api/relationship', relationshipRoutes);
app.use('/api/death-causes', deathCauseRoutes);
app.use('/api/declarations', declarationRoutes); // Add declaration routes
app.use('/api/admin', adminRoutes); // Add admin routes

// Test route (optional, can be removed or kept for basic checks)
app.get('/', async (req: Request, res: Response) => {
  try {
    res.json({ message: 'API is running' });
  } catch (error) {
    console.error("Root route error:", error);
    res.status(500).json({ error: 'API is running, but encountered an issue.' });
  }
});

// Basic Error Handling Middleware
// This should come after your routes
app.use((err: any, req: Request, res: Response, next: NextFunction) => { // Ensure NextFunction is imported from express
  console.error("Unhandled Error:", err.stack || err);
  res.status(err.status || err.statusCode || 500).json({ // Added err.statusCode
    message: err.message || 'Internal Server Error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});


// Start server
app.listen(port,'0.0.0.0', () => {
  // console.log(`Database connection established successfully.`); // Removed as DB connection is implicit
  console.log(`\n`);
  console.log(`Server is running on port ${port}`);
  console.log(`\n`);
  console.log(`User routes available at http://localhost:${port}/api/users`);
  console.log(`Decujus routes available at http://localhost:${port}/api/decujus`);
  console.log(`Agencies routes available at http://localhost:${port}/api/agencies`);
  console.log(`Relationship routes available at http://localhost:${port}/api/relationship`);
  console.log(`Death causes routes available at http://localhost:${port}/api/death-causes`);
  console.log(`Declaration routes available at http://localhost:${port}/api/declarations`); // Added log
  console.log(`Admin routes available at http://localhost:${port}/api/admin`); // Added log
});

export default app; // Export app for potential testing frameworks
//this is just a test