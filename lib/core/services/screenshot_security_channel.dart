import 'package:flutter/services.dart';

/// Platform channel for screenshot detection and blocking
/// This communicates with native Android and iOS code
class ScreenshotSecurityChannel {
  static const MethodChannel _channel = MethodChannel('com.example.quizapp/screenshot_security');
  
  /// Enable screenshot blocking (Android only)
  /// iOS doesn't support screenshot blocking, only detection
  static Future<bool> enableScreenshotBlocking() async {
    try {
      final result = await _channel.invokeMethod<bool>('enableScreenshotBlocking');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
  
  /// Disable screenshot blocking
  static Future<bool> disableScreenshotBlocking() async {
    try {
      final result = await _channel.invokeMethod<bool>('disableScreenshotBlocking');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
  
  /// Setup screenshot detection listener
  /// Calls the provided callback when a screenshot is detected
  static void setScreenshotDetectionListener(Function() onScreenshotDetected) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onScreenshotDetected') {
        onScreenshotDetected();
      }
    });
  }
  
  /// Remove screenshot detection listener
  static void removeScreenshotDetectionListener() {
    _channel.setMethodCallHandler(null);
  }
}
