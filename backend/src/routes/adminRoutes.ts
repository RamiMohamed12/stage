import express from 'express';
import * as adminController from '../controllers/adminController';
import { authenticateToken, checkRole } from '../middleware/authMiddleware';
import { Role } from '../models/Users'; // Import the Role enum

const router = express.Router();

router.use(authenticateToken);

// New routes for admin dashboard
router.get(
    '/declarations',
    checkRole([Role.ADMIN]),
    adminController.getAllDeclarationsForAdmin
);

router.get(
    '/declarations/:declarationId',
    checkRole([Role.ADMIN]),
    adminController.getDeclarationDetails
);

// New route for bulk approval
router.post(
    '/declarations/approve-all',
    checkRole([Role.ADMIN]),
    adminController.handleApproveAllDeclarations
);

// New routes for appointment-based approvals
router.post(
    '/declarations/:declarationId/approve-with-appointment',
    checkRole([Role.ADMIN]),
    adminController.handleApproveDeclarationWithAppointment
);

router.post(
    '/declarations/approve-all-with-appointments',
    checkRole([Role.ADMIN]),
    adminController.handleApproveAllDeclarationsWithAppointments
);

// Existing routes
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