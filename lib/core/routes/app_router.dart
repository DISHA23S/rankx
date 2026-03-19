import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/terms_agreement_screen.dart';
import '../../features/auth/screens/auth_start_screen.dart';
import '../../features/auth/screens/user_login_screen.dart';
import '../../features/auth/screens/admin_login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/otp_verification_screen.dart';
import '../../features/auth/screens/role_selection_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/quiz_management_screen.dart';
import '../../features/admin/screens/quiz_create_screen.dart';
import '../../features/admin/screens/user_management_screen.dart';
import '../../features/admin/screens/subscription_management_screen.dart';
import '../../features/admin/screens/admin_payment_tracking_screen.dart';
import '../../features/admin/screens/admin_agreements_settings_screen.dart';
import '../../features/user/screens/user_home_screen.dart';
import '../../features/user/screens/quiz_list_screen.dart';
import '../../features/user/screens/quiz_taking_screen.dart';
import '../../features/user/screens/quiz_result_screen.dart';
import '../../features/user/screens/payment_screen.dart';
import '../../features/user/screens/user_profile_screen.dart';
import '../../features/user/screens/settings_screen.dart';
import '../../features/user/screens/help_support_screen.dart';
import '../../features/user/screens/progress_screen.dart';
import '../../features/user/screens/user_nav_shell.dart';
import '../services/auth_service.dart';

class AppRoutes {
  static const String root = '/';
  static const String authStart = '/auth-start';
  static const String userLogin = '/user-login';
  static const String adminLogin = '/admin-login';
  static const String register = '/register';
  static const String otpVerification = '/otp-verification';
  static const String roleSelection = '/role-selection';
  static const String termsAgreement = '/terms-agreement';
  static const String passwordReset = '/reset-password';
  static const String adminDashboard = '/admin/dashboard';
  static const String quizManagement = '/admin/quiz-management';
  static const String quizCreate = '/admin/quiz-create';
  static const String quizEdit = '/admin/quiz-edit/:quizId';
  static const String userManagement = '/admin/user-management';
  static const String subscriptionManagement = '/admin/subscriptions';
  static const String adminPayments = '/admin/payments';
  static const String adminAgreements = '/admin/agreements';
  static const String userHome = '/user/home';
  static const String userProfile = '/user/profile';
  static const String userSettings = '/user/settings';
  static const String userHelpSupport = '/user/help-support';
  static const String userProgress = '/user/progress';
  static const String quizList = '/user/quiz-list';
  static const String quizTaking = '/user/quiz/:quizId';
  static const String quizResult = '/user/quiz/:quizId/result';
  static const String payment = '/user/payment/:quizId';
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  static late final GoRouter router;

  static void initialize() {
    final authService = Get.find<AuthService>();
    
    router = GoRouter(
      refreshListenable: GoRouterRefreshStream(
        authService.isAuthenticated.stream,
      ),
      redirect: (context, state) {
        final loggedIn = authService.isAuthenticated.value;
        final location = state.uri.path;
        final currentUser = authService.currentUser.value;

      final loggingScreens = <String>[
        AppRoutes.authStart,
        AppRoutes.userLogin,
        AppRoutes.adminLogin,
        AppRoutes.register,
        AppRoutes.otpVerification,
        AppRoutes.roleSelection,
        AppRoutes.termsAgreement,
        AppRoutes.passwordReset,
      ];

      final isAuthFlow = loggingScreens.contains(location);

      // If logged in, check if terms have been accepted
      if (loggedIn && currentUser != null) {
        // If user doesn't have a name yet, redirect to role selection to complete profile
        // (unless already on role selection screen or any auth flow screen)
        if ((currentUser.name == null || currentUser.name!.isEmpty) && 
            location != AppRoutes.roleSelection &&
            !isAuthFlow) {
          return AppRoutes.roleSelection;
        }
        
        final termsAccepted = currentUser.termsAccepted ?? false;

        // If terms not accepted and not on terms/role selection screen, redirect to terms
        // But skip if user hasn't completed profile yet (no name)
        if (!termsAccepted && 
            location != AppRoutes.termsAgreement && 
            location != AppRoutes.roleSelection &&
            currentUser.name != null && 
            currentUser.name!.isNotEmpty) {
          return AppRoutes.termsAgreement;
        }

        // If terms accepted and trying to access auth screens, redirect to home
        if (termsAccepted &&
            isAuthFlow &&
            location != AppRoutes.termsAgreement &&
            location != AppRoutes.roleSelection) {
          final role = currentUser.role;
          if (role == 'admin') return AppRoutes.adminDashboard;
          return AppRoutes.userHome;
        }
      }

      // If not logged in but on auth screens, allow access
      if (isAuthFlow && !loggedIn) {
        return null;
      }

      // For non-auth routes, check if user is logged in
      final isUserRoute = location.startsWith('/user');
      final isAdminRoute = location.startsWith('/admin');

      // If not logged in, block access to user/admin routes
      if (!loggedIn && (isUserRoute || isAdminRoute)) {
        // send admins back to admin login, others to auth start
        if (isAdminRoute) return AppRoutes.adminLogin;
        return AppRoutes.authStart;
      }

      return null;
    },
    //initialLocation: AppRoutes.authStart,
    routes: [
      GoRoute(path: '/', redirect: (_, __) => AppRoutes.authStart),
      GoRoute(
        path: AppRoutes.authStart,
        builder: (context, state) => const AuthStartScreen(),
      ),
      GoRoute(
        path: AppRoutes.userLogin,
        builder: (context, state) => const UserLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminLogin,
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.passwordReset,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      // Admin registration route removed for security (use normal register route)
      GoRoute(
        path: AppRoutes.otpVerification,
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return OtpVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.roleSelection,
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return RoleSelectionScreen(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.termsAgreement,
        builder: (context, state) => const TermsAgreementScreen(),
      ),
      // Admin Routes
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.quizManagement,
        builder: (context, state) => const QuizManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.quizCreate,
        builder: (context, state) => const QuizCreateScreen(),
      ),
      GoRoute(
        path: AppRoutes.quizEdit,
        builder: (context, state) {
          final quizId = state.pathParameters['quizId'] ?? '';
          return QuizCreateScreen(quizId: quizId);
        },
      ),
      GoRoute(
        path: AppRoutes.userManagement,
        builder: (context, state) => const UserManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscriptionManagement,
        builder: (context, state) => const SubscriptionManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminPayments,
        builder: (context, state) => const AdminPaymentTrackingScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminAgreements,
        builder: (context, state) => const AdminAgreementsSettingsScreen(),
      ),
      // User Routes
      GoRoute(
        path: AppRoutes.userHome,
        builder: (context, state) => const UserNavShell(initialIndex: 0),
      ),
      GoRoute(
        path: AppRoutes.userProfile,
        builder: (context, state) => const UserProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.userSettings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.userHelpSupport,
        builder: (context, state) => const HelpAndSupportScreen(),
      ),
      GoRoute(
        path: AppRoutes.userProgress,
        builder: (context, state) => const UserNavShell(initialIndex: 2),
      ),
      GoRoute(
        path: AppRoutes.quizList,
        builder: (context, state) => const UserNavShell(initialIndex: 1),
      ),
      GoRoute(
        path: AppRoutes.quizTaking,
        builder: (context, state) {
          final quizId = state.pathParameters['quizId'] ?? '';
          return QuizTakingScreen(quizId: quizId);
        },
      ),
      GoRoute(
        path: AppRoutes.quizResult,
        builder: (context, state) {
          final quizId = state.pathParameters['quizId'] ?? '';
          return QuizResultScreen(quizId: quizId);
        },
      ),
      GoRoute(
        path: AppRoutes.payment,
        builder: (context, state) {
          final quizId = state.pathParameters['quizId'] ?? '';
          return PaymentScreen(quizId: quizId);
        },
      ),
    ],
    errorBuilder:
        (context, state) =>
            Scaffold(body: Center(child: Text('Error: ${state.error}'))),
    );
  }
}
