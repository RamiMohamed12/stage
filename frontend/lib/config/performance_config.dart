import 'package:flutter/foundation.dart';

class PerformanceConfig {
  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 300);
  static const Duration mediumAnimation = Duration(milliseconds: 600);
  static const Duration longAnimation = Duration(milliseconds: 800);
  
  // Enable/disable features based on platform performance
  static bool get enableComplexAnimations => !kIsWeb && kDebugMode;
  static bool get enableShadows => !kIsWeb;
  static bool get enableBlur => !kIsWeb;
  
  // Memory optimization
  static const int maxCachedImages = 50;
  static const int maxCachedNetworkRequests = 20;
  
  // UI responsiveness
  static const Duration debounceDelay = Duration(milliseconds: 300);
  static const Duration throttleDelay = Duration(milliseconds: 100);
}
