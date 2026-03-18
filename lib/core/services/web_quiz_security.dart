// Web-specific security implementation
// This file should only be imported in web builds

// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';

/// Web security manager for quiz
/// Handles fullscreen mode and visibility detection
class WebQuizSecurity {
  Timer? _visibilityCheckTimer;
  Function()? _onVisibilityChange;
  bool _wasVisible = true;
  
  /// Request fullscreen mode
  Future<void> requestFullscreen() async {
    try {
      await html.document.documentElement?.requestFullscreen();
    } catch (e) {
      print('Error requesting fullscreen: $e');
    }
  }
  
  /// Exit fullscreen mode
  Future<void> exitFullscreen() async {
    try {
      if (html.document.fullscreenElement != null) {
        html.document.exitFullscreen();
      }
    } catch (e) {
      print('Error exiting fullscreen: $e');
    }
  }
  
  /// Check if in fullscreen mode
  bool get isFullscreen {
    return html.document.fullscreenElement != null;
  }
  
  /// Setup visibility change detection
  void setupVisibilityDetection(Function() onVisibilityChange) {
    _onVisibilityChange = onVisibilityChange;
    
    // Listen to visibility change events
    html.document.onVisibilityChange.listen((_) {
      _handleVisibilityChange();
    });
    
    // Listen to fullscreen change events
    html.document.onFullscreenChange.listen((_) {
      if (!isFullscreen && _onVisibilityChange != null) {
        _onVisibilityChange!();
      }
    });
    
    // Additional checks for tab switching
    html.window.onBlur.listen((_) {
      _handleVisibilityChange();
    });
    
    // Start periodic check
    _visibilityCheckTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _checkVisibility(),
    );
  }
  
  void _handleVisibilityChange() {
    final isVisible = !html.document.hidden!;
    
    if (!isVisible && _wasVisible) {
      // Tab became hidden
      _onVisibilityChange?.call();
    }
    
    _wasVisible = isVisible;
  }
  
  void _checkVisibility() {
    if (html.document.hidden! && _wasVisible) {
      _handleVisibilityChange();
    }
  }
  
  /// Remove visibility detection
  void removeVisibilityDetection() {
    _visibilityCheckTimer?.cancel();
    _visibilityCheckTimer = null;
    _onVisibilityChange = null;
  }
  
  /// Cleanup
  void dispose() {
    removeVisibilityDetection();
  }
}
