# QuizMaster - Flutter + Supabase Quiz Application

A production-ready quiz application built with Flutter and Supabase, featuring role-based access (Admin & User), OTP authentication, payment integration, and comprehensive analytics.

## 🎯 Features

### Authentication
- ✅ OTP-based login (email/phone)
- ✅ Role-based registration (Admin/User)
- ✅ Session management
- ✅ Secure authentication with Supabase Auth

### Admin Features
- ✅ Quiz creation and management (CRUD)
- ✅ Question management with multiple choice options
- ✅ Answer management with explanations
- ✅ Quiz publishing and archiving
- ✅ Quiz categories and difficulty levels
- ✅ User performance analytics
- ✅ Payment tracking and reports
- ✅ Agreement management

### User Features
- ✅ Points system (Daily, Weekly, Total)
- ✅ Browse and filter quizzes
- ✅ Interactive quiz taking with timer
- ✅ Auto-submit on timeout
- ✅ Real-time progress tracking
- ✅ Detailed result analysis
- ✅ Performance charts (Pie/Bar)
- ✅ Multiple payment methods (UPI, Card, Wallet, Net Banking)
- ✅ Subscription plans (Daily, Weekly, Monthly, Yearly)

## 🏗️ Architecture

### Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── app_colors.dart
│   │   └── app_spacing.dart
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── quiz_model.dart
│   │   ├── question_model.dart
│   │   ├── payment_model.dart
│   │   ├── points_model.dart
│   │   └── agreement_model.dart
│   ├── services/
│   │   ├── supabase_service.dart
│   │   └── auth_service.dart
│   ├── routes/
│   │   └── app_router.dart
│   ├── theme/
│   │   └── app_theme.dart
│   ├── utils/
│   │   └── validators.dart
│   └── widgets/
│       └── app_widgets.dart
├── features/
│   ├── auth/
│   │   └── screens/
│   │       ├── login_screen.dart
│   │       ├── otp_verification_screen.dart
│   │       └── role_selection_screen.dart
│   ├── admin/
│   │   └── screens/
│   │       ├── admin_dashboard_screen.dart
│   │       ├── quiz_management_screen.dart
│   │       └── quiz_create_screen.dart
│   └── user/
│       └── screens/
│           ├── user_home_screen.dart
│           ├── quiz_list_screen.dart
│           ├── quiz_taking_screen.dart
│           ├── quiz_result_screen.dart
│           └── payment_screen.dart
└── main.dart

supabase/
└── migrations/
    └── schema.sql
```

### Technology Stack

**Frontend:**
- Flutter 3.x
- GetX for state management
- GoRouter for navigation
- FL Chart for analytics
- Cached Network Image for image optimization

**Backend:**
- Supabase (PostgreSQL)
- Supabase Auth (OTP)
- Supabase Realtime
- Row Level Security (RLS)

## 🚀 Getting Started

### Prerequisites

1. Flutter SDK 3.x or higher
2. Supabase account
3. Xcode (for iOS) / Android Studio (for Android)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd quizapp
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Setup Environment Variables**
   
   Update `.env` file with your Supabase credentials:
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```

4. **Setup Supabase Database**
   
   - Copy the SQL from `supabase/migrations/schema.sql`
   - Run it in your Supabase SQL editor
   - This will create all tables with RLS policies

5. **Run the app**
   ```bash
   flutter run
   ```

## 📱 Usage Guide

### For Admins

1. **Login with Admin Role**
   - Enter email and receive OTP
   - Verify OTP
   - Select "Admin" role during registration

2. **Create Quiz**
   - Go to Admin Dashboard → Create New Quiz
   - Add quiz details (title, category, duration)
   - Add questions and answers
   - Set correct answer and explanation
   - Publish quiz

3. **Manage Quizzes**
   - View all quizzes in Quiz Management
   - Edit or delete quizzes
   - Archive published quizzes

4. **View Analytics**
   - Check user performance
   - View quiz-wise scores
   - Track accuracy and time taken

### For Users

1. **Login with User Role**
   - Enter email and receive OTP
   - Verify OTP
   - Select "User" role during registration

2. **Take Quiz**
   - Go to Quizzes section
   - Browse available quizzes
   - For paid quizzes, complete payment first
   - Answer all questions within time limit
   - Auto-submit on timeout

3. **View Results**
   - See score and accuracy percentage
   - Review time spent
   - View performance charts
   - Option to retake quiz

## 🔐 Security Features

### Row Level Security (RLS)
- Users can only access their own data
- Admins can manage only their quizzes
- Automatic enforcement at database level

### Authentication
- OTP-based secure login
- Session management
- Token-based API access

### Data Protection
- End-to-end encryption for sensitive data
- Secure password hashing
- HTTPS for all communications

## 💳 Payment Integration

### Supported Methods
- UPI
- Credit/Debit Card
- Wallet
- Net Banking

### Subscription Plans
- Daily (₹9.99)
- Weekly (₹49.99)
- Monthly (₹149.99)
- Yearly (₹999.99)

## 📊 Database Schema

### Key Tables
- `users` - User profiles and roles
- `quizzes` - Quiz metadata
- `questions` - Quiz questions
- `answers` - Answer options
- `user_answers` - User responses
- `payments` - Payment records
- `subscriptions` - User subscriptions
- `user_points` - Points tracking
- `agreements` - Terms and conditions

## 🎨 UI/UX Features

- **Dark Mode Support** - System-aware theme
- **Responsive Design** - Works on all screen sizes
- **Smooth Animations** - Enhanced user experience
- **Loading States** - User feedback
- **Error Handling** - Graceful error messages
- **Real-time Progress** - Live quiz progress tracking

## 📈 Performance Optimization

- Image caching with `cached_network_image`
- Lazy loading of quiz lists
- Efficient database queries with indexes
- Pagination support for large datasets
- RLS for server-side filtering

## 🔄 State Management

Using GetX for:
- User authentication state
- Quiz data management
- Points tracking
- Navigation

## 📝 API Documentation

### Key Endpoints

All endpoints are handled through Supabase client with RLS policies:

**Users:**
- Create user profile
- Update profile
- Get user data

**Quizzes:**
- Create quiz (admin only)
- Update quiz
- Delete quiz
- Get published quizzes
- Get quiz details with questions

**Payments:**
- Create payment record
- Update payment status
- Get user payment history

**Points:**
- Update user points
- Get user points
- Track daily/weekly/total

## 🐛 Troubleshooting

### Common Issues

1. **Supabase Connection Error**
   - Verify `.env` file has correct credentials
   - Check internet connection
   - Ensure Supabase project is active

2. **OTP Not Received**
   - Check email spam folder
   - Verify email address is correct
   - Wait 5 minutes for resend

3. **Payment Failed**
   - Check payment method balance
   - Verify correct details
   - Try alternative payment method

## 📚 Dependencies

See `pubspec.yaml` for complete list. Key dependencies:

- `supabase_flutter: ^2.8.0`
- `get: ^4.6.6`
- `go_router: ^14.0.0`
- `fl_chart: ^0.70.0`
- `razorpay_flutter: ^1.3.7`

## 📄 License

This project is licensed under the MIT License - see LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📧 Support

For support, email support@quizmaster.com or open an issue in the repository.

## 🚀 Deployment

### iOS
```bash
flutter build ios --release
```

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

## 📊 Future Enhancements

- [ ] Leaderboard system
- [ ] Social sharing features
- [ ] Advanced analytics dashboard
- [ ] AI-powered question generation
- [ ] Video explanations
- [ ] Offline quiz mode
- [ ] Push notifications
- [ ] Quiz scheduling

---

**QuizMaster** - Master Your Knowledge! 🎓
