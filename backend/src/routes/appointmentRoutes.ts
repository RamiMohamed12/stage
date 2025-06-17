import express from 'express';
import * as appointmentController from '../controllers/appointmentController';
import { authenticateToken, checkRole } from '../middleware/authMiddleware';
import { Role } from '../models/Users';

const router = express.Router();

// All routes require authentication
router.use(authenticateToken);

// User routes
router.get('/user', appointmentController.getUserAppointments);
router.get('/:appointmentId', appointmentController.getAppointmentById);

// Admin routes
router.post('/', checkRole([Role.ADMIN]), appointmentController.createAppointment);
router.get('/', checkRole([Role.ADMIN]), appointmentController.getAllAppointments);
router.put('/:appointmentId', checkRole([Role.ADMIN]), appointmentController.updateAppointment);
router.delete('/:appointmentId', checkRole([Role.ADMIN]), appointmentController.deleteAppointment);

export default router;