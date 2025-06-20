import express from 'express';
import * as notificationController from '../controllers/notificationController';
import { authenticateToken, checkRole } from '../middleware/authMiddleware';
import { Role } from '../models/Users';

const router = express.Router();

// All routes require authentication
router.use(authenticateToken);

// User notification routes
router.get(
    '/',
    notificationController.getUserNotifications
);

router.get(
    '/stats',
    notificationController.getUserNotificationStats
);

router.patch(
    '/:notificationId/read',
    notificationController.markNotificationAsRead
);

router.patch(
    '/mark-all-read',
    notificationController.markAllNotificationsAsRead
);

router.delete(
    '/:notificationId',
    notificationController.deleteNotification
);

// Admin-only routes
router.post(
    '/send',
    checkRole([Role.ADMIN]),
    notificationController.sendNotificationToUser
);

router.post(
    '/send-rejection',
    checkRole([Role.ADMIN]),
    notificationController.sendRejectionNotification
);

router.patch(
    '/:notificationId/acknowledge',
    notificationController.acknowledgeRejection
);

router.get(
    '/admin/all',
    checkRole([Role.ADMIN]),
    notificationController.getAllNotifications
);

export default router;