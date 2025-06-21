import 'package:flutter/material.dart';
import '../models/notification.dart' as model;
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../constants/colors.dart';
import '../widgets/loading_indicator.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  List<model.Notification> _notifications = [];
  model.NotificationStats? _stats;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadStats();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final result = await _notificationService.getUserNotifications();
    
    if (result['success'] == true) {
      setState(() {
        _notifications = result['notifications'] as List<model.Notification>;
        _isLoading = false;
      });
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = result['message'] ?? 'Failed to load notifications';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStats() async {
    final result = await _notificationService.getNotificationStats();
    if (result['success'] == true) {
      setState(() {
        _stats = result['stats'] as model.NotificationStats;
      });
    }
  }

  Future<void> _markAsRead(model.Notification notification) async {
    if (notification.isRead) return;

    final result = await _notificationService.markNotificationAsRead(notification.notificationId);
    if (result['success'] == true) {
      setState(() {
        final index = _notifications.indexWhere((n) => n.notificationId == notification.notificationId);
        if (index != -1) {
          _notifications[index] = model.Notification(
            notificationId: notification.notificationId,
            userId: notification.userId,
            title: notification.title,
            body: notification.body,
            type: notification.type,
            relatedId: notification.relatedId,
            isRead: true,
            sentAt: notification.sentAt,
            readAt: DateTime.now(),
            createdByAdminId: notification.createdByAdminId,
            createdAt: notification.createdAt,
          );
        }
      });
      _loadStats(); // Refresh stats
    }
  }

  Future<void> _markAllAsRead() async {
    final result = await _notificationService.markAllNotificationsAsRead();
    if (result['success'] == true) {
      setState(() {
        _notifications = _notifications.map((n) => model.Notification(
          notificationId: n.notificationId,
          userId: n.userId,
          title: n.title,
          body: n.body,
          type: n.type,
          relatedId: n.relatedId,
          isRead: true,
          sentAt: n.sentAt,
          readAt: DateTime.now(),
          createdByAdminId: n.createdByAdminId,
          createdAt: n.createdAt,
        )).toList();
      });
      _loadStats(); // Refresh stats
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    }
  }

  Future<void> _deleteNotification(model.Notification notification) async {
    final result = await _notificationService.deleteNotification(notification.notificationId);
    if (result['success'] == true) {
      setState(() {
        _notifications.removeWhere((n) => n.notificationId == notification.notificationId);
      });
      _loadStats(); // Refresh stats
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification deleted')),
      );
    }
  }

  Future<void> _refreshNotifications() async {
    await _loadNotifications();
    await _loadStats();
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de déconnexion: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'document_review':
        return Colors.blue;
      case 'declaration_approved':
        return Colors.green;
      case 'declaration_rejected':
        return Colors.red;
      case 'appointment':
        return AppColors.primaryColor;
      case 'general':
      default:
        return AppColors.grayColor;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'document_review':
        return Icons.description;
      case 'declaration_approved':
        return Icons.check_circle;
      case 'declaration_rejected':
        return Icons.cancel;
      case 'appointment':
        return Icons.event;
      case 'general':
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLightColor,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primaryColor, AppColors.bgDarkBlueColor],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),
          // Main Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
          if (_isLoading)
            const LoadingIndicator(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Spacer(),
              // Logout button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: _logout,
                  tooltip: 'Déconnexion',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Icon(
            Icons.notifications,
            color: Colors.white,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            "Notifications",
            style: TextStyle(
              color: AppColors.whiteColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (_stats != null)
            Text(
              "${_stats!.unread} non lues sur ${_stats!.total}",
              style: TextStyle(
                color: AppColors.whiteColor.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const SizedBox();
    }

    if (_hasError) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.errorColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grayColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadNotifications,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications_off,
                  size: 64,
                  color: AppColors.grayColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune notification',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vous verrez vos notifications ici quand vous en recevrez',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grayColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Action buttons
        if (_stats != null && _stats!.unread > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _markAllAsRead,
                    icon: const Icon(Icons.mark_email_read, size: 18),
                    label: const Text('Tout marquer comme lu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 16),
        
        // Notifications list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshNotifications,
            color: AppColors.primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return _buildNotificationCard(notification);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(model.Notification notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: notification.isRead ? 2 : 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _markAsRead(notification),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: notification.isRead ? null : AppColors.primaryColor.withOpacity(0.05),
              border: notification.isRead 
                  ? null 
                  : Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getNotificationColor(notification.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getNotificationIcon(notification.type),
                        color: _getNotificationColor(notification.type),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            notification.typeDisplayName,
                            style: TextStyle(
                              color: _getNotificationColor(notification.type),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'mark_read':
                            _markAsRead(notification);
                            break;
                          case 'delete':
                            _deleteNotification(notification);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (!notification.isRead)
                          const PopupMenuItem(
                            value: 'mark_read',
                            child: Row(
                              children: [
                                Icon(Icons.mark_email_read, size: 18),
                                SizedBox(width: 8),
                                Text('Marquer comme lu'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text('Supprimer', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  notification.body,
                  style: TextStyle(
                    color: AppColors.grayColor,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notification.timeAgo,
                      style: TextStyle(
                        color: AppColors.grayColor.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}