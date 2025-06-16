import express from 'express';
import * as adminController from '../controllers/adminController';
import { authenticateToken, checkRole } from '../middleware/authMiddleware';
import { Role } from '../models/Users'; // Import the Role enum

const router = express.Router();

router.use(authenticateToken);

router.patch(
    '/documents/:declarationDocumentId/review',
    checkRole([Role.ADMIN]), 
    adminController.handleReviewDocument
);

router.patch(
    '/declarations/:declarationId/approve',
    checkRole([Role.ADMIN]), 
    adminController.handleApproveDeclaration
);

router.patch(
    '/declarations/:declarationId/reject',
    checkRole([Role.ADMIN]), 
    adminController.handleRejectDeclaration
);

export default router;