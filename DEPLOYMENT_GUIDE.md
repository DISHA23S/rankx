# 🚀 Deployment Guide

## Pre-Deployment Checklist

### Code Quality
- [ ] All tests passing
- [ ] No lint errors (`flutter analyze`)
- [ ] Code formatted (`flutter format .`)
- [ ] Remove debug prints
- [ ] Error handling complete

### Supabase Configuration
- [ ] Database migration applied
- [ ] RLS policies verified
- [ ] Indexes created
- [ ] Backups configured
- [ ] Monitoring enabled

### App Configuration
- [ ] `.env` file configured
- [ ] App version updated (pubspec.yaml)
- [ ] App name correct
- [ ] Icons and splash screen configured
- [ ] Permissions set correctly

### Testing
- [ ] Auth flow tested
- [ ] Quiz taking tested
- [ ] Payment flow tested
- [ ] Error handling tested
- [ ] Performance benchmarked

---

## iOS Deployment

### Prerequisites
- Xcode 14+
- iOS 11.0+ support
- Apple Developer Account
- Valid Apple ID

### Steps

1. **Update Version**
   ```bash
   cd ios
   ```
   Edit `Runner/Info.plist`:
   ```xml
   <key>CFBundleShortVersionString</key>
   <string>1.0.0</string>
   ```

2. **Build for Production**
   ```bash
   flutter clean
   flutter pub get
   flutter build ios --release
   ```

3. **Archive in Xcode**
   ```bash
   open ios/Runner.xcworkspace
   ```
   - Select "Generic iOS Device"
   - Product → Archive
   - Click "Distribute App"

4. **Upload to App Store**
   - Choose "App Store Connect"
   - Fill metadata
   - Submit for review

### Key Files to Check
- `ios/Runner/Info.plist` - App permissions
- `ios/Podfile` - Pod dependencies
- `ios/Runner/Assets.xcassets` - App icons

---

## Android Deployment

### Prerequisites
- Android Studio
- Android SDK 21+
- Google Play Developer Account
- Keystore file (for signing)

### Steps

1. **Create Keystore**
   ```bash
   keytool -genkey -v -keystore ~/key.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias quizmaster-key
   ```

2. **Create Key Properties**
   Create `android/key.properties`:
   ```properties
   storePassword=<password>
   keyPassword=<password>
   keyAlias=quizmaster-key
   storeFile=/path/to/key.jks
   ```

3. **Update Build Gradle**
   Edit `android/app/build.gradle`:
   ```gradle
   android {
     ...
     signingConfigs {
       release {
         keyAlias keystoreProperties['keyAlias']
         keyPassword keystoreProperties['keyPassword']
         storeFile file(keystoreProperties['storeFile'])
         storePassword keystoreProperties['storePassword']
       }
     }
     buildTypes {
       release {
         signingConfig signingConfigs.release
       }
     }
   }
   ```

4. **Build APK**
   ```bash
   flutter build apk --release
   ```

5. **Build App Bundle**
   ```bash
   flutter build appbundle --release
   ```

6. **Upload to Play Store**
   - Open Google Play Console
   - Create Release
   - Upload AAB/APK
   - Add release notes
   - Submit for review

### Key Files to Check
- `android/app/build.gradle` - Version, signing
- `android/app/src/main/` - Permissions
- `android/app/src/main/ic_launcher.xml` - App icon

---

## Web Deployment (Optional)

### Build Web
```bash
flutter build web --release
```

### Deploy to Firebase Hosting
```bash
firebase deploy
```

### Deploy to Netlify
```bash
netlify deploy --prod --dir=build/web
```

---

## Post-Deployment

### Monitoring
- Set up error tracking (Firebase Crashlytics)
- Monitor performance
- Track user engagement
- Check crash reports

### Updates
- Plan future releases
- Schedule maintenance windows
- Version management strategy
- Rollback procedures

### Support
- Set up feedback channel
- Monitor reviews
- Handle user issues
- Gather analytics

---

## Release Notes Template

```markdown
## Version 1.0.0

### New Features
- OTP-based authentication
- Quiz taking with timer
- Results analytics
- Payment integration

### Bug Fixes
- Fixed UI alignment issues
- Improved error handling
- Better performance

### Known Issues
- None

### Requirements
- iOS 11.0+
- Android 5.0+
```

---

## Rollback Procedure

If issues occur after release:

1. **Immediate Actions**
   - Remove from stores if critical
   - Notify users
   - Document issue

2. **Investigation**
   - Review error logs
   - Identify root cause
   - Plan fix

3. **Hotfix Release**
   - Create hotfix branch
   - Fix issue
   - Test thoroughly
   - Release immediately

---

## Version Management

### Semantic Versioning
- **Major** (1.0.0) - Breaking changes
- **Minor** (1.1.0) - New features
- **Patch** (1.0.1) - Bug fixes

### Update pubspec.yaml
```yaml
version: 1.0.0+1
# format: version+buildNumber
```

---

## Performance Targets

- **App Size**: < 50MB (Android), < 30MB (iOS)
- **Load Time**: < 2 seconds
- **Quiz Load**: < 1 second
- **API Response**: < 500ms
- **Frame Rate**: 60 FPS

---

## Security Checklist

- [ ] No hardcoded secrets
- [ ] HTTPS for all API calls
- [ ] Supabase RLS enabled
- [ ] Input validation
- [ ] SQL injection prevention
- [ ] XSS prevention
- [ ] CSRF tokens
- [ ] Secure storage

---

## Beta Testing

### TestFlight (iOS)
1. Upload build to App Store Connect
2. Add testers' Apple IDs
3. Send TestFlight links
4. Gather feedback
5. Fix issues

### Google Play Internal Testing (Android)
1. Upload APK/AAB to Google Play
2. Create internal test release
3. Add tester emails
4. Send test links
5. Gather feedback

---

## App Store Optimization (ASO)

### iOS App Store
- **Icon**: 1024x1024px
- **Screenshots**: 5-10 images
- **Description**: Clear, concise
- **Keywords**: Relevant, searchable
- **Category**: Educational

### Google Play Store
- **Icon**: 512x512px
- **Screenshots**: 4-8 images
- **Description**: 4000 chars
- **Short Description**: 80 chars
- **Categories**: Education

---

## Marketing

### Pre-Launch
- [ ] Create landing page
- [ ] Set up social media
- [ ] Plan press release
- [ ] Contact influencers
- [ ] Prepare promo materials

### Launch Day
- [ ] Post on social media
- [ ] Send press release
- [ ] Email newsletter
- [ ] Ask for reviews
- [ ] Monitor feedback

### Post-Launch
- [ ] Engage with reviews
- [ ] Respond to feedback
- [ ] Plan next features
- [ ] Analyze metrics
- [ ] Plan updates

---

## Analytics Setup

### Firebase Analytics
```dart
import 'package:firebase_analytics/firebase_analytics.dart';

final analytics = FirebaseAnalytics.instance;

analytics.logEvent(
  name: 'quiz_completed',
  parameters: {
    'quiz_id': quizId,
    'score': score,
  },
);
```

### Monitoring Events
- App opens
- User signups
- Quiz attempts
- Payments
- Errors

---

## Support & Maintenance

### User Support Channels
- In-app feedback form
- Email support
- Help center/FAQ
- Social media

### Maintenance Schedule
- Regular backups
- Security updates
- Performance optimization
- Feature updates

### SLA Targets
- Critical bugs: Fix within 24 hours
- Major bugs: Fix within 1 week
- Minor bugs: Fix within 2 weeks
- Features: Plan quarterly

---

## Compliance

### Privacy
- [ ] Privacy Policy published
- [ ] GDPR compliant
- [ ] Data retention policy
- [ ] User consent collected

### Terms
- [ ] Terms of Service
- [ ] Acceptable Use Policy
- [ ] Refund Policy
- [ ] License Agreement

### Accessibility
- [ ] WCAG 2.1 AA compliant
- [ ] Text contrast checked
- [ ] Screen reader tested
- [ ] Keyboard navigation

---

## Success Metrics

Track these after launch:

- **Downloads**: 1,000+ in first month
- **DAU**: Daily Active Users > 100
- **Retention**: Day 30 retention > 30%
- **Rating**: App Store rating > 4.5
- **Revenue**: Daily revenue > $100
- **Errors**: Crash rate < 0.1%

---

## Common Issues

### iOS Issues
**"Invalid provisioning profile"**
- Renew provisioning profiles
- Check team ID
- Update certificates

### Android Issues
**"Signature does not match"**
- Use same keystore
- Check key alias
- Verify key password

### General Issues
**"App rejected by store"**
- Review store guidelines
- Check screenshots
- Verify metadata
- Fix policy issues

---

## Resources

- [Flutter Deployment](https://flutter.dev/docs/deployment)
- [App Store Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Google Play Policies](https://play.google.com/about/developer-content-policy/)
- [Supabase Deployment](https://supabase.com/docs/guides/deployment)

---

## Quick Deployment Checklist

```bash
# 1. Clean build
flutter clean
flutter pub get

# 2. Run tests
flutter test

# 3. Analyze code
flutter analyze

# 4. Format code
flutter format .

# 5. Build
flutter build apk --release
flutter build ios --release

# 6. Version bump
# Edit pubspec.yaml

# 7. Commit
git add .
git commit -m "Release v1.0.0"
git tag v1.0.0
```

---

**Deployment Ready? You're all set to go live! 🚀**
