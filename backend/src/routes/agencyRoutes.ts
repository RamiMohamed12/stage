import express from 'express';
import { handleGetAllAgencies } from '../controllers/agencyController';
import { handleValidationErrors } from '../middleware/validationMiddleware';
import { authenticateToken } from '../middleware/authMiddleware'; // Import the authentication middleware
const router = express.Router();

router.get(
    '/',
    authenticateToken, // Added authentication middleware
    handleValidationErrors,
    handleGetAllAgencies
);

export default router;