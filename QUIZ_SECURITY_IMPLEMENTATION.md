# Quiz Security Implementation Guide

## Overview
This document provides complete instructions for implementing quiz security features in your Flutter app. The security system includes:

### Mobile (Android & iOS)
- ✅ Fullscreen mode during quiz
- ✅ Screenshot detection and blocking
- ✅ 3-strike warning system
- ✅ Auto-submit on third violation

### Web
- ✅ Fullscreen mode
- ✅ Tab switching detection
- ✅ Window minimize/exit fullscreen detection
- ✅ 2-strike warning system
- ✅ Watermark overlay with user email and timestamp

---

## File Structure

All necessary files have been created:

```
lib/
  core/
    services/
      ✅ quiz_security_service.dart          # Main orchestration service
      ✅ screenshot_security_channel.dart    # Platform channel for native code
      ✅ web_quiz_security.dart             # Web-specific security (dart:html)
      ✅ web_quiz_security_stub.dart        # Stub for non-web platforms
    widgets/
      ✅ quiz_security_overlay.dart         # Watermark overlay and dialogs
  features/
    user/
      screens/
        ✅ quiz_taking_screen.dart           # Integrated with security

android/app/src/main/kotlin/com/example/quizapp/
  ✅ MainActivity_SECURITY_INTEGRATION.kt  # Android native implementation

ios/Runner/
  ✅ AppDelegate_SECURITY_INTEGRATION.swift # iOS native implementation
```

---

## Installation Steps

### 1. Add Dependencies to pubspec.yaml

The security implementation requires the `intl` package for date formatting in the watermark:

```yaml
dependencies:
  flutter:
    sdk: flutter
  # ... your other dependencies ...
  intl: ^0.18.0  # Add this line
```

Run:
```bash
flutter pub get
```

---

## 2. Android Native Integration

### Option A: Replace MainActivity (Recommended)

1. Navigate to: `android/app/src/main/kotlin/com/example/quizapp/MainActivity.kt`
2. Back up your existing file
3. Copy the contents from `MainActivity_SECURITY_INTEGRATION.kt` 
4. Replace the entire `MainActivity.kt` file

### Option B: Merge with Existing Code

If your MainActivity has custom code, merge the security code:

**Add imports:**
```kotlin
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.view.WindowManager
import io.flutter.plugin.common.MethodChannel
```

**Add class properties:**
```kotlin
private val CHANNEL = "com.example.quizapp/screenshot_security"
private var screenshotBlockingEnabled = false
private var screenshotReceiver: BroadcastReceiver? = null
private var methodChannel: MethodChannel? = null
```

**Add all methods from the security integration file**

### Verify Android Setup

After integration, rebuild:
```bash
flutter clean
flutter build apk --debug
```

---

## 3. iOS Native Integration

### Option A: Replace AppDelegate (Recommended)

1. Navigate to: `ios/Runner/AppDelegate.swift`
2. Back up your existing file
3. Copy the contents from `AppDelegate_SECURITY_INTEGRATION.swift`
4. Replace the entire `AppDelegate.swift` file

### Option B: Merge with Existing Code

**Add imports:**
```swift
import UIKit
import Flutter
```

**Add class properties:**
```swift
private let CHANNEL = "com.example.quizapp/screenshot_security"
private var screenshotChannel: FlutterMethodChannel?
```

**Add all methods from the security integration file**

### Verify iOS Setup

After integration, rebuild:
```bash
cd ios
pod install
cd ..
flutter build ios --debug
```

---

## 4. Testing the Implementation

### Testing on Android

1. Build and run on Android device:
   ```bash
   flutter run
   ```

2. Start a quiz and verify:
   - ✅ App enters fullscreen mode
   - ✅ Status bar and navigation bar are hidden
   - ✅ Screenshot attempts are blocked (screen goes black in screenshot)
   - ✅ If screenshot is captured, warning dialog appears

3. Take 3 screenshots to test:
   - 1st screenshot → "Warning #1" dialog
   - 2nd screenshot → "Final Warning" dialog
   - 3rd screenshot → "Quiz Submitted" dialog + auto-submit

### Testing on iOS

1. Build and run on iOS device/simulator:
   ```bash
   flutter run
   ```

2. Start a quiz and verify:
   - ✅ App enters fullscreen mode
   - ✅ Screenshot detection works (use Control+Shift+Command+S on simulator)
   - ⚠️  Note: iOS cannot block screenshots, only detect them

3. Take 3 screenshots to test the warning system

### Testing on Web

1. Run on Chrome:
   ```bash
   flutter run -d chrome
   ```

2. Start a quiz and verify:
   - ✅ Browser enters fullscreen mode (press F11 or click fullscreen button)
   - ✅ Watermark overlay visible with user email and timestamp
   - ✅ Switching tabs triggers warning
   - ✅ Exiting fullscreen triggers warning

3. Test tab switching:
   - Switch to another tab → 1st warning
   - Switch again → Auto-submit

---

## How It Works

### Security Flow

```
Quiz Starts
    ↓
Enable Security
    ├─ Mobile: Enter fullscreen + Setup screenshot detection
    └─ Web: Request fullscreen + Setup visibility detection
    ↓
Quiz In Progress
    ├─ Screenshot detected (Mobile) → Increment counter → Show warning
    ├─ Tab switch detected (Web) → Increment counter → Show warning
    └─ 3rd violation (Mobile) or 2nd violation (Web) → Auto-submit
    ↓
Quiz Ends
    ↓
Disable Security
    ├─ Mobile: Exit fullscreen + Remove listeners
    └─ Web: Exit fullscreen + Remove listeners
```

### Code Integration Points

The `quiz_taking_screen.dart` has been fully integrated:

1. **Initialization** (line ~87):
   ```dart
   _enableQuizSecurity();
   ```

2. **Disposal** (line ~54):
   ```dart
   @override
   void dispose() {
     _securityService.disableQuizSecurity();
     super.dispose();
   }
   ```

3. **UI Wrapper** (line ~228):
   ```dart
   return QuizSecurityOverlay(
     userIdentifier: userEmail,
     showWatermark: true,
     child: Scaffold(...)
   );
   ```

4. **Submit with security disable** (line ~447):
   ```dart
   Future<void> _submitQuiz({bool isAutoSubmit = false}) async {
     await _securityService.disableQuizSecurity();
     // ... submit logic
   }
   ```

---

## Platform-Specific Notes

### Android
- **FLAG_SECURE**: Prevents screenshots and screen recording
- **BroadcastReceiver**: Detects screenshot attempts (not 100% reliable)
- **MethodChannel**: Communication between Kotlin and Flutter

### iOS
- **No Screenshot Blocking**: iOS doesn't support preventing screenshots
- **Detection Only**: Uses `UIApplication.userDidTakeScreenshotNotification`
- **MethodChannel**: Communication between Swift and Flutter

### Web
- **Fullscreen API**: `document.documentElement.requestFullscreen()`
- **Visibility API**: `document.onVisibilityChange` and `window.onBlur`
- **Watermark**: Semi-transparent text overlay to discourage screenshots
- **Browser Limitations**: User can exit fullscreen with ESC key

---

## Customization

### Change Warning Messages

Edit the warning messages in `quiz_taking_screen.dart`:

```dart
void _showFirstWarning() {
  showDialog(
    context: context,
    builder: (context) => QuizSecurityWarningDialog(
      title: 'Custom Warning Title',
      message: 'Your custom warning message here.',
      onContinue: () => Navigator.of(context).pop(),
    ),
  );
}
```

### Adjust Strike Limits

In `quiz_security_service.dart`, modify the strike thresholds:

```dart
void handleScreenshotDetected() {
  _screenshotCount++;
  
  if (_screenshotCount == 1) {
    onFirstWarning?.call();
  } else if (_screenshotCount == 2) {
    onSecondWarning?.call();
  } else if (_screenshotCount >= 3) {  // Change this number
    onAutoSubmit?.call();
  }
}
```

### Disable Watermark on Web

In `quiz_taking_screen.dart`, set `showWatermark: false`:

```dart
return QuizSecurityOverlay(
  userIdentifier: userEmail,
  showWatermark: false,  // Disable watermark
  child: Scaffold(...)
);
```

---

## Troubleshooting

### Android: Screenshots not blocked
- Verify `FLAG_SECURE` is set in MainActivity
- Check device Android version (some manufacturers disable this)
- Test on real device (emulator may not enforce FLAG_SECURE)

### iOS: Screenshots not detected
- Verify NotificationCenter observer is registered
- Check that MethodChannel name matches exactly
- Test on real device (simulator screenshot detection may differ)

### Web: Fullscreen not working
- Fullscreen requires user gesture (button click)
- Check browser console for errors
- Some browsers block fullscreen in iframes
- Test in Chrome/Edge (best support)

### Flutter: "Method channel not implemented"
- Verify native code is properly integrated
- Run `flutter clean && flutter pub get`
- Rebuild the app completely
- Check channel name matches exactly: `com.example.quizapp/screenshot_security`

---

## Security Limitations

### Important Understanding

1. **Not 100% Foolproof**: No security system can completely prevent cheating
2. **Android FLAG_SECURE**: Can be bypassed on rooted devices
3. **iOS Screenshot**: Can only detect, not prevent
4. **Web Screenshots**: User can use external camera to photograph screen
5. **Purpose**: Deterrent, not absolute prevention

### Best Practices

- ✅ Combine with server-side validation
- ✅ Randomize question order
- ✅ Time limits on quizzes
- ✅ Monitor unusual patterns
- ✅ Use anti-cheating algorithms
- ✅ Proctoring for high-stakes exams

---

## Support

If you encounter issues:

1. Check error logs: `flutter run --verbose`
2. Verify all files are in correct locations
3. Ensure package name matches in native code
4. Rebuild completely: `flutter clean && flutter run`

---

## Summary

✅ **Completed Features:**
- Fullscreen mode on mobile and web
- Screenshot detection and blocking (Android)
- Screenshot detection (iOS)
- Tab switching detection (Web)
- 3-strike system (Mobile)
- 2-strike system (Web)
- Warning dialogs
- Auto-submit functionality
- Watermark overlay (Web)

✅ **Integrated Files:**
- QuizSecurityService
- ScreenshotSecurityChannel
- WebQuizSecurity
- QuizSecurityOverlay
- quiz_taking_screen.dart

📋 **Next Steps:**
1. Add `intl: ^0.18.0` to pubspec.yaml
2. Integrate Android native code (MainActivity.kt)
3. Integrate iOS native code (AppDelegate.swift)
4. Test on all platforms
5. Deploy and monitor

---

**Last Updated:** $(date)
**Version:** 1.0.0
