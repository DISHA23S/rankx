# QuizMaster - Setup Guide

## 🚀 Quick Start Setup

### Step 1: Prerequisites
- Flutter 3.x+ installed
- Xcode (macOS/iOS development)
- Android Studio (Android development)
- Supabase account

### Step 2: Project Setup

1. **Clone or create the project**
   ```bash
   cd quizapp
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code (for Hive, etc.)**
   ```bash
   flutter pub run build_runner build
   ```

### Step 3: Supabase Configuration

1. **Create a Supabase Project**
   - Go to https://supabase.com
   - Click "New Project"
   - Fill in project details
   - Wait for project to initialize

2. **Get Your Credentials**
   - Go to Settings → API
   - Copy your `Project URL` and `Anon Key`

3. **Update .env file**
   ```
   SUPABASE_URL=https://[your-project-ref].supabase.co
   SUPABASE_ANON_KEY=your-anon-key-here
   ```

4. **Run Database Migration**
   - Go to SQL Editor in Supabase
   - Click "New Query"
   - Copy all SQL from `supabase/migrations/schema.sql`
   - Paste and execute

### Step 4: Firebase Setup (Optional for Notifications)

If you want to add push notifications:

1. **Android Setup**
   - Download google-services.json from Firebase Console
   - Place in `android/app/`

2. **iOS Setup**
   - Download GoogleService-Info.plist
   - Add to Xcode project

### Step 5: Run the App

**iOS:**
```bash
flutter run -d macos
# or
flutter run -d ios
```

**Android:**
```bash
flutter run -d android
```

**Web (Development):**
```bash
flutter run -d chrome
```

## 🔧 Configuration Files

### pubspec.yaml
- Already configured with all dependencies
- No additional changes needed

### .env File
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### Main.dart
Already set up with:
- Supabase initialization
- GetX service configuration
- GoRouter setup
- Theme configuration

## 📋 Supabase Tables Created

After running the SQL migration:

1. **users** - User profiles and roles
2. **quizzes** - Quiz data
3. **questions** - Quiz questions
4. **answers** - Answer options
5. **user_answers** - User responses
6. **user_points** - Points tracking
7. **payments** - Payment records
8. **subscriptions** - Subscription data
9. **agreements** - Terms and conditions
10. **user_agreements** - Agreement acceptance tracking

All tables have RLS policies enabled for security.

## 🔐 Authentication Setup

### OTP Configuration

Supabase OTP is automatically configured. Make sure:
1. Email provider is enabled (default)
2. Phone provider can be enabled if needed
3. OTP expiry is set to 300 seconds (5 minutes)

### Test Credentials

Create test accounts:
1. Start the app
2. Go to login screen
3. Enter test email: `test@example.com`
4. Check Supabase email logs for OTP
5. Select role and complete registration

## 💾 Local Database (Hive)

For local caching:
1. Hive is already configured
2. Generate boxes: `flutter pub run build_runner build`
3. Can be used for offline quiz support

## 🎨 Customization

### Colors
Edit `lib/core/constants/app_colors.dart`:
```dart
static const Color primary = Color(0xFF6366F1);
```

### Spacing
Edit `lib/core/constants/app_spacing.dart`:
```dart
static const double md = 16.0;
```

### Strings & Constants
Edit `lib/core/constants/app_constants.dart`:
```dart
static const String appName = 'QuizMaster';
```

## 📱 Mobile Platform Configuration

### Android Minimum Version
- Set in `android/app/build.gradle`:
  ```gradle
  minSdkVersion 21
  ```

### iOS Minimum Version
- Set in `ios/Podfile`:
  ```ruby
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      flutter_additional_ios_build_settings(target)
      target.build_configurations.each do |config|
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
          '$(inherited)',
        ]
      end
    end
  end
  ```

## 🔗 Payment Gateway Integration

### For Razorpay (India)
1. Install razorpay_flutter
2. Add keys in payment_screen.dart
3. Follow Razorpay documentation

### For UPI
- Use upi_pay package
- Configure UPI apps in device settings

## 📊 Analytics Setup

### Get user performance data:
```dart
// In admin dashboard, fetch user analytics
final analytics = await quizService.getAdminQuizzes(adminId);
```

### Database queries example:
```sql
-- Quiz-wise user performance
SELECT 
  q.title,
  u.name,
  COUNT(ua.id) as total_attempted,
  SUM(CASE WHEN ua.is_correct THEN 1 ELSE 0 END) as correct_answers,
  ROUND(100.0 * SUM(CASE WHEN ua.is_correct THEN 1 ELSE 0 END) / 
    COUNT(ua.id), 2) as accuracy_percentage
FROM quizzes q
JOIN user_answers ua ON q.id = ua.quiz_id
JOIN users u ON ua.user_id = u.id
GROUP BY q.id, u.id;
```

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test
```

### Widget Tests
Tests are in `test/` directory

## 🚀 Deployment

### Build APK (Android)
```bash
flutter build apk --release
```

### Build App Bundle (Android)
```bash
flutter build appbundle --release
```

### Build IPA (iOS)
```bash
flutter build ios --release
```

## 📚 API Rate Limits

Supabase free tier:
- 50,000 API calls/month
- Realtime: 200 concurrent connections
- Storage: 1GB

For production, consider:
- Pro plan: $25/month
- Custom limits available

## 🐛 Debugging

### Enable Debug Logs
```dart
// In main.dart
flutter run --verbose
```

### Supabase Debug
```dart
Supabase.instance.client.auth.onAuthStateChange.listen((data) {
  print('Auth state: ${data.event}');
  print('User: ${data.session?.user.email}');
});
```

### Database Debug
Use Supabase dashboard to:
- Check table data
- Monitor RLS policies
- View function logs

## 📞 Support Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Supabase Documentation](https://supabase.com/docs)
- [GetX Documentation](https://github.com/jonataslaw/getx)
- [GoRouter Documentation](https://pub.dev/packages/go_router)

## ✅ Pre-Launch Checklist

- [ ] Environment variables set in .env
- [ ] Supabase project created and initialized
- [ ] Database migration completed
- [ ] Authentication working (OTP verified)
- [ ] Admin can create quizzes
- [ ] Users can take quizzes
- [ ] Payments configured
- [ ] Error handling tested
- [ ] Performance optimized
- [ ] UI tested on iOS and Android
- [ ] Terms & conditions added
- [ ] Privacy policy added

## 🎉 You're Ready!

The app is now fully configured and ready for development or deployment.

For any issues, check the troubleshooting section in IMPLEMENTATION_GUIDE.md
