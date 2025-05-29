import express from 'express';
import { handleVerifyDecujusByPensionNumber, handleVerifyDecujus } from '../controllers/decujusController';
import { authenticateToken } from '../middleware/authMiddleware';
import { validateDecujusVerificationInput } from '../middleware/validators/decujusValidators';
import { handleValidationErrors } from '../middleware/validationMiddleware';

const router = express.Router();

// Route for verifying decujus information (POST)
router.post(
    '/verify',
    authenticateToken,
    validateDecujusVerificationInput,
    handleValidationErrors,
    handleVerifyDecujus // This should be handleVerifyDecujus for the POST /verify route
);

// Route for fetching a decujus by pension number (GET)
router.get(
    '/:pension_number', 
    authenticateToken,
    handleVerifyDecujusByPensionNumber
);

export default router;