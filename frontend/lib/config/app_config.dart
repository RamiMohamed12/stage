class AppConfig {
  // API Configuration
  static const String baseUrl = 'http://192.168.108.17:3000/api';
  
  // App Configuration
  static const String appName = 'Declaration App';
  static const String appVersion = '1.0.0';
  
  // Development/Production flags
  static const bool isDevelopment = true;
  static const bool enableLogging = true;
  
  // Network Configuration
  static const int timeoutSeconds = 30;
  static const int maxRetries = 3;
  
  // Notification Configuration
  static const int notificationRefreshInterval = 30; // seconds
  static const int maxNotificationsPerPage = 50;
}
