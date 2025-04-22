import express, { Express, Request, Response } from 'express';
import cors from 'cors';
import pool from './config/db'; // Assuming db config is here
import dotenv from 'dotenv';
import decujusRoutes from './routes/decujusRoutes';
import agencyRoutes from './routes/agencyRoutes'; 
import relationshipRoutes from './routes/relationshipRoutes'; // Import relationship routes
// Import user routes
import userRoutes from './routes/userRoutes'; // Adjust path if needed
import deathCauseRoutes from './routes/deathCauseRoutes'; // Import death cause routes

dotenv.config();

const app: Express = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors()); // Enable Cross-Origin Resource Sharing
app.use(express.json()); // Parse incoming JSON requests
app.use(express.urlencoded({ extended: true })); // Parse URL-encoded requests

// --- Mount API Routes ---
// All routes defined in userRoutes will be prefixed with /api/users
app.use('/api/death-causes', deathCauseRoutes); // Adjust path if needed
app.use('/api/users', userRoutes);
app.use('/api/decujus', decujusRoutes);
app.use('/api/agencies', agencyRoutes);
app.use('/api/relationship', relationshipRoutes); 
// Test route (optional, can be removed or kept for basic checks)
app.get('/', async (req: Request, res: Response) => {
  try {
    // Optional: Simple DB check
    // const [rows] = await pool.query('SELECT 1 as test');
    res.json({ message: 'API is running' }); // Simplified response
  } catch (error) {
    console.error("Root route error:", error); // Log the error
    res.status(500).json({ error: 'API is running, but encountered an issue.' });
  }
});

// Basic Error Handling Middleware (Optional but Recommended)
// This should come after your routes
app.use((err: any, req: Request, res: Response, next: express.NextFunction) => {
  console.error("Unhandled Error:", err.stack || err);
  res.status(err.status || 500).json({
    message: err.message || 'Internal Server Error',
    // Optionally include stack trace in development
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});


// Start server
app.listen(port, () => {
  console.log(`Database connection established successfully.`);
  console.log(`\n`); 
  console.log(`Server is running on port ${port}`);
  console.log(`\n`); 
  console.log(`User routes available at http://localhost:${port}/api/users`);
  console.log(`Decujus routes available at http://localhost:${port}/api/decujus`);
  console.log(`Agencies routes available at http://localhost:${port}/api/agencies`);
  console.log(`Relationship routes available at http://localhost:${port}/api/relationship`);
  console.log(`Death causes routes available at http://localhost:${port}/api/death-causes`); 
});

export default app; // Export app for potential testing frameworks
