import express from 'express';
import * as agencyController from '../controllers/agencyController';
import { handleValidationErrors } from '../middleware/validationMiddleware';
import { authenticateToken } from '../middleware/authMiddleware'; // Import the authentication middleware
const router = express.Router();

router.get(
    '/',
    authenticateToken,
    handleValidationErrors,
    agencyController.handleGetAllAgencies
);

router.get( 
    '/:agencyId',
    authenticateToken,
    handleValidationErrors,
    agencyController.handleGetAgencyNameById
)

router.get(
    '/name/:agencyName',
    authenticateToken,
    handleValidationErrors,
    agencyController.handleGetAgencyIdbyName
); 

export default router;
