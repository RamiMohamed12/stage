import express from 'express';
import * as appointmentController from '../controllers/appointmentController';
import { authenticateToken, checkRole } from '../middleware/authMiddleware';
import { Role } from '../models/Users';

const router = express.Router();

// All routes require authentication
router.use(authenticateToken);

// User routes
router.get('/user', appointmentController.getUserAppointments);
router.get('/declaration/:declarationId', appointmentController.getAppointmentByDeclarationId);
router.get('/:appointmentId', appointmentController.getAppointmentById);
router.patch('/:appointmentId/status', appointmentController.updateAppointmentStatus);

// Admin routes
router.post('/', checkRole([Role.ADMIN]), appointmentController.createAppointment);
router.get('/', checkRole([Role.ADMIN]), appointmentController.getAllAppointments);
router.put('/:appointmentId', checkRole([Role.ADMIN]), appointmentController.updateAppointment);
router.patch('/:appointmentId/reject', checkRole([Role.ADMIN]), appointmentController.rejectAppointment);
router.delete('/:appointmentId', checkRole([Role.ADMIN]), appointmentController.deleteAppointment);

export default router;