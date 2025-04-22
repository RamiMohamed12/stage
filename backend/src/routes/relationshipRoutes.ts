import express from 'express';
import { handleGetAllRelationship } from '../controllers/relationshipController';
import { handleValidationErrors } from '../middleware/validationMiddleware';
import { authenticateToken } from '../middleware/authMiddleware'; // Import the authentication middleware
const router = express.Router();

router.get(
    '/',
    authenticateToken, 
    handleValidationErrors,
    handleGetAllRelationship    
);

export default router;
