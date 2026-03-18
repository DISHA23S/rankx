# Password Reset Setup Guide

This guide explains how to configure password reset functionality properly in your RankX app.

## Issues Fixed

1. ✅ **UI Layout Issue**: Login and Create Account buttons were being cut off on small screens
2. ✅ **Password Reset Deep Link**: Blank white page when opening reset password link from email

## Supabase Configuration

### 1. Configure Site URL and Redirect URLs

In your Supabase Dashboard:

1. Go to **Authentication** → **URL Configuration**
2. Set **Site URL** to one of:
   - For development: `http://localhost:3000`
   - For production: `https://yourdomain.com`
   - For mobile app: `quizmaster://reset-password`

3. Add **Redirect URLs** (all of these):
   ```
   http://localhost:3000/reset-password
   http://localhost:3000/*
   quizmaster://reset-password
   quizmaster://*
   https://yourdomain.com/reset-password (if you have a web domain)
   https://yourdomain.com/*
   ```

### 2. Configure Email Templates

In Supabase Dashboard:

1. Go to **Authentication** → **Email Templates**
2. Click on **Reset Password** template
3. Update the reset link to use your custom URL scheme:

**For Mobile App:**
```html
<a href="quizmaster://reset-password?code={{ .TokenHash }}">Reset Password</a>
```

**Or if you have a web domain that redirects to the app:**
```html
<a href="https://yourdomain.com/reset-password?code={{ .TokenHash }}">Reset Password</a>
```

### 3. Android Deep Link Configuration

The AndroidManifest.xml has been updated to handle both custom scheme and HTTPS deep links:

**Custom Scheme** (already configured):
- `quizmaster://reset-password`

**HTTPS Deep Link** (update the host):
- Replace `quizmaster.com` with your actual domain in [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml#L25)
- If you don't have a domain, you can remove the HTTPS intent filter

## How It Works

### Password Reset Flow

1. **User requests password reset**
   - User enters email on forgot password screen
   - Supabase sends email with reset link

2. **User clicks reset link in email**
   - Link format: `quizmaster://reset-password?code=XXXXX`
   - Android opens the app via deep link
   - App listens for the deep link in [main.dart](lib/main.dart)

3. **App handles the deep link**
   - Extracts the `code` parameter from the URL
   - Exchanges code for a session using `exchangeCodeForSession()`
   - Navigates to the reset password screen

4. **User resets password**
   - Reset password screen checks if session is active
   - If session is ready, shows the password reset form
   - User enters new password and submits
   - Password is updated in Supabase

## Testing

### Testing on Android Device/Emulator

1. **Build and install the app:**
   ```bash
   flutter run
   ```

2. **Request password reset:**
   - Open the app
   - Click "Forgot Password"
   - Enter your email
   - Check your email inbox

3. **Test the deep link:**
   - Open the reset password email on your device
   - Click the reset password link
   - App should open and navigate to reset password screen
   - Enter new password and submit

### Manual Deep Link Testing

You can test deep links manually using ADB:

```bash
# Test custom scheme
adb shell am start -W -a android.intent.action.VIEW -d "quizmaster://reset-password?code=test123"

# Test HTTPS (if configured)
adb shell am start -W -a android.intent.action.VIEW -d "https://yourdomain.com/reset-password?code=test123"
```

## Troubleshooting

### Issue: Still seeing blank white page

**Solution:**
1. Check Supabase Dashboard → Authentication → URL Configuration
2. Ensure `quizmaster://reset-password` is in the Redirect URLs list
3. Ensure `quizmaster://*` is in the Redirect URLs list
4. Update the email template to use the correct URL scheme

### Issue: Deep link not opening the app

**Solution:**
1. Uninstall and reinstall the app
2. Check that AndroidManifest.xml has the intent filter
3. Test with manual ADB command to verify the deep link is registered

### Issue: Session not found error

**Solution:**
1. Check that the `code` parameter is being passed in the URL
2. Verify that `exchangeCodeForSession()` is being called before navigating
3. Check Supabase logs for any authentication errors

### Issue: Buttons cut off on small screens

**Solution:**
- This has been fixed by changing the layout from `Expanded` to `Flexible` widgets
- The auth start screen now properly adapts to all screen sizes

## Files Modified

1. [lib/main.dart](lib/main.dart) - Added deep link handling
2. [lib/features/auth/screens/reset_password_screen.dart](lib/features/auth/screens/reset_password_screen.dart) - Improved reset flow
3. [lib/features/auth/screens/auth_start_screen.dart](lib/features/auth/screens/auth_start_screen.dart) - Fixed UI layout
4. [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml) - Added deep link intent filters

## Additional Notes

- The app uses PKCE flow for better security
- Deep links work both when the app is open and when it's closed
- The reset password screen shows a loading state while verifying the session
- Users are redirected to login after successfully resetting their password

## Support

If you encounter any issues, check:
1. Supabase Dashboard logs
2. Flutter console output for debug messages
3. Android logcat for deep link events
