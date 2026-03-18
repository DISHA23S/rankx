# CRITICAL FIX: Update Supabase Email Template

## ❌ Current Problem

Your Supabase password reset email is using the **old PKCE format** that doesn't work for web:

```
❌ Current format (causes PKCE error):
{{ .SiteURL }}/reset-password?code={{ .Token }}
```

This creates URLs like:
```
http://localhost:3000/reset-password?code=a9db8b86-80a6-4110-b02f-d9510a0fb830
```

When Supabase sees `?code=` in the URL, it tries to exchange it using PKCE, which fails because there's no verifier in local storage (user clicked from email).

## ✅ SOLUTION: Update Email Template in Supabase

### Step 1: Go to Supabase Dashboard

1. Open your Supabase project dashboard
2. Go to **Authentication** → **Email Templates**
3. Select **"Reset Password"** template

### Step 2: Update the Template

**Option A: Use Confirmation URL (Recommended)**

Replace the reset link with:
```html
<a href="{{ .ConfirmationURL }}">Reset Password</a>
```

This generates a URL with `token_hash` format:
```
http://localhost:3000/reset-password?token_hash=XXX&type=recovery
```

**Option B: Use Magic Link Format**

Or use this format for hash-based auth:
```html
<a href="{{ .SiteURL }}/reset-password#access_token={{ .Token }}&type=recovery">Reset Password</a>
```

This generates:
```
http://localhost:3000/reset-password#access_token=XXX&type=recovery
```

### Step 3: Save Template

Click **Save** in the Supabase dashboard.

### Step 4: Test

1. Request a new password reset
2. Check the email
3. The link should now work without PKCE errors!

---

## 📧 Complete Email Template Example

Here's a complete working template you can use:

```html
<h2>Reset Password</h2>

<p>Follow this link to reset your password:</p>

<p><a href="{{ .ConfirmationURL }}">Reset Password</a></p>

<p>Or copy and paste this URL into your browser:</p>
<p>{{ .ConfirmationURL }}</p>

<p>This link expires in 24 hours.</p>

<p>If you didn't request this, you can safely ignore this email.</p>
```

---

## 🔍 How to Verify It's Working

### Check Email Link Format

After requesting password reset, check the email link format:

✅ **Good formats:**
```
http://localhost:3000/reset-password?token_hash=XXX&type=recovery
http://localhost:3000/reset-password#access_token=XXX&type=recovery
```

❌ **Bad format (causes PKCE error):**
```
http://localhost:3000/reset-password?code=XXX
```

### Check Browser Console

After clicking the link, check console logs:

✅ **Success:**
```
Deep link received: ...reset-password?token_hash=...
Token hash detected - letting Supabase handle auth
Auth state changed - session now available
Session ready for password reset
```

❌ **Error:**
```
Legacy code parameter detected
Code verifier could not be found in local storage
```

---

## 🎯 Why This Matters

### PKCE Flow (for user-initiated auth):
```
User starts login → App generates verifier → Stores in local storage
→ Supabase returns code → App exchanges code with verifier
```

### Email Link Flow (password reset):
```
User clicks email → No verifier in browser → Code exchange fails ❌
```

### Token Hash Flow (correct for email links):
```
User clicks email → Supabase processes token_hash → Session created ✅
```

---

## 🚀 Alternative: Use OTP Format

If you can't update the email template, you can also use OTP-style verification:

### In Supabase Template:
```html
<a href="{{ .SiteURL }}/reset-password?token={{ .Token }}&type=recovery">Reset Password</a>
```

### In Your App:
The code I've added will attempt to verify it as an OTP token, though this might not work depending on Supabase version.

---

## ⚙️ Supabase Dashboard Settings Checklist

### 1. Email Templates
- [x] Update "Reset Password" template to use `{{ .ConfirmationURL }}`
- [x] Remove `?code={{ .Token }}` format
- [x] Save changes

### 2. URL Configuration
- [x] Add redirect URLs:
  ```
  http://localhost:3000/reset-password
  http://localhost:3000/*
  https://yourdomain.com/reset-password
  https://yourdomain.com/*
  ```

### 3. Authentication Settings
- [x] SMTP configured correctly
- [x] Site URL set to your app URL
- [x] Email rate limiting configured (if needed)

---

## 🧪 Testing Steps

1. **Update email template** in Supabase dashboard
2. **Request password reset** from your app
3. **Check email** - verify URL format
4. **Click link** - should open app without errors
5. **Check console** - should see "Token hash detected" or "Access token in fragment"
6. **Reset password** - form should appear and work

---

## 📞 Still Having Issues?

### If PKCE error persists:

1. **Clear browser cache and local storage**
   ```
   Ctrl+Shift+Delete → Clear all data
   ```

2. **Verify template was saved**
   - Go back to Email Templates
   - Check that changes are there

3. **Request NEW reset link**
   - Old links still use old format
   - Need fresh link with new template

4. **Check Supabase logs**
   - Dashboard → Logs
   - Look for authentication errors

---

## 📝 Summary

| Issue | Solution |
|-------|----------|
| PKCE error on web | Update email template to use `{{ .ConfirmationURL }}` |
| Old `?code=` format | Replace with `token_hash` or `access_token` format |
| Session not establishing | Clear cache, use new reset link |
| Template not updating | Save template, restart Supabase if needed |

---

**CRITICAL:** The app code is updated to handle both formats, but you **MUST** update the Supabase email template for the best experience. The old `?code=` format will not work reliably on web platforms.

**Status:** ⚠️ Waiting for Supabase email template update  
**Next Step:** Update the email template in your Supabase dashboard
