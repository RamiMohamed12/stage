export interface Notification {
    notification_id: number;
    user_id: number;
    title: string;
    body: string;
    type: 'document_review' | 'declaration_approved' | 'declaration_rejected' | 'general';
    related_id: number | null; // Can reference declaration_id or document_id
    is_read: boolean;
    sent_at: Date;
    read_at: Date | null;
    created_by_admin_id: number | null;
    created_at: Date;
}

export interface CreateNotificationInput {
    user_id: number;
    title: string;
    body: string;
    type?: 'document_review' | 'declaration_approved' | 'declaration_rejected' | 'general';
    related_id?: number | null;
    created_by_admin_id?: number | null;
}

export interface UpdateNotificationInput {
    is_read?: boolean;
    read_at?: Date | null;
}

export interface NotificationStats {
    total: number;
    unread: number;
    read: number;
}