import express from 'express';
import * as adminController from '../controllers/adminController';
import { authenticateToken, checkRole } from '../middleware/authMiddleware';
import { Role } from '../models/Users'; // Import the Role enum

// Optional: Import validators if you create them for request bodies
// import { validateReviewDocumentInput, validateRejectDeclarationInput } from '../middleware/validators/adminValidators'; // You would create these if needed

const router = express.Router();

// Apply authentication to all routes in this file
router.use(authenticateToken);

// Route to review a specific document
// PATCH /api/v1/admin/documents/:declarationDocumentId/review
router.patch(
    '/documents/:declarationDocumentId/review',
    checkRole([Role.ADMIN]), // Ensure only admins can access
    // validateReviewDocumentInput, // Optional: if you have body validation
    adminController.handleReviewDocument
);

// Route to approve a declaration
// PATCH /api/v1/admin/declarations/:declarationId/approve
router.patch(
    '/declarations/:declarationId/approve',
    checkRole([Role.ADMIN]), // Ensure only admins can access
    adminController.handleApproveDeclaration
);

// Route to reject a declaration
// PATCH /api/v1/admin/declarations/:declarationId/reject
router.patch(
    '/declarations/:declarationId/reject',
    checkRole([Role.ADMIN]), // Ensure only admins can access
    // validateRejectDeclarationInput, // Optional: if you have body validation for rejectionReason
    adminController.handleRejectDeclaration
);

export default router;