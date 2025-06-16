import { Request, Response, NextFunction } from "express";
import * as notificationService from '../services/notificationService';
import { ServiceErorr } from '../services/usersService';
import { JwtPayload } from '../utils/jwtUtils';
import { Role } from '../models/Users';

// Get user's notifications
export const getUserNotifications = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const authenticatedUser = req.user as JwtPayload;
        const userId = authenticatedUser.userId;
        
        const limit = parseInt(req.query.limit as string) || 50;
        const offset = parseInt(req.query.offset as string) || 0;
        const unreadOnly = req.query.unread_only === 'true';

        const result = await notificationService.getUserNotifications(userId, limit, offset, unreadOnly);
        
        res.status(200).json({
            notifications: result.notifications,
            total: result.total,
            limit,
            offset
        });

    } catch (error: unknown) {
        if (error instanceof ServiceErorr) {
            res.status(error.statusCode).json({ message: error.message });
        } else if (error instanceof Error) {
            console.error("Get User Notifications Error:", error);
            res.status(500).json({ message: "Failed to fetch notifications.", error: error.message });
        } else {
            console.error("Get User Notifications Error (Unknown):", error);
            res.status(500).json({ message: "An unknown error occurred while fetching notifications." });
        }
    }
};

// Get user's notification statistics
export const getUserNotificationStats = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const authenticatedUser = req.user as JwtPayload;
        const userId = authenticatedUser.userId;

        const stats = await notificationService.getUserNotificationStats(userId);
        res.status(200).json(stats);

    } catch (error: unknown) {
        if (error instanceof ServiceErorr) {
            res.status(error.statusCode).json({ message: error.message });
        } else if (error instanceof Error) {
            console.error("Get Notification Stats Error:", error);
            res.status(500).json({ message: "Failed to fetch notification statistics.", error: error.message });
        } else {
            console.error("Get Notification Stats Error (Unknown):", error);
            res.status(500).json({ message: "An unknown error occurred while fetching notification statistics." });
        }
    }
};

// Mark notification as read
export const markNotificationAsRead = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const authenticatedUser = req.user as JwtPayload;
        const userId = authenticatedUser.userId;
        const notificationId = parseInt(req.params.notificationId);

        if (isNaN(notificationId)) {
            res.status(400).json({ message: 'Invalid notification ID.' });
            return;
        }

        await notificationService.markNotificationAsRead(notificationId, userId);
        res.status(200).json({ message: 'Notification marked as read.' });

    } catch (error: unknown) {
        if (error instanceof ServiceErorr) {
            res.status(error.statusCode).json({ message: error.message });
        } else if (error instanceof Error) {
            console.error("Mark Notification Read Error:", error);
            res.status(500).json({ message: "Failed to mark notification as read.", error: error.message });
        } else {
            console.error("Mark Notification Read Error (Unknown):", error);
            res.status(500).json({ message: "An unknown error occurred while marking notification as read." });
        }
    }
};

// Mark all notifications as read
export const markAllNotificationsAsRead = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const authenticatedUser = req.user as JwtPayload;
        const userId = authenticatedUser.userId;

        await notificationService.markAllNotificationsAsRead(userId);
        res.status(200).json({ message: 'All notifications marked as read.' });

    } catch (error: unknown) {
        if (error instanceof ServiceErorr) {
            res.status(error.statusCode).json({ message: error.message });
        } else if (error instanceof Error) {
            console.error("Mark All Notifications Read Error:", error);
            res.status(500).json({ message: "Failed to mark all notifications as read.", error: error.message });
        } else {
            console.error("Mark All Notifications Read Error (Unknown):", error);
            res.status(500).json({ message: "An unknown error occurred while marking all notifications as read." });
        }
    }
};

// Delete notification
export const deleteNotification = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const authenticatedUser = req.user as JwtPayload;
        const userId = authenticatedUser.userId;
        const notificationId = parseInt(req.params.notificationId);

        if (isNaN(notificationId)) {
            res.status(400).json({ message: 'Invalid notification ID.' });
            return;
        }

        await notificationService.deleteNotification(notificationId, userId);
        res.status(200).json({ message: 'Notification deleted successfully.' });

    } catch (error: unknown) {
        if (error instanceof ServiceErorr) {
            res.status(error.statusCode).json({ message: error.message });
        } else if (error instanceof Error) {
            console.error("Delete Notification Error:", error);
            res.status(500).json({ message: "Failed to delete notification.", error: error.message });
        } else {
            console.error("Delete Notification Error (Unknown):", error);
            res.status(500).json({ message: "An unknown error occurred while deleting notification." });
        }
    }
};

// ADMIN ONLY: Send notification to specific user
export const sendNotificationToUser = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const authenticatedUser = req.user as JwtPayload;
        const adminId = authenticatedUser.userId;
        
        const { user_id, title, body, type = 'general', related_id } = req.body;

        if (!user_id || !title || !body) {
            res.status(400).json({ message: 'user_id, title, and body are required.' });
            return;
        }

        const notification = await notificationService.sendNotificationToUser(
            user_id,
            title,
            body,
            adminId,
            type,
            related_id
        );

        res.status(201).json({
            message: 'Notification sent successfully.',
            notification
        });

    } catch (error: unknown) {
        if (error instanceof ServiceErorr) {
            res.status(error.statusCode).json({ message: error.message });
        } else if (error instanceof Error) {
            console.error("Send Notification Error:", error);
            res.status(500).json({ message: "Failed to send notification.", error: error.message });
        } else {
            console.error("Send Notification Error (Unknown):", error);
            res.status(500).json({ message: "An unknown error occurred while sending notification." });
        }
    }
};

// ADMIN ONLY: Get all notifications
export const getAllNotifications = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const limit = parseInt(req.query.limit as string) || 100;
        const offset = parseInt(req.query.offset as string) || 0;

        const result = await notificationService.getAllNotifications(limit, offset);
        
        res.status(200).json({
            notifications: result.notifications,
            total: result.total,
            limit,
            offset
        });

    } catch (error: unknown) {
        if (error instanceof ServiceErorr) {
            res.status(error.statusCode).json({ message: error.message });
        } else if (error instanceof Error) {
            console.error("Get All Notifications Error:", error);
            res.status(500).json({ message: "Failed to fetch all notifications.", error: error.message });
        } else {
            console.error("Get All Notifications Error (Unknown):", error);
            res.status(500).json({ message: "An unknown error occurred while fetching all notifications." });
        }
    }
};