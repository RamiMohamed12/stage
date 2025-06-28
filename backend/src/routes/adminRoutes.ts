import express from 'express';
import * as adminController from '../controllers/adminController';
import { authenticateToken, checkRole } from '../middleware/authMiddleware';
import { Role } from '../models/Users'; // Import the Role enum

const router = express.Router();

// This middleware applies to all routes defined in this file
router.use(authenticateToken);

// --- Routes for Admin Dashboard and Declaration Management ---
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

// --- Routes for Bulk/Advanced Approval Actions ---
router.post(
    '/declarations/approve-all',
    checkRole([Role.ADMIN]),
    adminController.handleApproveAllDeclarations
);

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


router.get(
    '/pension-groups',
    checkRole([Role.ADMIN]),
    adminController.getApprovedDeclarationGroups
);

router.post(
    '/pension-groups/calculate',
    checkRole([Role.ADMIN]),
    adminController.handlePensionCalculation
);


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