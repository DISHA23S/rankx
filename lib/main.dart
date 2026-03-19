import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_links/app_links.dart';
import 'core/routes/app_router.dart';
import 'core/services/supabase_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/quiz_service.dart';
import 'core/services/quiz_result_service.dart';
import 'core/services/user_service.dart';
import 'core/services/points_service.dart';
import 'core/services/payment_service.dart';
import 'core/services/subscription_plan_service.dart';
import 'core/theme/app_theme.dart';
import 'core/controllers/theme_controller.dart';
import 'core/utils/url_strategy.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up global error handlers
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('Flutter Error: ${details.exception}');
    debugPrintStack(stackTrace: details.stack);
  };

  //configureUrlStrategy();
  setUrlStrategy(PathUrlStrategy()); 

  // Load environment variables
  await dotenv.load();

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      // Supabase will automatically detect and handle auth URLs/fragments
      autoRefreshToken: true,
    ),
  );

  // Initialize SupabaseService (singleton)
  Get.put(SupabaseService());

  // Initialize AuthService
  Get.put(AuthService());

  // Initialize QuizService
  Get.put(QuizService());

  // Initialize QuizResultService
  Get.put(QuizResultService());

  // Initialize UserService
  Get.put(UserService());

  // Initialize Points & Payment services
  Get.put(PointsService());
  Get.put(PaymentService());
  Get.put(SubscriptionPlanService());

  // Initialize Theme Controller
  Get.put(ThemeController());

  // Initialize AppRouter after all services are registered
  AppRouter.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _checkInitialUrl();
  }

  // Check if app was opened with a URL (important for web password reset)
  void _checkInitialUrl() async {
    try {
      // For web, check if current URL contains auth fragments
      final currentUrl = Uri.base;
      debugPrint('Initial URL: $currentUrl');
      
      if (currentUrl.fragment.isNotEmpty) {
        debugPrint('URL has fragment: ${currentUrl.fragment}');
        
        // Check if it's an auth-related fragment
        if (currentUrl.fragment.contains('access_token') || 
            currentUrl.fragment.contains('type=recovery') ||
            currentUrl.path.contains('reset-password')) {
          debugPrint('Auth fragment detected - letting Supabase handle it');
          
          // Give Supabase time to process the URL and establish session
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Navigate to reset password screen
          if (currentUrl.path.contains('reset-password') || 
              currentUrl.fragment.contains('type=recovery')) {
            AppRouter.router.go(AppRoutes.passwordReset);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking initial URL: $e');
    }
  }

  void _initDeepLinks() async {
    // Handle deep links when app is already running
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    // Handle deep link when app starts from killed state
    try {
      final initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Failed to get initial app link: $e');
    }
  }

  void _handleDeepLink(Uri uri) async {
    debugPrint('Deep link received: $uri');
    debugPrint('Host: ${uri.host}, Path: ${uri.path}, Fragment: ${uri.fragment}');

    // Check if it's a password reset link
    if (uri.host == 'reset-password' || 
        uri.path.contains('reset-password') || 
        uri.fragment.contains('type=recovery')) {
      
      debugPrint('Password reset link detected');
      
      // Check if there's a token_hash (new Supabase format) or code in query params
      final tokenHash = uri.queryParameters['token_hash'];
      final type = uri.queryParameters['type'];
      
      if (tokenHash != null && type == 'recovery') {
        // New format: token_hash - Supabase will handle this automatically
        debugPrint('Token hash detected - letting Supabase handle auth');
        await Future.delayed(const Duration(milliseconds: 500));
        AppRouter.router.go(AppRoutes.passwordReset);
        return;
      }
      
      // Check for access_token in fragment (hash-based URL)
      if (uri.fragment.contains('access_token')) {
        debugPrint('Access token in fragment - letting Supabase handle auth');
        await Future.delayed(const Duration(milliseconds: 500));
        AppRouter.router.go(AppRoutes.passwordReset);
        return;
      }
      
      // Check for legacy code parameter (causes PKCE error)
      final code = uri.queryParameters['code'];
      if (code != null) {
        debugPrint('Legacy code parameter detected: $code');
        debugPrint('WARNING: This format requires PKCE verifier and will likely fail');
        debugPrint('Please update your Supabase email template to use token_hash or access_token format');
        
        // Try to use verifyOtp as a workaround for recovery tokens
        try {
          debugPrint('Attempting to verify OTP with recovery token...');
          final response = await Supabase.instance.client.auth.verifyOTP(
            type: OtpType.recovery,
            token: code,
          );
          
          if (response.session != null) {
            debugPrint('Successfully verified recovery token');
            await Future.delayed(const Duration(milliseconds: 300));
            AppRouter.router.go(AppRoutes.passwordReset);
            return;
          }
        } catch (e) {
          debugPrint('verifyOTP failed: $e');
          debugPrint('This is expected - the code format is not compatible with OTP verification');
        }
      }
      
      // Navigate to reset screen anyway - user will see appropriate error message
      debugPrint('Navigating to reset password screen');
      await Future.delayed(const Duration(milliseconds: 300));
      AppRouter.router.go(AppRoutes.passwordReset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(
      () => GetMaterialApp.router(
        title: 'RankX',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.themeMode.value,
        routerDelegate: AppRouter.router.routerDelegate,
        routeInformationParser: AppRouter.router.routeInformationParser,
        routeInformationProvider: AppRouter.router.routeInformationProvider,
      ),
    );
  }
}
