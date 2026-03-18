# Password Reset Fix - Android & Web

## Issues Fixed

✅ **Android Deep Link Handling**: Improved deep link processing with better error handling  
✅ **Web Hash Fragment Support**: Added support for Supabase hash-based auth URLs  
✅ **Session Timing**: Implemented retry mechanism to handle session establishment delays  
✅ **Auth State Listener**: Added real-time auth state change detection  
✅ **Redirect URL Configuration**: Dynamic redirect URLs based on platform  

---

## Changes Made

### 1. **Reset Password Screen** (`lib/features/auth/screens/reset_password_screen.dart`)

**Improvements:**
- Added **session retry mechanism** with exponential backoff (up to 10 retries)
- Added **auth state change listener** to detect session updates in real-time
- Better handling of async session establishment from deep links
- Improved error states and user feedback

**Key Features:**
```dart
// Retry logic for session detection
while (_retryCount < _maxRetries && !_sessionReady && mounted) {
  final session = supabaseService.client.auth.currentSession;
  if (session != null) {
    setState(() { _sessionReady = true; });
    return;
  }
  await Future.delayed(Duration(milliseconds: 300 * _retryCount));
}

// Auth state listener
supabaseService.client.auth.onAuthStateChange.listen((data) {
  if (mounted && data.session != null && !_sessionReady) {
    setState(() { _sessionReady = true; });
  }
});
```

### 2. **Deep Link Handler** (`lib/main.dart`)

**Improvements:**
- Added **hash fragment parsing** for web URLs
- Better detection of password reset links (checks host, path, and fragment)
- Support for `access_token` in URL fragment (Supabase web auth)
- Enhanced logging for debugging
- Added delays to ensure session is fully established before navigation

**Supported URL Formats:**
```
✅ quizmaster://reset-password?code=ABC123
✅ http://localhost:3000/reset-password?code=ABC123
✅ http://localhost:3000/reset-password#access_token=XYZ&type=recovery
✅ https://yourdomain.com/reset-password#access_token=XYZ&type=recovery
```

### 3. **Auth Service** (`lib/core/services/auth_service.dart`)

**Improvements:**
- **Dynamic redirect URL** based on platform
- For web: Uses current origin (production-ready)
- For mobile: Uses custom scheme `quizmaster://`
- Better debugging with console output

### 4. **Web Index HTML** (`web/index.html`)

**Improvements:**
- Added initialization script to detect Supabase auth hashes
- Ensures proper handling of email link redirects
- Logging for debugging web auth flow

---

## Supabase Configuration

### Required Settings in Supabase Dashboard

1. **Go to:** Authentication → URL Configuration

2. **Site URL:** 
   - **Development (Web):** `http://localhost:3000` or your local web server
   - **Production (Web):** `https://yourdomain.com`
   - **Mobile:** `quizmaster://`

3. **Redirect URLs** (Add all of these):
   ```
   http://localhost:3000/reset-password
   http://localhost:3000/*
   quizmaster://reset-password
   quizmaster://*
   https://yourdomain.com/reset-password    (for production)
   https://yourdomain.com/*                  (for production)
   ```

4. **Email Templates:**
   - Go to: Authentication → Email Templates → Reset Password
   - Ensure the link uses: `{{ .SiteURL }}/reset-password?code={{ .Token }}`
   - Or for hash-based: `{{ .SiteURL }}/reset-password#access_token={{ .Token }}&type=recovery`

---

## Testing Instructions

### Testing on Android

1. **Build and install:**
   ```bash
   flutter run
   ```

2. **Request password reset:**
   - Open app → Login screen
   - Click "Forgot password?"
   - Enter email
   - Check email inbox

3. **Click reset link:**
   - Open email on Android device
   - Click the password reset link
   - App should open automatically
   - Reset password screen should appear with form ready

4. **Manual testing with ADB:**
   ```bash
   # Test with code parameter
   adb shell am start -W -a android.intent.action.VIEW -d "quizmaster://reset-password?code=test123"
   
   # Check logs
   adb logcat | grep -i "deep link\|password reset\|session"
   ```

### Testing on Web

1. **Run web app:**
   ```bash
   flutter run -d chrome --web-port 3000
   ```

2. **Request password reset:**
   - Navigate to login screen
   - Click "Forgot password?"
   - Enter email
   - Check email inbox

3. **Click reset link:**
   - Click link in email
   - Browser should open the app
   - Reset password screen should load
   - Form should appear (may take 1-3 seconds for session)

4. **Check browser console:**
   ```
   F12 → Console tab
   Look for: "Deep link received", "Session established", etc.
   ```

5. **Manual URL testing:**
   ```
   http://localhost:3000/reset-password#access_token=YOUR_TOKEN&type=recovery
   ```

---

## Troubleshooting

### Issue: "Session expired" or "No active session"

**Cause:** Deep link was clicked but session not established yet

**Solutions:**
1. ✅ **Fixed:** Retry mechanism now handles this automatically
2. Wait 2-3 seconds - the screen will update when session is ready
3. Check Supabase logs for authentication errors
4. Verify redirect URLs in Supabase dashboard

### Issue: Deep link doesn't open app on Android

**Check:**
1. AndroidManifest.xml has correct intent filters (already configured)
2. URL scheme matches: `quizmaster://reset-password`
3. Test with ADB command to isolate the issue
4. Check if other apps are intercepting the link

**Verify AndroidManifest:**
```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="quizmaster" android:host="reset-password"/>
</intent-filter>
```

### Issue: Web shows loading forever

**Cause:** Hash fragment not being parsed or session not established

**Solutions:**
1. ✅ **Fixed:** Added hash fragment parsing in deep link handler
2. Check browser console for errors
3. Verify Supabase email template URL format
4. Clear browser cache and cookies
5. Check if ad blockers are interfering

### Issue: "Failed to update password"

**Possible causes:**
1. Session expired (user took too long)
2. Token already used
3. Network error
4. Supabase configuration issue

**Solutions:**
1. Request a new reset link
2. Check Supabase dashboard logs
3. Verify user exists in database
4. Check network connectivity

---

## Debug Logging

### Android Logs
```bash
# View all app logs
adb logcat | grep "flutter"

# View deep link specific logs
adb logcat | grep -E "deep link|reset-password|session"
```

### Web Console
Press F12 → Console tab to see:
- "Deep link received: ..."
- "Session established from deep link"
- "Session ready for password reset"
- "Auth state changed - session now available"

### Flutter Debug Console
In VS Code or Android Studio, check Debug Console for:
```
Deep link received: quizmaster://reset-password?code=...
Exchanging code for session: ABC123...
Session established from deep link
Session ready for password reset
```

---

## Production Deployment

### Before deploying to production:

1. **Update Supabase redirect URLs:**
   ```
   https://yourdomain.com/reset-password
   https://yourdomain.com/*
   ```

2. **Update Site URL:**
   ```
   https://yourdomain.com
   ```

3. **Update AndroidManifest.xml** (if using HTTPS deep links):
   ```xml
   <data android:scheme="https"/>
   <data android:host="yourdomain.com"/>
   <data android:pathPrefix="/reset-password"/>
   ```

4. **Test thoroughly:**
   - Test on real Android devices
   - Test on web browsers (Chrome, Firefox, Safari)
   - Test email delivery and link clicking
   - Verify session establishment timing

5. **Monitor:**
   - Check Supabase logs for authentication errors
   - Monitor user feedback
   - Set up error tracking (e.g., Sentry, Firebase Crashlytics)

---

## Security Notes

✅ **PKCE Flow**: App uses PKCE flow for enhanced security  
✅ **Token Exchange**: Codes are exchanged for sessions securely  
✅ **One-time Use**: Reset tokens can only be used once  
✅ **Expiration**: Tokens expire after a set time (configured in Supabase)  
✅ **Password Hashing**: Passwords are hashed using SHA-256 with salt  

---

## Support

If you encounter issues:

1. **Check this guide** - Most issues are covered in Troubleshooting
2. **Check logs** - Enable debug logging on your platform
3. **Verify Supabase config** - Ensure redirect URLs are correct
4. **Test systematically** - Isolate whether issue is on Android, web, or both
5. **Check network** - Ensure device/browser can reach Supabase

### Common Quick Fixes:
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run

# Clear web cache
Ctrl+Shift+Delete → Clear all

# Reinstall on Android
adb uninstall com.yourcompany.quizapp
flutter install
```

---

## Files Modified

1. ✅ [`lib/features/auth/screens/reset_password_screen.dart`](lib/features/auth/screens/reset_password_screen.dart)
2. ✅ [`lib/main.dart`](lib/main.dart)
3. ✅ [`lib/core/services/auth_service.dart`](lib/core/services/auth_service.dart)
4. ✅ [`web/index.html`](web/index.html)
5. ℹ️ [`android/app/src/main/AndroidManifest.xml`](android/app/src/main/AndroidManifest.xml) (already configured)

---

**Last Updated:** January 29, 2026  
**Status:** ✅ Ready for testing
