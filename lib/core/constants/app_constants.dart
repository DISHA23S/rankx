class AppConstants {
  // App Info
  static const String appName = 'Rankx';
  static const String appVersion = '1.0.0';
  // Default admin credentials (for development/testing only)
  // NOTE: removed default admin credentials for security.
  
  // API Endpoints
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  
  // Database Tables
  static const String usersTable = 'users';
  static const String quizzesTable = 'quizzes';
  static const String questionsTable = 'questions';
  static const String answersTable = 'answers';
  static const String userAnswersTable = 'user_answers';
  static const String userPointsTable = 'user_points';
  static const String paymentsTable = 'payments';
  static const String subscriptionsTable = 'subscriptions';
  static const String subscriptionPlansTable = 'subscription_plans';
  static const String agreementsTable = 'agreements';
  static const String userAgreementsTable = 'user_agreements';
  
  // Roles
  static const String adminRole = 'admin';
  static const String userRole = 'user';
  
  // Payment Methods
  static const String paymentMethodUPI = 'upi';
  static const String paymentMethodCard = 'card';
  static const String paymentMethodWallet = 'wallet';
  static const String paymentMethodNetBanking = 'net_banking';
  
  // Subscription Plans
  static const String planDaily = 'daily';
  static const String planWeekly = 'weekly';
  static const String planMonthly = 'monthly';
  static const String planYearly = 'yearly';

  // Legacy hard-coded reward points (kept for backward compatibility)
  static const int planDailyPoints = 19;
  static const int planWeeklyPoints = 49;
  static const int planMonthlyPoints = 149;
  static const int planYearlyPoints = 365;
  
  // Payment Status
  static const String paymentPending = 'pending';
  static const String paymentCompleted = 'completed';
  static const String paymentFailed = 'failed';
  
  // Quiz Status
  static const String quizDraft = 'draft';
  static const String quizPublished = 'published';
  static const String quizArchived = 'archived';
  
  // Durations
  static const int otpExpirySeconds = 300; // 5 minutes
  static const int sessionTimeoutSeconds = 1800; // 30 minutes
  
  // Validation
  static const int minPasswordLength = 8;
  static const int maxQuestionLength = 500;
  static const int maxAnswerLength = 200;
  static const int minQuestionsPerQuiz = 1;
  static const int maxQuestionsPerQuiz = 100;
}
