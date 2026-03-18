import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screenshot_security_channel.dart';

// Conditional import for web
import 'web_quiz_security.dart' if (dart.library.io) 'web_quiz_security_stub.dart';

/// Quiz Security Service
/// Handles screenshot detection, fullscreen mode, and security violations
class QuizSecurityService {
  // Screenshot counter
  int _screenshotCount = 0;
  
  // Violation callbacks
  VoidCallback? onFirstWarning;
  VoidCallback? onSecondWarning;
  VoidCallback? onAutoSubmit;
  
  // Web-specific: tab visibility detection
  Timer? _visibilityCheckTimer;
  int _tabSwitchCount = 0;
  VoidCallback? onTabSwitch;
  
  // Platform check
  bool get isMobile => !kIsWeb;
  bool get isWeb => kIsWeb;
  
  // Web security instance
  WebQuizSecurity? _webSecurity;
  
  /// Initialize security features when quiz starts
  Future<void> enableQuizSecurity({
    required BuildContext context,
    VoidCallback? onFirstWarning,
    VoidCallback? onSecondWarning,
    VoidCallback? onAutoSubmit,
    VoidCallback? onTabSwitch,
  }) async {
    this.onFirstWarning = onFirstWarning;
    this.onSecondWarning = onSecondWarning;
    this.onAutoSubmit = onAutoSubmit;
    this.onTabSwitch = onTabSwitch;
    
    _screenshotCount = 0;
    _tabSwitchCount = 0;
    
    if (isMobile) {
      await _enableMobileSecurity();
    } else if (isWeb) {
      await _enableWebSecurity(context);
    }
  }
  
  /// Disable security features when quiz ends
  Future<void> disableQuizSecurity() async {
    if (isMobile) {
      await _disableMobileSecurity();
    } else if (isWeb) {
      await _disableWebSecurity();
    }
    
    _visibilityCheckTimer?.cancel();
    _visibilityCheckTimer = null;
    _screenshotCount = 0;
    _tabSwitchCount = 0;
  }
  
  /// Mobile: Enable fullscreen and setup screenshot detection
  Future<void> _enableMobileSecurity() async {
    try {
      // Enter fullscreen mode - hide status bar and navigation bar
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );
      
      // Set up screenshot detection listener
      // Note: On Android, we can use MethodChannel for native screenshot blocking
      // On iOS, we can only detect screenshots after they happen
      _setupScreenshotListener();
      
    } catch (e) {
      debugPrint('Error enabling mobile security: $e');
    }
  }
  
  /// Mobile: Restore normal UI mode
  Future<void> _disableMobileSecurity() async {
    try {
      // Restore normal system UI
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: SystemUiOverlay.values,
      );
    } catch (e) {
      debugPrint('Error disabling mobile security: $e');
    }
  }
  
  /// Setup screenshot detection for mobile
  void _setupScreenshotListener() {
    // Setup native platform channel listener
    ScreenshotSecurityChannel.setScreenshotDetectionListener(() {
      handleScreenshotDetected();
    });
    
    // Enable screenshot blocking on Android
    ScreenshotSecurityChannel.enableScreenshotBlocking();
  }
  
  /// Handle screenshot detection
  void handleScreenshotDetected() {
    _screenshotCount++;
    
    if (_screenshotCount == 1) {
      // First warning
      onFirstWarning?.call();
    } else if (_screenshotCount == 2) {
      // Second warning
      onSecondWarning?.call();
    } else if (_screenshotCount >= 3) {
      // Auto-submit quiz
      onAutoSubmit?.call();
    }
  }
  
  /// Web: Enable fullscreen and visibility detection
  Future<void> _enableWebSecurity(BuildContext context) async {
    // Request fullscreen mode on web
    // Note: This requires user interaction to work in browsers
    if (kIsWeb) {
      _webSecurity = WebQuizSecurity();
      
      // Request fullscreen
      await _webSecurity?.requestFullscreen();
      
      // Setup visibility monitoring
      _webSecurity?.setupVisibilityDetection(() {
        handleVisibilityChange();
      });
    }
  }
  
  /// Web: Exit fullscreen
  Future<void> _disableWebSecurity() async {
    if (kIsWeb) {
      await _webSecurity?.exitFullscreen();
      _webSecurity?.removeVisibilityDetection();
      _webSecurity?.dispose();
      _webSecurity = null;
    }
  }
  
  /// Handle tab switch/visibility change
  void handleVisibilityChange() {
    _tabSwitchCount++;
    
    if (_tabSwitchCount == 1) {
      // First warning
      onTabSwitch?.call();
    } else if (_tabSwitchCount >= 2) {
      // Auto-submit quiz
      onAutoSubmit?.call();
    }
  }
  
  /// Get current screenshot count
  int get screenshotCount => _screenshotCount;
  
  /// Get current tab switch count
  int get tabSwitchCount => _tabSwitchCount;
  
  /// Reset counters
  void resetCounters() {
    _screenshotCount = 0;
    _tabSwitchCount = 0;
  }
}
