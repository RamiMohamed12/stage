import express from 'express';
import { handleGetAllDeathCauses } from '../controllers/deathCauseController';
import { handleValidationErrors } from '../middleware/validationMiddleware';
import { authenticateToken } from '../middleware/authMiddleware'; // Import the authentication middleware

const router = express.Router();

router.get(
    '/',
    authenticateToken, 
    handleValidationErrors,
    handleGetAllDeathCauses
);

export default router;

