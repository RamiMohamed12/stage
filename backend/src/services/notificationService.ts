import pool from '../config/db';
import { RowDataPacket, ResultSetHeader } from 'mysql2';
import { PoolConnection } from 'mysql2/promise';
import { ServiceErorr } from './usersService';
import { Notification, CreateNotificationInput, UpdateNotificationInput, NotificationStats } from '../models/Notification';

// Create a new notification
export const createNotification = async (notificationData: CreateNotificationInput): Promise<Notification> => {
    const { user_id, title, body, type = 'general', related_id, created_by_admin_id } = notificationData;
    let connection: PoolConnection | undefined;

    try {
        connection = await pool.getConnection();
        
        const insertSql = `
            INSERT INTO notifications (user_id, title, body, type, related_id, created_by_admin_id) 
            VALUES (?, ?, ?, ?, ?, ?)
        `;
        const values = [user_id, title, body, type, related_id, created_by_admin_id];

        const [result] = await connection.execute<ResultSetHeader>(insertSql, values);

        if (result.affectedRows === 0) {
            throw new ServiceErorr('Failed to create notification.', 500);
        }

        // Fetch the newly created notification
        const [newNotificationRows] = await connection.execute<RowDataPacket[]>(
            `SELECT notification_id, user_id, title, body, type, related_id, is_read, 
                    sent_at, read_at, created_by_admin_id, created_at 
             FROM notifications WHERE notification_id = ?`,
            [result.insertId]
        );

        if (newNotificationRows.length === 0) {
            throw new ServiceErorr('Failed to retrieve newly created notification.', 500);
        }

        console.log(`Notification created for user ${user_id}: ${title}`);
        return newNotificationRows[0] as Notification;

    } catch (error: any) {
        console.error('Error creating notification:', error);
        if (error instanceof ServiceErorr) {
            throw error;
        }
        throw new ServiceErorr('An internal error occurred while creating the notification.', 500);
    } finally {
        if (connection) {
            connection.release();
        }
    }
};

// Get notifications for a specific user
export const getUserNotifications = async (
    userId: number, 
    limit: number = 50, 
    offset: number = 0,
    unreadOnly: boolean = false
): Promise<{ notifications: Notification[]; total: number }> => {
    let connection: PoolConnection | undefined;

    try {
        connection = await pool.getConnection();
        
        let whereClause = 'WHERE user_id = ?';
        let countWhereClause = 'WHERE user_id = ?';
        const queryParams = [userId];
        
        if (unreadOnly) {
            whereClause += ' AND is_read = FALSE';
            countWhereClause += ' AND is_read = FALSE';
        }

        // Get total count
        const [countRows] = await connection.execute<RowDataPacket[]>(
            `SELECT COUNT(*) as total FROM notifications ${countWhereClause}`,
            queryParams
        );
        const total = countRows[0].total;

        // Get notifications
        const [notificationRows] = await connection.execute<RowDataPacket[]>(
            `SELECT notification_id, user_id, title, body, type, related_id, is_read, 
                    sent_at, read_at, created_by_admin_id, created_at 
             FROM notifications 
             ${whereClause}
             ORDER BY sent_at DESC 
             LIMIT ? OFFSET ?`,
            [...queryParams, limit, offset]
        );

        return {
            notifications: notificationRows as Notification[],
            total
        };

    } catch (error: any) {
        console.error('Error fetching user notifications:', error);
        throw new ServiceErorr('Failed to fetch notifications.', 500);
    } finally {
        if (connection) {
            connection.release();
        }
    }
};

// Mark notification as read
export const markNotificationAsRead = async (notificationId: number, userId: number): Promise<void> => {
    let connection: PoolConnection | undefined;

    try {
        connection = await pool.getConnection();
        
        const [result] = await connection.execute<ResultSetHeader>(
            'UPDATE notifications SET is_read = TRUE, read_at = NOW() WHERE notification_id = ? AND user_id = ?',
            [notificationId, userId]
        );

        if (result.affectedRows === 0) {
            throw new ServiceErorr('Notification not found or unauthorized.', 404);
        }

    } catch (error: any) {
        console.error('Error marking notification as read:', error);
        if (error instanceof ServiceErorr) {
            throw error;
        }
        throw new ServiceErorr('Failed to mark notification as read.', 500);
    } finally {
        if (connection) {
            connection.release();
        }
    }
};

// Mark all notifications as read for a user
export const markAllNotificationsAsRead = async (userId: number): Promise<void> => {
    let connection: PoolConnection | undefined;

    try {
        connection = await pool.getConnection();
        
        await connection.execute(
            'UPDATE notifications SET is_read = TRUE, read_at = NOW() WHERE user_id = ? AND is_read = FALSE',
            [userId]
        );

    } catch (error: any) {
        console.error('Error marking all notifications as read:', error);
        throw new ServiceErorr('Failed to mark all notifications as read.', 500);
    } finally {
        if (connection) {
            connection.release();
        }
    }
};

// Get notification statistics for a user
export const getUserNotificationStats = async (userId: number): Promise<NotificationStats> => {
    let connection: PoolConnection | undefined;

    try {
        connection = await pool.getConnection();
        
        const [statsRows] = await connection.execute<RowDataPacket[]>(
            `SELECT 
                COUNT(*) as total,
                SUM(CASE WHEN is_read = FALSE THEN 1 ELSE 0 END) as unread,
                SUM(CASE WHEN is_read = TRUE THEN 1 ELSE 0 END) as read
             FROM notifications 
             WHERE user_id = ?`,
            [userId]
        );

        return {
            total: statsRows[0].total || 0,
            unread: statsRows[0].unread || 0,
            read: statsRows[0].read || 0
        };

    } catch (error: any) {
        console.error('Error fetching notification stats:', error);
        throw new ServiceErorr('Failed to fetch notification statistics.', 500);
    } finally {
        if (connection) {
            connection.release();
        }
    }
};

// Delete a notification
export const deleteNotification = async (notificationId: number, userId: number): Promise<void> => {
    let connection: PoolConnection | undefined;

    try {
        connection = await pool.getConnection();
        
        const [result] = await connection.execute<ResultSetHeader>(
            'DELETE FROM notifications WHERE notification_id = ? AND user_id = ?',
            [notificationId, userId]
        );

        if (result.affectedRows === 0) {
            throw new ServiceErorr('Notification not found or unauthorized.', 404);
        }

    } catch (error: any) {
        console.error('Error deleting notification:', error);
        if (error instanceof ServiceErorr) {
            throw error;
        }
        throw new ServiceErorr('Failed to delete notification.', 500);
    } finally {
        if (connection) {
            connection.release();
        }
    }
};

// Admin: Send notification to specific user
export const sendNotificationToUser = async (
    targetUserId: number, 
    title: string, 
    body: string, 
    adminId: number,
    type: 'document_review' | 'declaration_approved' | 'declaration_rejected' | 'appointment' | 'general' = 'general',
    relatedId?: number
): Promise<Notification> => {
    return await createNotification({
        user_id: targetUserId,
        title,
        body,
        type,
        related_id: relatedId || null,
        created_by_admin_id: adminId
    });
};

// Admin: Get all notifications (for admin dashboard)
export const getAllNotifications = async (
    limit: number = 100, 
    offset: number = 0
): Promise<{ notifications: Notification[]; total: number }> => {
    let connection: PoolConnection | undefined;

    try {
        connection = await pool.getConnection();
        
        // Get total count
        const [countRows] = await connection.execute<RowDataPacket[]>(
            'SELECT COUNT(*) as total FROM notifications'
        );
        const total = countRows[0].total;

        // Get notifications with user info
        const [notificationRows] = await connection.execute<RowDataPacket[]>(
            `SELECT n.notification_id, n.user_id, n.title, n.body, n.type, n.related_id, 
                    n.is_read, n.sent_at, n.read_at, n.created_by_admin_id, n.created_at,
                    u.email as user_email, u.first_name, u.last_name,
                    admin.email as admin_email
             FROM notifications n
             JOIN users u ON n.user_id = u.user_id
             LEFT JOIN users admin ON n.created_by_admin_id = admin.user_id
             ORDER BY n.sent_at DESC 
             LIMIT ? OFFSET ?`,
            [limit, offset]
        );

        return {
            notifications: notificationRows as Notification[],
            total
        };

    } catch (error: any) {
        console.error('Error fetching all notifications:', error);
        throw new ServiceErorr('Failed to fetch all notifications.', 500);
    } finally {
        if (connection) {
            connection.release();
        }
    }
};

// Helper function to send automatic notifications when documents are reviewed
export const sendDocumentReviewNotification = async (
    userId: number,
    documentType: string,
    status: 'approved' | 'rejected',
    adminId: number,
    declarationId?: number
): Promise<void> => {
    const title = status === 'approved' 
        ? `Document Approuvé: ${documentType}`
        : `Document Rejeté: ${documentType}`;
    
    const body = status === 'approved'
        ? `Votre ${documentType} a été examiné et approuvé par notre équipe administrative.`
        : `Votre ${documentType} a été examiné et nécessite une attention. Veuillez vérifier votre déclaration pour plus de détails.`;

    try {
        await sendNotificationToUser(
            userId,
            title,
            body,
            adminId,
            'document_review',
            declarationId
        );
    } catch (error) {
        console.error('Failed to send document review notification:', error);
    }
};

// Helper function to send automatic notifications when declarations are approved
export const sendDeclarationApprovedNotification = async (
    userId: number,
    adminId: number,
    declarationId: number
): Promise<void> => {
    const title = 'Déclaration Approuvée';
    const body = 'Félicitations! Votre déclaration a été approuvée. Vous pouvez maintenant procéder aux étapes suivantes du processus.';

    try {
        await sendNotificationToUser(
            userId,
            title,
            body,
            adminId,
            'declaration_approved',
            declarationId
        );
    } catch (error) {
        console.error('Failed to send declaration approved notification:', error);
    }
};

// Helper function to send automatic notifications when declarations are rejected
export const sendDeclarationRejectedNotification = async (
    userId: number,
    adminId: number,
    declarationId: number,
    reason?: string
): Promise<void> => {
    const title = 'Déclaration Rejetée';
    const body = reason 
        ? `Votre déclaration a été rejetée. Raison: ${reason}. Veuillez examiner et soumettre à nouveau avec les corrections nécessaires.`
        : 'Votre déclaration a été rejetée. Veuillez examiner les commentaires et soumettre à nouveau avec les corrections nécessaires.';

    try {
        await sendNotificationToUser(
            userId,
            title,
            body,
            adminId,
            'declaration_rejected',
            declarationId
        );
    } catch (error) {
        console.error('Failed to send declaration rejected notification:', error);
    }
};