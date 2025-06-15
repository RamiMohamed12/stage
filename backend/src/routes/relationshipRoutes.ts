import express from 'express';
import { handleGetAllRelationship, handleGetRequiredDocumentsForRelationship } from '../controllers/relationshipController';
import { handleValidationErrors } from '../middleware/validationMiddleware';
import { authenticateToken } from '../middleware/authMiddleware'; // Import the authentication middleware
const router = express.Router();

router.get(
    '/',
    authenticateToken, 
    handleValidationErrors,
    handleGetAllRelationship    
);

router.get(
    '/:relationshipId/required-documents',
    authenticateToken,
    handleValidationErrors,
    handleGetRequiredDocumentsForRelationship
);

export default router;
