import express from 'express';
import { handleVerifyDecujus } from '../controllers/decujusController';
import { authenticateToken } from '../middleware/authMiddleware';

import { handleValidationErrors } from '../middleware/validationMiddleware'; 

const router = express.Router();


router.post(
    '/verify',
    authenticateToken,
    handleValidationErrors, 
    handleVerifyDecujus
);


export default router;