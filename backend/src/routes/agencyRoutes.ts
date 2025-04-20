import express from 'express';
import { handleGetAllAgencies } from '../controllers/agencyController';
import { handleValidationErrors } from '../middleware/validationMiddleware';

const router = express.Router();

router.get(
    '/',
    handleValidationErrors,
    handleGetAllAgencies
);

export default router;