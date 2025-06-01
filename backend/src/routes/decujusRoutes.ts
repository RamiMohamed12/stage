import express from 'express';
import { handleVerifyDecujusByPensionNumber, handleVerifyDecujus, handleGetDecujusByPensionAndAgency } from '../controllers/decujusController';
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

// Route for fetching a decujus by pension number and agency ID (GET)
router.get(
    '/pension/:pension_number/agency/:agency_id',
    authenticateToken,
    handleGetDecujusByPensionAndAgency
);

export default router;