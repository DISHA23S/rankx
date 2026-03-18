import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart' as app_user;
import 'supabase_service.dart';
import 'package:flutter/foundation.dart';


class LoginResult {
  final bool success;
  final bool requiresRegistration;

  const LoginResult({
    required this.success,
    this.requiresRegistration = false,
  });
}

class AuthService extends GetxController {
  late SupabaseService supabaseService;

  final Rx<app_user.User?> currentUser = Rx<app_user.User?>(null);
  final RxBool isAuthenticated = false.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() async {
    super.onInit();
    supabaseService = Get.find<SupabaseService>();
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    try {
      final user = supabaseService.client.auth.currentUser;
      if (user != null) {
        final userProfile = await supabaseService.getUserProfile(user.id);
        if (userProfile != null) {
          currentUser.value = app_user.User.fromJson(userProfile);
          isAuthenticated.value = true;
        }
      }
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }

  // User Login with Email & Password (no OTP)
  Future<LoginResult> loginUserWithPassword({
    required String email,
    required String password,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Lookup user profile to verify stored password hash
      final userProfile = await supabaseService.getUserProfileByEmail(email);
      if (userProfile == null) {
        errorMessage.value = 'Account not found. Please register first.';
        isLoading.value = false;
        return const LoginResult(success: false, requiresRegistration: true);
      }

      // Check role is user
      if (userProfile['role'] != 'user') {
        errorMessage.value = 'Only user accounts can login here';
        isLoading.value = false;
        return const LoginResult(success: false);
      }

      final stored = userProfile['password_hash'] as String?;
      if (stored == null || stored.isEmpty) {
        errorMessage.value = 'No password set for this account';
        isLoading.value = false;
        return const LoginResult(success: false);
      }

      // stored format: salt$hex
      final parts = stored.split(r'$');
      if (parts.length != 2) {
        errorMessage.value = 'Invalid stored password format';
        isLoading.value = false;
        return const LoginResult(success: false);
      }
      final salt = parts[0];
      final hashHex = parts[1];

      final computed = sha256.convert(utf8.encode(salt + password)).toString();
      if (computed != hashHex) {
        errorMessage.value = 'Invalid credentials';
        isLoading.value = false;
        return const LoginResult(success: false);
      }

      // Password verified — sign in with Supabase to establish session
      try {
        await supabaseService.client.auth.signInWithPassword(email: email, password: password);
      } catch (_) {
        // fall back: if Supabase sign-in fails, continue as authenticated locally
      }

      // Fetch user profile and set currentUser
      final profile = await supabaseService.getUserProfileByEmail(email);
      if (profile != null) {
        currentUser.value = app_user.User.fromJson(profile);
      }
      isAuthenticated.value = true;
      isLoading.value = false;
      return const LoginResult(success: true);
    } catch (e) {
      errorMessage.value = _formatErrorMessage(e);
      isLoading.value = false;
      return const LoginResult(success: false);
    }
  }

  Future<bool> sendPasswordResetEmail({
    required String email,
    String? redirectUrl,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      // Determine the appropriate redirect URL
      String resetUrl;
      if (kIsWeb) {
        // For web, use current origin if possible, fallback to localhost
        // In production, update this to your actual domain
        resetUrl = "${Uri.base.origin}/reset-password";
        debugPrint('Web reset URL: $resetUrl');
      } else {
        // For mobile, use custom scheme
        resetUrl = "rankx://reset-password";
      }
      
      await supabaseService.sendPasswordResetEmail(
        email: email,
        redirectUrl: redirectUrl ?? resetUrl,
      );
      isLoading.value = false;
      return true;
    } catch (e) {
      errorMessage.value = _formatErrorMessage(e);
      isLoading.value = false;
      return false;
    }
  }

  // Admin Login with OTP (email → send OTP → verify)
  Future<bool> loginAdminWithOtp({
    required String email,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Check if admin account exists
      final userProfile = await supabaseService.getUserProfileByEmail(email);
      if (userProfile == null) {
        errorMessage.value = 'Admin account not found. Run this SQL in Supabase:\n\nDROP POLICY IF EXISTS "Allow email lookup for login" ON public.users;\nCREATE POLICY "Allow email lookup for login" ON public.users FOR SELECT USING (auth.role() = \'anon\' OR auth.uid() = id);';
        isLoading.value = false;
        return false;
      }

      if (userProfile['role'] != 'admin') {
        errorMessage.value = 'Only admin accounts can login here';
        isLoading.value = false;
        return false;
      }

      // Send OTP via Supabase
      await supabaseService.signInWithOtp(email: email, phone: '', isEmail: true);
      isLoading.value = false;
      return true; // OTP sent; client should now verify
    } catch (e) {
      debugPrint('loginAdminWithOtp error: $e');
      final errorMsg = e.toString();
      if (errorMsg.contains('permission denied') ||
          errorMsg.contains('RLS') ||
          errorMsg.contains('policy')) {
        errorMessage.value =
            'Admin lookup blocked by database policy. Please check RLS policies in Supabase.';
      } else if (errorMsg.contains('over_email_send_rate_limit') ||
          errorMsg.contains('429')) {
        // Friendlier message for rate limiting
        errorMessage.value =
            'For security purposes, you can only request this after 23 seconds.';
      } else {
        errorMessage.value = _formatErrorMessage(e);
      }
      debugPrint('Admin login error message: ${errorMessage.value}');
      isLoading.value = false;
      return false;
    }
  }

  // Send OTP for registration
  Future<bool> sendOtp({required String email, bool isEmail = true}) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      await supabaseService.signInWithOtp(
        email: isEmail ? email : '',
        phone: isEmail ? '' : email,
        isEmail: isEmail,
      );
      isLoading.value = false;
      return true;
    } catch (e) {
      debugPrint('sendOtp error: $e');
      final formattedError = _formatErrorMessage(e);
      errorMessage.value = formattedError;
      debugPrint('Formatted error message: $formattedError');
      isLoading.value = false;
      return false;
    }
  }

  // Verify OTP
  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      await supabaseService.verifyOtp(
        email: email,
        phone: '',
        token: otp,
      );

      final user = supabaseService.client.auth.currentUser;
      if (user != null) {
        final userProfile = await supabaseService.getUserProfile(user.id);
        if (userProfile != null) {
          currentUser.value = app_user.User.fromJson(userProfile);
        } else {
          // Create a temporary user object until profile is created
          currentUser.value = app_user.User(
            id: user.id,
            email: user.email ?? email,
            role: 'user',
            name: '',
            phone: '',
            emailVerified: false,
            profileImage: '',
            createdAt: DateTime.now(),
          );
        }
        isAuthenticated.value = true;
        isLoading.value = false;
        return true;
      }
      isLoading.value = false;
      return false;
    } catch (e) {
      debugPrint('verifyOtp error: $e');
      final formattedError = _formatErrorMessage(e);
      errorMessage.value = formattedError;
      debugPrint('Formatted error message: $formattedError');
      isLoading.value = false;
      return false;
    }
  }

  // Complete Registration with Admin Role Only
  Future<bool> completeAdminRegistration({
    required String userId,
    required String email,
    String? name,
    String? phone,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Always create as admin
      await supabaseService.createUserProfile(
        userId: userId,
        email: email,
        role: 'admin',
        name: name,
        phone: phone,
      );

      final userProfile = await supabaseService.getUserProfile(userId);
      if (userProfile != null) {
        currentUser.value = app_user.User.fromJson(userProfile);
        isAuthenticated.value = true;
      }
      isLoading.value = false;
      return true;
    } catch (e) {
      errorMessage.value = 'Registration failed: ${e.toString()}';
      isLoading.value = false;
      return false;
    }
  }

  // Complete Registration (For users/admins)
  Future<bool> completeRegistration({
    required String userId,
    required String email,
    required String role,
    String? name,
    String? phone,
    String? password, // plain password provided from UI so we can store hash
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // compute and store salted hash if password provided
      String? passwordHash;
      if (password != null && password.isNotEmpty) {
        final salt = DateTime.now().millisecondsSinceEpoch.toString();
        final hash = sha256.convert(utf8.encode(salt + password)).toString();
        passwordHash = '$salt\$${hash}';
      }

      await supabaseService.createUserProfile(
        userId: userId,
        email: email,
        role: role,
        name: name,
        phone: phone,
        passwordHash: passwordHash,
      );

      // If user is currently signed in via OTP, set their Supabase auth password
      try {
        final current = supabaseService.client.auth.currentUser;
        if (current != null && password != null && password.isNotEmpty) {
          await supabaseService.client.auth.updateUser(UserAttributes(password: password));
        }
      } catch (e) {
        // ignore update errors — password stored in profile regardless
      }

      // Initialize user points if not already present
      final existingPoints = await supabaseService.getUserPointsByUserId(userId);
      if (existingPoints == null) {
        await supabaseService.insert(
          table: AppConstants.userPointsTable,
          data: [
            {
              'user_id': userId,
              'daily_points': 0,
              'weekly_points': 0,
              'total_points': 0,
              'last_updated': DateTime.now().toIso8601String(),
            }
          ],
        );
      }

      final userProfile = await supabaseService.getUserProfile(userId);
      if (userProfile != null) {
        currentUser.value = app_user.User.fromJson(userProfile);
      }
      isAuthenticated.value = true;
      isLoading.value = false;
      return true;
    } catch (e) {
      errorMessage.value = 'Registration failed: ${e.toString()}';
      isLoading.value = false;
      return false;
    }
  }

  Future<void> logout() async {
    isLoading.value = true;
    try {
      await supabaseService.client.auth.signOut();
      currentUser.value = null;
      isAuthenticated.value = false;
    } catch (e) {
      errorMessage.value = 'Logout failed: ${e.toString()}';
    }
    isLoading.value = false;
  }

  /// Format error messages to be user-friendly
  String _formatErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Check for specific error types FIRST before generic HTTP codes
    
    // OTP-specific errors (check before 403)
    if (errorString.contains('otp_expired') || 
        errorString.contains('token has expired') ||
        errorString.contains('otp expired') ||
        errorString.contains('invalid otp') ||
        errorString.contains('token.*invalid')) {
      return 'The verification code has expired or is invalid. Please request a new code.';
    }
    
    // Rate limiting
    if (errorString.contains('429') || 
        errorString.contains('too many requests') ||
        errorString.contains('rate_limit') ||
        errorString.contains('over_email_send_rate_limit')) {
      return 'Too many attempts. Please wait a few minutes before trying again.';
    }
    
    // Email already exists
    if (errorString.contains('email already registered') || 
        errorString.contains('user already registered') ||
        errorString.contains('already_registered')) {
      return 'This email is already registered. Please try logging in instead.';
    }
    
    // Network/Connection errors
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network connection error. Please check your internet connection.';
    }
    
    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    
    // Now check generic HTTP status codes
    if (errorString.contains('400') || errorString.contains('bad request')) {
      return 'Invalid request. Please check your information and try again.';
    }
    
    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return 'Authentication failed. Please check your credentials.';
    }
    
    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return 'Access denied. You do not have permission to perform this action.';
    }
    
    if (errorString.contains('404') || errorString.contains('not found')) {
      return 'The requested resource was not found.';
    }
    
    if (errorString.contains('500') || errorString.contains('internal server')) {
      return 'Server error occurred. Please try again later.';
    }
    
    if (errorString.contains('503') || errorString.contains('service unavailable')) {
      return 'Service is temporarily unavailable. Please try again later.';
    }
    
    // Default formatted message
    return 'An error occurred. Please try again later.';
  }
}
