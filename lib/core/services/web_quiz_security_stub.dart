// Stub implementation for non-web platforms
class WebQuizSecurity {
  Future<void> requestFullscreen() async {}
  Future<void> exitFullscreen() async {}
  bool get isFullscreen => false;
  void setupVisibilityDetection(Function() onVisibilityChange) {}
  void removeVisibilityDetection() {}
  void dispose() {}
}
