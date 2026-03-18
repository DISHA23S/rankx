# Web Password Reset - PKCE Error Fix

## ❌ Error Fixed

```
AuthException(message: Code verifier could not be found in local storage., statusCode: null, code: null)
```

## 🔍 Root Cause

The error occurred because we were trying to **manually exchange** the auth code using `exchangeCodeForSession()`. This method requires a **PKCE verifier** that should be stored in local storage when the auth flow is initiated.

**Problem:** When a user clicks a password reset link from their email:
- The link opens in a new browser tab/session
- No PKCE verifier exists in local storage (because the flow wasn't initiated from this browser)
- Manual code exchange fails with "Code verifier could not be found"

## ✅ Solution

**Stop manually exchanging codes.** Let Supabase handle it automatically!

Supabase's SDK has a built-in URL listener that:
1. Automatically detects auth URLs with `#access_token` or `#type=recovery`
2. Processes the auth fragments without needing PKCE verifier
3. Establishes the session automatically
4. Fires auth state change events

### What Changed:

#### 1. **Deep Link Handler** (`lib/main.dart`)
**Before:**
```dart
// ❌ This causes PKCE error
await Supabase.instance.client.auth.exchangeCodeForSession(code);
```

**After:**
```dart
// ✅ Just navigate - Supabase handles the rest
debugPrint('Navigating to reset password screen - Supabase will handle auth');
AppRouter.router.go(AppRoutes.passwordReset);
```

#### 2. **Initial URL Check** (`lib/main.dart`)
Added `_checkInitialUrl()` method that:
- Checks if app opened with auth URL fragment
- Lets Supabase process it automatically
- Navigates to reset screen after delay

#### 3. **Session Retry Logic** (`reset_password_screen.dart`)
- Increased max retries from 5 to 15
- Increased delay between retries (400ms per attempt)
- Auth state listener catches session when Supabase establishes it

## 🧪 How It Works Now

### Password Reset Flow (Web):

1. **User clicks "Forgot Password"**
   - Email sent with link: `https://yourdomain.com/reset-password#access_token=XYZ&type=recovery`

2. **User clicks link in email**
   - Browser opens the URL
   - Supabase SDK detects the hash fragment

3. **Supabase processes auth automatically**
   - Parses the `access_token` from URL hash
   - Establishes session without PKCE verifier
   - Fires `onAuthStateChange` event

4. **App responds**
   - `_checkInitialUrl()` detects reset password URL
   - Navigates to reset screen
   - Auth state listener detects session
   - Reset form appears

## 🚀 Testing

### Test on Web:
```bash
flutter run -d chrome --web-port 3000
```

1. Click "Forgot Password"
2. Enter email
3. Check email and click reset link
4. Should now work without PKCE error!

### Expected Logs:
```
Initial URL: http://localhost:3000/reset-password#access_token=...
URL has fragment: access_token=...&type=recovery
Auth fragment detected - letting Supabase handle it
Navigating to reset password screen - Supabase will handle auth
Auth state changed - session now available
Session ready for password reset
```

## 🔧 Key Configuration

### Supabase Dashboard Settings:

**Authentication → URL Configuration → Redirect URLs:**
```
http://localhost:3000/reset-password
http://localhost:3000/*
https://yourdomain.com/reset-password
https://yourdomain.com/*
```

**Email Template (Reset Password):**
```
{{ .SiteURL }}/reset-password#access_token={{ .Token }}&type=recovery
```

Or use default:
```
{{ .ConfirmationURL }}
```

## ⚠️ Important Notes

1. **Don't manually exchange codes** for password reset flows
2. **Supabase auto-detects** auth URLs - just let it work
3. **Wait for session** - use retry mechanism or auth state listener
4. **Hash fragments** (`#access_token=...`) don't require PKCE verifier
5. **PKCE is for user-initiated flows** (login, signup) not email links

## 🐛 Troubleshooting

### Still seeing PKCE error?
- Clear browser cache and local storage
- Check Supabase email template format
- Verify redirect URLs in Supabase dashboard

### Session not establishing?
- Check browser console for Supabase errors
- Increase retry timeout
- Verify network connectivity

### Form not appearing?
- Check retry count hasn't exceeded max
- Verify auth state listener is firing
- Check for navigation errors

## 📚 Related Files

- [`lib/main.dart`](lib/main.dart) - Deep link handling, initial URL check
- [`lib/features/auth/screens/reset_password_screen.dart`](lib/features/auth/screens/reset_password_screen.dart) - Session retry logic
- [`web/index.html`](web/index.html) - Web initialization

---

**Status:** ✅ Fixed  
**Tested:** Web password reset now works without PKCE errors
