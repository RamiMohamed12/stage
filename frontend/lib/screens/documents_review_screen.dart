import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/models/document.dart';
import 'package:frontend/services/document_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/notification_service.dart';
import 'package:frontend/services/declaration_service.dart';
import 'package:frontend/services/appointment_service.dart';
import 'package:frontend/models/notification.dart' as NotificationModel;
import 'package:frontend/widgets/loading_indicator.dart';
import 'dart:async';

class DocumentsReviewScreen extends StatefulWidget {
  final int declarationId;
  final String? applicantName;

  const DocumentsReviewScreen({
    super.key,
    required this.declarationId,
    this.applicantName,
  });

  @override
  State<DocumentsReviewScreen> createState() => _DocumentsReviewScreenState();
}

class _DocumentsReviewScreenState extends State<DocumentsReviewScreen> {
  final DocumentService _documentService = DocumentService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final DeclarationService _declarationService = DeclarationService();
  final AppointmentService _appointmentService = AppointmentService();
  List<DeclarationDocument> _documents = [];
  List<NotificationModel.Notification> _notifications = [];
  NotificationModel.NotificationStats? _notificationStats;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;
  Timer? _notificationTimer;
  DateTime? _lastRefresh;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadDocuments();
    _startAutoRefresh();
    _startNotificationPolling();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initializePushNotifications();
    
    // Set auth token for notification service
    final token = await _authService.getToken();
    if (token != null) {
      _notificationService.setAuthToken(token);
    }
  }

  void _startNotificationPolling() {
    // Check for new notifications every 30 seconds
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _checkForNewNotifications();
      }
    });
  }

  Future<void> _checkForNewNotifications() async {
    final result = await _notificationService.getUserNotifications(limit: 10, unreadOnly: true);
    if (result['success'] == true) {
      final newNotifications = result['notifications'] as List<NotificationModel.Notification>;
      
      // Check for appointment notifications related to this declaration
      final appointmentNotification = newNotifications.firstWhere(
        (notification) => 
          notification.type == 'appointment' && 
          notification.relatedId == widget.declarationId,
        orElse: () => NotificationModel.Notification(
          notificationId: 0,
          userId: 0,
          title: '',
          body: '',
          type: '',
          isRead: false,
          sentAt: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );
      
      // Check for any rejection notification related to this declaration
      final anyRejectionNotification = newNotifications.firstWhere(
        (notification) => 
          notification.type == 'declaration_rejected' && 
          notification.relatedId == widget.declarationId,
        orElse: () => NotificationModel.Notification(
          notificationId: 0,
          userId: 0,
          title: '',
          body: '',
          type: '',
          isRead: false,
          sentAt: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );
      
      // Show push notifications for truly new notifications
      final existingIds = _notifications.map((n) => n.notificationId).toSet();
      final reallyNewNotifications = newNotifications
          .where((n) => !existingIds.contains(n.notificationId))
          .toList();
      
      // Show push notifications for ALL new notifications, including document reviews
      for (final notification in reallyNewNotifications) {
        await _notificationService.showPushNotification(
          title: notification.title,
          body: notification.body,
          type: notification.type,
          payload: {
            'notification_id': notification.notificationId.toString(),
            'type': notification.type,
            'related_id': notification.relatedId?.toString() ?? '',
          },
        );
      }
      
      if (reallyNewNotifications.isNotEmpty) {
        setState(() {
          _notifications = newNotifications;
        });
        _loadNotificationStats();
      }
      
      // CRITICAL FIX: Check the latest declaration status and appointment info
      // instead of relying only on notifications
      await _checkLatestDeclarationStatus();
    }
  }

  // NEW METHOD: Check the latest declaration status and navigate accordingly
  Future<void> _checkLatestDeclarationStatus() async {
    try {
      // Fetch the latest declaration status from the backend
      final declarationResult = await _declarationService.getDeclarationById(widget.declarationId);
      
      // The backend returns the declaration object directly, not wrapped in a success field
      final status = declarationResult['status'];
      
      // If declaration is approved, check if appointment exists
      if (status == 'approved') {
        // Mark any old rejection notifications for this declaration as read
        // to prevent them from interfering with navigation
        await _markOldRejectionNotificationsAsRead();
        
        try {
          final appointmentResult = await _appointmentService.getAppointmentByDeclarationId(widget.declarationId);
          if (appointmentResult != null) {
            // Declaration is approved and appointment exists - navigate to success screen
            if (mounted) {
              Navigator.pushReplacementNamed(
                context,
                '/appointment-success',
                arguments: {
                  'declarationId': widget.declarationId,
                  'applicantName': widget.applicantName,
                },
              );
              return;
            }
          }
        } catch (e) {
          // Appointment not found, but declaration is approved - still navigate to success
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/appointment-success',
              arguments: {
                'declarationId': widget.declarationId,
                'applicantName': widget.applicantName,
              },
            );
            return;
          }
        }
      }
      
      // If declaration is rejected, navigate to rejection screen
      if (status == 'rejected') {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/rejection',
            arguments: {
              'declarationId': widget.declarationId,
              'applicantName': widget.applicantName,
              'rejectionReason': declarationResult['rejection_reason'] ?? 'Raison non spécifiée',
            },
          );
          return;
        }
      }
      
      // For other statuses (pending, submitted), stay on current screen
      // The documents will continue to be reviewed
    } catch (e) {
      // If there's an error fetching the declaration status, fall back to notification-based logic
      print('Error checking declaration status: $e');
      
      // Fallback to the original notification-based logic
      final result = await _notificationService.getUserNotifications(limit: 10, unreadOnly: true);
      if (result['success'] == true) {
        final newNotifications = result['notifications'] as List<NotificationModel.Notification>;
        
        // Check for appointment notifications related to this declaration
        final appointmentNotification = newNotifications.firstWhere(
          (notification) => 
            notification.type == 'appointment' && 
            notification.relatedId == widget.declarationId,
          orElse: () => NotificationModel.Notification(
            notificationId: 0,
            userId: 0,
            title: '',
            body: '',
            type: '',
            isRead: false,
            sentAt: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        );
        
        // Check for any rejection notification related to this declaration
        final anyRejectionNotification = newNotifications.firstWhere(
          (notification) => 
            notification.type == 'declaration_rejected' && 
            notification.relatedId == widget.declarationId,
          orElse: () => NotificationModel.Notification(
            notificationId: 0,
            userId: 0,
            title: '',
            body: '',
            type: '',
            isRead: false,
            sentAt: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        );
        
        // If there's a rejection notification, navigate to the rejection screen
        if (anyRejectionNotification.notificationId != 0) {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/rejection',
              arguments: {
                'declarationId': widget.declarationId,
                'applicantName': widget.applicantName,
                'rejectionReason': anyRejectionNotification.body,
              },
            );
            return;
          }
        }
        
        // If we found an appointment notification for this declaration, navigate to appointment screen
        if (appointmentNotification.notificationId != 0) {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/appointment-success',
              arguments: {
                'declarationId': widget.declarationId,
                'applicantName': widget.applicantName,
              },
            );
            return;
          }
        }
      }
    }
  }

  // NEW METHOD: Mark old rejection notifications as read
  Future<void> _markOldRejectionNotificationsAsRead() async {
    try {
      // Get all unread rejection notifications for this declaration
      final result = await _notificationService.getUserNotifications(limit: 100, unreadOnly: true);
      if (result['success'] == true) {
        final notifications = result['notifications'] as List<NotificationModel.Notification>;
        
        // Find rejection notifications for this declaration
        final rejectionNotifications = notifications.where((notification) => 
          notification.type == 'declaration_rejected' && 
          notification.relatedId == widget.declarationId
        ).toList();
        
        // Mark each rejection notification as read
        for (final notification in rejectionNotifications) {
          await _notificationService.markNotificationAsRead(notification.notificationId);
        }
        
        if (rejectionNotifications.isNotEmpty) {
          print('Marked ${rejectionNotifications.length} old rejection notifications as read for declaration ${widget.declarationId}');
        }
      }
    } catch (e) {
      // Silent fail - this is not critical
      print('Error marking old rejection notifications as read: $e');
    }
  }

  Future<void> _loadNotificationStats() async {
    final result = await _notificationService.getNotificationStats();
    if (result['success'] == true) {
      setState(() {
        _notificationStats = result['stats'] as NotificationModel.NotificationStats;
      });
    }
  }

  void _startAutoRefresh() {
    // Auto-refresh every 30 seconds if documents are still under review
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && _shouldAutoRefresh()) {
        _loadDocuments(showLoading: false);
      }
    });
  }

  bool _shouldAutoRefresh() {
    // Only auto-refresh if there are documents still under review
    return _documents.any((doc) => 
      doc.status == DocumentStatus.uploaded || 
      doc.status == DocumentStatus.pending
    );
  }

  Future<void> _loadDocuments({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final documents = await _documentService.getDeclarationDocuments(widget.declarationId);
      setState(() {
        _documents = documents;
        _isLoading = false;
        _lastRefresh = DateTime.now();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur de déconnexion: ${e.toString()}';
        });
      }
    }
  }

  String _getReviewStatus() {
    if (_documents.isEmpty) return 'Aucun document';
    
    final hasRejected = _documents.any((doc) => doc.status == DocumentStatus.rejected);
    final hasUploaded = _documents.any((doc) => doc.status == DocumentStatus.uploaded);
    final allApproved = _documents.every((doc) => doc.status == DocumentStatus.approved);
    
    if (hasRejected) {
      return 'Documents à corriger';
    } else if (allApproved) {
      return 'Documents approuvés';
    } else if (hasUploaded) {
      return 'Documents en cours de révision';
    } else {
      return 'Documents en attente';
    }
  }

  Color _getReviewStatusColor() {
    if (_documents.isEmpty) return AppColors.grayColor;
    
    final hasRejected = _documents.any((doc) => doc.status == DocumentStatus.rejected);
    final hasUploaded = _documents.any((doc) => doc.status == DocumentStatus.uploaded);
    final allApproved = _documents.every((doc) => doc.status == DocumentStatus.approved);
    
    if (hasRejected) {
      return Colors.red;
    } else if (allApproved) {
      return Colors.green;
    } else if (hasUploaded) {
      return Colors.blue;
    } else {
      return Colors.orange;
    }
  }

  IconData _getReviewStatusIcon() {
    final color = _getReviewStatusColor();
    if (color == Colors.green) return Icons.verified_user;
    if (color == Colors.red) return Icons.error_outline;
    if (color == Colors.blue) return Icons.visibility;
    return Icons.schedule;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLightColor,
      body: Stack(
        children: [
          // Background Gradient (same as formulaire_download_screen)
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
            child: _isLoading
                ? const SizedBox()
                : RefreshIndicator(
                    onRefresh: _loadDocuments,
                    color: AppColors.primaryColor,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 20),
                            _buildHeader(),
                            const SizedBox(height: 40),
                            _buildReviewCard(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          if (_isLoading)
            const LoadingIndicator(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          children: [
            const Spacer(),
            // Notification button with badge
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: () => Navigator.pushNamed(context, '/notifications'),
                    tooltip: 'Notifications',
                  ),
                ),
                if (_notificationStats != null && _notificationStats!.unread > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${_notificationStats!.unread}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
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
        Icon(
          _getReviewStatusIcon(),
          color: Colors.white,
          size: 64,
        ),
        const SizedBox(height: 16),
        const Text(
          "Révision des Documents",
          style: TextStyle(
            color: AppColors.whiteColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.applicantName ?? 'Déclaration #${widget.declarationId}',
          style: TextStyle(
            color: AppColors.whiteColor.withOpacity(0.8),
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildReviewCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _getReviewStatus(),
              style: TextStyle(
                color: AppColors.subTitleColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "État actuel de vos documents",
              style: TextStyle(
                color: AppColors.grayColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Error Display
            if (_errorMessage != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.errorColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.errorColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Documents List - styled like instruction steps
            if (_documents.isNotEmpty) ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _documents.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final document = _documents[index];
                  return _buildDocumentStep(document, index + 1);
                },
              ),
              const SizedBox(height: 32),
            ],

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentStep(DeclarationDocument document, int stepNumber) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.bgLightColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getStatusColor(document.status),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: document.status == DocumentStatus.approved
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : document.status == DocumentStatus.rejected
                      ? const Icon(Icons.close, color: Colors.white, size: 20)
                      : Text(
                          stepNumber.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            _getStatusIcon(document.status),
            color: _getStatusColor(document.status),
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        document.documentName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                      ),
                    ),
                    if (document.isMandatory)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Obligatoire',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusText(document.status),
                  style: TextStyle(
                    fontSize: 14,
                    color: _getStatusColor(document.status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (document.rejectionReason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Motif: ${document.rejectionReason}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // MODIFIED WIDGET
  Widget _buildActionButtons() {
    // This condition is true if there's at least one document that is not approved.
    final bool hasUnapproved = _documents.any((doc) => doc.status != DocumentStatus.approved);

    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          // If there are unapproved documents, show the "Modify" button.
          if (hasUnapproved)
            ElevatedButton.icon(
              icon: const Icon(Icons.edit_document, size: 22.0),
              label: const Text('Modifier les documents'),
              onPressed: () {
                Navigator.pushReplacementNamed(
                  context,
                  '/documents-upload',
                  arguments: {
                    'declarationId': widget.declarationId,
                    'declarantName': widget.applicantName ?? '',
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                alignment: Alignment.center,
                elevation: 4.0,
              ),
            )
          // Otherwise (if all documents are approved), show the "New Declaration" button.
          else
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/agencySelection',
                  (route) => false,
                );
              },
              icon: const Icon(Icons.add_circle, color: AppColors.whiteColor),
              label: const Text(
                'Nouvelle Déclaration',
                style: TextStyle(
                  color: AppColors.whiteColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
        ],
      ),
    );
  }


  Color _getStatusColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.pending:
        return Colors.orange;
      case DocumentStatus.uploaded:
        return Colors.blue;
      case DocumentStatus.approved:
        return Colors.green;
      case DocumentStatus.rejected:
        return Colors.red;
    }
  }

  String _getStatusText(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.pending:
        return 'En attente';
      case DocumentStatus.uploaded:
        return 'En révision';
      case DocumentStatus.approved:
        return 'Approuvé';
      case DocumentStatus.rejected:
        return 'Rejeté';
    }
  }

  IconData _getStatusIcon(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.pending:
        return Icons.schedule;
      case DocumentStatus.uploaded:
        return Icons.visibility;
      case DocumentStatus.approved:
        return Icons.check_circle;
      case DocumentStatus.rejected:
        return Icons.cancel;
    }
  }
}