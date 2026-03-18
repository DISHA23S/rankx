import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/app_widgets.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _sessionReady = false;
  int _retryCount = 0;
  static const int _maxRetries = 15; 

  final supabaseService = Get.find<SupabaseService>();

  @override
  void initState() {
    super.initState();
    _checkSessionWithRetry();
    
    // Listen to auth state changes
    supabaseService.client.auth.onAuthStateChange.listen((data) {
      if (mounted && data.session != null && !_sessionReady) {
        debugPrint('Auth state changed - session now available');
        setState(() {
          _sessionReady = true;
        });
      }
    });
  }

  Future<void> _checkSessionWithRetry() async {
    // Try to get session with retries (important for web and deep links)
    // Supabase processes URL hash fragments automatically, we just need to wait
    while (_retryCount < _maxRetries && !_sessionReady && mounted) {
      final session = supabaseService.client.auth.currentSession;
      
      if (session != null) {
        debugPrint('Session ready for password reset');
        if (mounted) {
          setState(() {
            _sessionReady = true;
          });
        }
        return;
      }
      
      debugPrint('No session yet, retry $_retryCount/$_maxRetries');
      _retryCount++;
      
      // Wait before retrying - longer delays for web to process URL hash
      await Future.delayed(Duration(milliseconds: 400 * _retryCount));
    }
    
    if (!_sessionReady && mounted) {
      debugPrint('Failed to establish session after $_maxRetries retries');
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _sessionReady ? _buildResetForm() : _buildWaitingView(),
        ),
      ),
    );
  }

  Widget _buildWaitingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Verifying reset link...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Please wait while we verify your password reset link.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextButton(
            onPressed: () => context.go(AppRoutes.authStart),
            child: const Text('Back to Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildResetForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Create a new password',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Enter and confirm your new password below.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),
          
          // New Password Field
          AppTextField(
            label: 'New Password',
            hintText: 'At least ${AppConstants.minPasswordLength} characters',
            controller: _passwordController,
            obscureText: _obscurePassword,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Password is required';
              }
              if (v.length < AppConstants.minPasswordLength) {
                return 'Password must be at least ${AppConstants.minPasswordLength} characters';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Confirm Password Field
          AppTextField(
            label: 'Confirm Password',
            hintText: 'Re-enter your new password',
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            prefixIcon: const Icon(Icons.lock_reset),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please confirm your password';
              }
              if (v != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.xxl),
          
          // Reset Button
          AppButton(
            label: _isLoading ? 'Updating...' : 'Update Password',
            onPressed: _isLoading ? null : _handleReset,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Future<void> _handleReset() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final user = supabaseService.client.auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your session has expired. Please request a new password reset link.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final newPassword = _passwordController.text.trim();

      // 1. Update password in Supabase Auth
      await supabaseService.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      // 2. Update custom password hash in users table
      // Generate salt and hash like during registration
      final salt = DateTime.now().millisecondsSinceEpoch.toString();
      final hash = sha256.convert(utf8.encode(salt + newPassword)).toString();
      final passwordHash = '$salt\$${hash}';
      
      await supabaseService.updateUserPasswordHash(
        userId: user.id,
        passwordHash: passwordHash,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully! You can now login with your new password.'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Navigate to login screen
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            context.go(AppRoutes.userLogin);
          }
        });
      }
    } catch (e) {
      debugPrint('Password reset error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update password. Please try again or request a new reset link.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
