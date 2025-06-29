import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../constants/api_endpoints.dart';
import '../models/notification.dart' as NotificationModel;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  String? _authToken;
  bool _isInitialized = false;
  FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;

  void setAuthToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // Initialize push notifications
  Future<void> initializePushNotifications() async {
    if (_isInitialized) return;

    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize the plugin
    await _flutterLocalNotificationsPlugin!.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    await _requestPermissions();

    _isInitialized = true;
  }

  Future<void> _requestPermissions() async {
    if (_flutterLocalNotificationsPlugin != null) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin!.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.requestExactAlarmsPermission();
        await androidImplementation.requestNotificationsPermission();
      }
    }
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    // Handle notification tap
    print('Notification tapped: ${notificationResponse.payload}');
    // You can navigate to specific screens based on the payload
  }

  // Show local push notification
  Future<void> showPushNotification({
    required String title,
    required String body,
    String? type,
    Map<String, String>? payload,
  }) async {
    if (!_isInitialized) {
      await initializePushNotifications();
    }

    if (_flutterLocalNotificationsPlugin == null) return;

    // Create notification details
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      _getChannelId(type),
      _getChannelName(type),
      channelDescription: _getChannelDescription(type),
      importance: _getImportance(type),
      priority: _getPriority(type),
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF2E7D32),
      playSound: true,
      enableVibration: true,
      autoCancel: true,
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    // Show the notification
    await _flutterLocalNotificationsPlugin!.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000), // Unique ID
      title,
      body,
      notificationDetails,
      payload: payload != null ? payload.toString() : null,
    );
  }

  String _getChannelId(String? type) {
    switch (type) {
      case 'declaration_approved':
      case 'declaration_rejected':
      case 'appointment':
      case 'appointment_rejected':
        return 'high_importance_channel';
      case 'document_review':
        return 'document_channel';
      default:
        return 'general_channel';
    }
  }

  String _getChannelName(String? type) {
    switch (type) {
      case 'declaration_approved':
      case 'declaration_rejected':
      case 'appointment':
      case 'appointment_rejected':
        return 'Notifications importantes';
      case 'document_review':
        return 'Révision de documents';
      default:
        return 'Notifications générales';
    }
  }

  String _getChannelDescription(String? type) {
    switch (type) {
      case 'declaration_approved':
      case 'declaration_rejected':
      case 'appointment':
      case 'appointment_rejected':
        return 'Notifications pour les déclarations approuvées, rejetées et rendez-vous';
      case 'document_review':
        return 'Notifications pour la révision de documents';
      default:
        return 'Notifications générales de l\'application';
    }
  }

  Importance _getImportance(String? type) {
    switch (type) {
      case 'declaration_approved':
      case 'declaration_rejected':
      case 'appointment':
      case 'appointment_rejected':
        return Importance.high;
      case 'document_review':
        return Importance.defaultImportance;
      default:
        return Importance.low;
    }
  }

  Priority _getPriority(String? type) {
    switch (type) {
      case 'declaration_approved':
      case 'declaration_rejected':
      case 'appointment':
      case 'appointment_rejected':
        return Priority.high;
      case 'document_review':
        return Priority.defaultPriority;
      default:
        return Priority.low;
    }
  }

  // Get user's notifications from server
  Future<Map<String, dynamic>> getUserNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        'offset': offset.toString(),
        'unread_only': unreadOnly.toString(),
      };

      final uri = Uri.parse(ApiEndpoints.notifications)
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final notifications = (data['notifications'] as List)
            .map((json) => NotificationModel.Notification.fromJson(json))
            .toList();

        return {
          'success': true,
          'notifications': notifications,
          'total': data['total'] ?? 0,
          'limit': data['limit'] ?? limit,
          'offset': data['offset'] ?? offset,
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch notifications',
        };
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
      };
    }
  }

  // Get notification statistics
  Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.notifications}/stats'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'stats': NotificationModel.NotificationStats.fromJson(data),
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch notification stats',
        };
      }
    } catch (e) {
      print('Error fetching notification stats: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
      };
    }
  }

  // Mark notification as read
  Future<Map<String, dynamic>> markNotificationAsRead(int notificationId) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiEndpoints.notifications}/$notificationId/read'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Notification marked as read',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to mark notification as read',
        };
      }
    } catch (e) {
      print('Error marking notification as read: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
      };
    }
  }

  // Mark all notifications as read
  Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiEndpoints.notifications}/mark-all-read'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'All notifications marked as read',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to mark all notifications as read',
        };
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
      };
    }
  }

  // Delete notification
  Future<Map<String, dynamic>> deleteNotification(int notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiEndpoints.notifications}/$notificationId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Notification deleted successfully',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to delete notification',
        };
      }
    } catch (e) {
      print('Error deleting notification: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
      };
    }
  }

  // Poll for new notifications (call this periodically)
  Future<void> checkForNewNotifications() async {
    try {
      final result = await getUserNotifications(limit: 10, unreadOnly: true);
      if (result['success'] == true) {
        final notifications = result['notifications'] as List<NotificationModel.Notification>;
        
        // Show push notifications for new unread notifications
        for (final notification in notifications) {
          if (!notification.isRead) {
            await showPushNotification(
              title: notification.title,
              body: notification.body,
              type: notification.type,
              payload: {
                'notification_id': notification.notificationId.toString(),
                'type': notification.type,
              },
            );
          }
        }
      }
    } catch (e) {
      print('Error checking for new notifications: $e');
    }
  }
}