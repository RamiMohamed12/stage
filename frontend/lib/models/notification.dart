class Notification {
  final int notificationId;
  final int userId;
  final String title;
  final String body;
  final String type;
  final int? relatedId;
  final bool isRead;
  final DateTime sentAt;
  final DateTime? readAt;
  final int? createdByAdminId;
  final DateTime createdAt;

  Notification({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    required this.isRead,
    required this.sentAt,
    this.readAt,
    this.createdByAdminId,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      notificationId: json['notification_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? 'general',
      relatedId: json['related_id'],
      isRead: json['is_read'] ?? false,
      sentAt: DateTime.parse(json['sent_at'] ?? DateTime.now().toIso8601String()),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      createdByAdminId: json['created_by_admin_id'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_id': notificationId,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'related_id': relatedId,
      'is_read': isRead,
      'sent_at': sentAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'created_by_admin_id': createdByAdminId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get typeDisplayName {
    switch (type) {
      case 'document_review':
        return 'Révision de document';
      case 'declaration_approved':
        return 'Déclaration approuvée';
      case 'declaration_rejected':
        return 'Déclaration rejetée';
      case 'appointment':
        return 'Rendez-vous planifié';
      case 'general':
      default:
        return 'Général';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(sentAt);

    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }
}

class NotificationStats {
  final int total;
  final int unread;
  final int read;

  NotificationStats({
    required this.total,
    required this.unread,
    required this.read,
  });

  factory NotificationStats.fromJson(Map<String, dynamic> json) {
    return NotificationStats(
      total: json['total'] ?? 0,
      unread: json['unread'] ?? 0,
      read: json['read'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'unread': unread,
      'read': read,
    };
  }
}