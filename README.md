# 🎓 QuizMaster - Production Ready Quiz Application

A comprehensive, production-grade Flutter + Supabase quiz application with admin dashboard, OTP authentication, payment integration, and detailed analytics.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-blue?logo=dart)
![Supabase](https://img.shields.io/badge/Supabase-Latest-green)

## ✨ Features

### 🔐 Authentication & Security
- OTP-based Login (email/phone)
- Role-Based Access (Admin & User)
- Row-Level Security
- Session Management

### 👨‍💼 Admin Features
- Quiz Management (CRUD)
- Question & Answer Management
- User Analytics & Performance Tracking
- Payment Dashboard
- Agreement Management

### 👥 User Features
- Points System (Daily, Weekly, Total)
- Quiz Catalog with Filters
- Interactive Quiz Taking with Timer
- Results Analysis with Charts
- 4 Payment Methods (Card, UPI, Wallet, Net Banking)
- Subscription Plans (Daily, Weekly, Monthly, Yearly)

## 🚀 Quick Start

### Prerequisites
- Flutter 3.x+
- Supabase Account
- Xcode/Android Studio

### Installation

1. **Clone & Setup**
   ```bash
   cd quizapp
   flutter pub get
   ```

2. **Configure Supabase** - Update `.env`:
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```

3. **Run Database Migration**
   - Copy SQL from `supabase/migrations/schema.sql`
   - Execute in Supabase SQL Editor

4. **Run App**
   ```bash
   flutter run
   ```

## 📚 Documentation

- **[IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)** - Complete feature documentation
- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Detailed setup instructions
- **[API_DOCUMENTATION.md](API_DOCUMENTATION.md)** - API reference

## 🏗️ Architecture

**Technology Stack:**
- Flutter 3.x
- GetX (State Management)
- GoRouter (Navigation)
- Supabase (Backend & Auth)
- PostgreSQL (Database)
- FL Chart (Analytics)

**Key Features:**
- Clean Architecture
- RLS Security
- Real-time Updates
- Responsive Design
- Dark Mode Support

## 📊 Key Tables

- `users` - User profiles
- `quizzes` - Quiz data
- `questions` - Questions
- `answers` - Answer options
- `user_answers` - User responses
- `payments` - Payment records
- `subscriptions` - Subscription data
- `user_points` - Points tracking

## 🔒 Security

✅ Row-Level Security (RLS)
✅ OTP Authentication
✅ Token-based API Access
✅ Encrypted Data at Rest & in Transit

## 📱 Deployment

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## 📄 License

MIT License

---

**Master Your Knowledge with QuizMaster! 🎓**

