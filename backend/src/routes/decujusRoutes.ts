import express from 'express';
import { handleVerifyDecujusByPensionNumber, handleVerifyDecujus } from '../controllers/decujusController';
import { authenticateToken } from '../middleware/authMiddleware';
import { validateDecujusVerificationInput } from '../middleware/validators/decujusValidators'; // Import the validator
import { handleValidationErrors } from '../middleware/validationMiddleware';

const router = express.Router();

// Route for verifying decujus information
// POST /api/decujus/verify
router.post(
    '/verify',
    authenticateToken, // 1. Ensure user is logged in
    validateDecujusVerificationInput, // 2. Validate the input data
    handleValidationErrors, // 3. Handle any validation errors
    handleVerifyDecujusByPensionNumber // 4. Handle the verification logic
);


export default router;