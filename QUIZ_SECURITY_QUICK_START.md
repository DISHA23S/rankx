# Quiz Security - Quick Start Guide

## ✅ Implementation Status: COMPLETE

All security features have been implemented and integrated into your Flutter quiz app.

---

## 📁 Files Created/Modified

### ✅ Core Security Services
- `lib/core/services/quiz_security_service.dart` - Main security orchestration
- `lib/core/services/screenshot_security_channel.dart` - Native platform channel
- `lib/core/services/web_quiz_security.dart` - Web-specific security (fullscreen, tab detection)
- `lib/core/services/web_quiz_security_stub.dart` - Stub for non-web platforms

### ✅ UI Components
- `lib/core/widgets/quiz_security_overlay.dart` - Watermark overlay and warning dialogs

### ✅ Integration
- `lib/features/user/screens/quiz_taking_screen.dart` - Fully integrated with security features

### ✅ Native Code Templates
- `android/app/src/main/kotlin/com/example/quizapp/MainActivity_SECURITY_INTEGRATION.kt`
- `ios/Runner/AppDelegate_SECURITY_INTEGRATION.swift`

### ✅ Documentation
- `QUIZ_SECURITY_IMPLEMENTATION.md` - Complete implementation guide

---

## 🚀 Next Steps (Required for Full Functionality)

### 1. Add Dependency
Add to `pubspec.yaml`:
```yaml
dependencies:
  intl: ^0.18.0  # Required for watermark date formatting
```

Then run:
```bash
flutter pub get
```

### 2. Android Native Integration
Copy contents from:
```
android/app/src/main/kotlin/com/example/quizapp/MainActivity_SECURITY_INTEGRATION.kt
```

To:
```
android/app/src/main/kotlin/com/example/quizapp/MainActivity.kt
```

### 3. iOS Native Integration
Copy contents from:
```
ios/Runner/AppDelegate_SECURITY_INTEGRATION.swift
```

To:
```
ios/Runner/AppDelegate.swift
```

### 4. Test
```bash
# Clean and rebuild
flutter clean
flutter pub get

# Test on Android
flutter run

# Test on iOS
cd ios && pod install && cd ..
flutter run

# Test on Web
flutter run -d chrome
```

---

## 🔒 Features Implemented

### Mobile (Android & iOS)
✅ Fullscreen mode (hides status bar and navigation bar)
✅ Screenshot detection via platform channels
✅ Screenshot blocking (Android only - FLAG_SECURE)
✅ 3-strike warning system
✅ Auto-submit after 3rd screenshot
✅ Warning dialogs with appropriate messages

### Web
✅ Fullscreen mode (browser fullscreen API)
✅ Tab switching detection
✅ Window minimize/blur detection
✅ Exit fullscreen detection
✅ 2-strike warning system
✅ Auto-submit after 2nd violation
✅ Watermark overlay (user email + timestamp)

---

## 📊 Security Flow

```
User Starts Quiz
    ↓
QuizSecurityService.enableQuizSecurity()
    ├── Mobile: SystemChrome.setEnabledSystemUIMode(immersiveSticky)
    │   └── Setup screenshot listener via MethodChannel
    └── Web: document.requestFullscreen()
        └── Setup visibility change detection
    ↓
During Quiz
    ├── Screenshot detected (Mobile)
    │   ├── 1st: Show "Warning #1" dialog
    │   ├── 2nd: Show "Final Warning" dialog
    │   └── 3rd: Show "Quiz Submitted" → Auto-submit
    └── Tab switch detected (Web)
        ├── 1st: Show "Warning" dialog
        └── 2nd: Show "Quiz Submitted" → Auto-submit
    ↓
Quiz Ends (Submit or Auto-Submit)
    ↓
QuizSecurityService.disableQuizSecurity()
    ├── Mobile: Restore system UI
    └── Web: Exit fullscreen
```

---

## 🎯 How It Works in Code

### Initialization
```dart
// In quiz_taking_screen.dart - Line ~87
_enableQuizSecurity();
```

### Security Active During Quiz
```dart
// Wrapped in QuizSecurityOverlay - Line ~228
QuizSecurityOverlay(
  userIdentifier: userEmail,
  showWatermark: true,
  child: Scaffold(...)
)
```

### Auto-Submit on Violation
```dart
// Security service calls this - Line ~142
void _handleAutoSubmit() {
  showDialog(...).then((_) {
    _submitQuiz(isAutoSubmit: true);
  });
}
```

### Cleanup on Exit
```dart
// In dispose() - Line ~54
@override
void dispose() {
  _securityService.disableQuizSecurity();
  super.dispose();
}
```

---

## 🧪 Testing Checklist

### Android Testing
- [ ] App enters fullscreen (status bar hidden)
- [ ] Screenshot attempts blocked (screen goes black)
- [ ] 1st screenshot → Warning #1 dialog appears
- [ ] 2nd screenshot → Final Warning dialog appears
- [ ] 3rd screenshot → Auto-submit dialog + quiz submits

### iOS Testing
- [ ] App enters fullscreen
- [ ] Screenshot detection works (screenshots allowed but detected)
- [ ] 1st screenshot → Warning #1 dialog appears
- [ ] 2nd screenshot → Final Warning dialog appears
- [ ] 3rd screenshot → Auto-submit dialog + quiz submits

### Web Testing
- [ ] Browser enters fullscreen mode
- [ ] Watermark visible (user email + timestamp)
- [ ] Switch tab → Warning dialog appears
- [ ] Switch tab again → Auto-submit dialog + quiz submits
- [ ] Exit fullscreen → Warning dialog appears
- [ ] Minimize window → Warning dialog appears

---

## ⚙️ Configuration Options

### Change Strike Limits
Edit `lib/core/services/quiz_security_service.dart`:

```dart
// Line ~125 - Mobile screenshots
if (_screenshotCount >= 3) {  // Change to 2, 4, 5, etc.
  onAutoSubmit?.call();
}

// Line ~166 - Web tab switching
if (_tabSwitchCount >= 2) {  // Change to 1, 3, etc.
  onAutoSubmit?.call();
}
```

### Disable Watermark on Web
Edit `lib/features/user/screens/quiz_taking_screen.dart`:

```dart
QuizSecurityOverlay(
  userIdentifier: userEmail,
  showWatermark: false,  // Set to false
  child: Scaffold(...)
)
```

### Custom Warning Messages
Edit warning dialog messages in `quiz_taking_screen.dart`:
- `_showFirstWarning()` - Line ~111
- `_showSecondWarning()` - Line ~123
- `_handleAutoSubmit()` - Line ~136
- `_showTabSwitchWarning()` - Line ~152

---

## 🐛 Troubleshooting

### "Method channel not implemented" error
→ Native code not integrated. Complete steps 2 and 3 above.

### Screenshots not blocked on Android
→ Verify FLAG_SECURE is set in MainActivity.kt
→ Test on real device (emulator may not enforce)

### Fullscreen not working on Web
→ Fullscreen requires user interaction (can't auto-trigger)
→ Try different browser (Chrome recommended)

### Build errors
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📚 Additional Resources

See `QUIZ_SECURITY_IMPLEMENTATION.md` for:
- Detailed implementation guide
- Platform-specific notes
- Security best practices
- Advanced customization options

---

## ✨ Summary

**Status:** ✅ Implementation complete
**Integration:** ✅ quiz_taking_screen.dart fully integrated
**Testing Required:** Yes - native code integration needed
**Dependencies:** intl: ^0.18.0 (add to pubspec.yaml)

The security system is production-ready once native code is integrated and tested on all platforms.

---

**Last Updated:** December 2024
**Version:** 1.0.0
