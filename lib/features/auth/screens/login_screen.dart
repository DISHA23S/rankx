import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/rankx_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  final _formKey = GlobalKey<FormState>();
  final authService = Get.put(AuthService());
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xl),
                // App Logo
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.quiz,
                      size: 40,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Welcome Text
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Sign in to continue your learning journey',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Role Selection
                Text('I am a', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Text(
                          'Student',
                          style: TextStyle(
                            color: !_isAdmin 
                              ? Theme.of(context).colorScheme.onPrimary 
                              : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        selected: !_isAdmin,
                        onSelected: (v) => setState(() => _isAdmin = false),
                        selectedColor: Theme.of(context).colorScheme.primary,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ChoiceChip(
                        label: Text(
                          'Admin',
                          style: TextStyle(
                            color: _isAdmin 
                              ? Theme.of(context).colorScheme.onPrimary 
                              : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        selected: _isAdmin,
                        onSelected: (v) => setState(() => _isAdmin = true),
                        selectedColor: Theme.of(context).colorScheme.primary,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Email Input
                AppTextField(
                  label: 'Email',
                  hintText: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: TextFieldValidator.validateEmail,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Password Input (both user and admin use email/password login)
                AppTextField(
                  label: 'Password',
                  hintText: 'Enter your password',
                  controller: _passwordController,
                  prefixIcon: const Icon(Icons.lock_outline),
                  obscureText: true,
                  validator:
                      (v) =>
                          v == null ||
                                  v.trim().length <
                                      AppConstants.minPasswordLength
                              ? 'Password must be at least ${AppConstants.minPasswordLength} characters'
                              : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                Obx(
                  () => RankXButton(
                    text: _isAdmin ? 'Sign In as Admin' : 'Sign In',
                    type: RankXButtonType.gradient,
                    fullWidth: true,
                    onPressed:
                        authService.isLoading.value ? null : _handleLogin,
                    loading: authService.isLoading.value,
                    icon: Icons.arrow_forward,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Error Message
                Obx(
                  () =>
                      authService.errorMessage.value.isNotEmpty
                          ? Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                            ),
                            child: Text(
                              authService.errorMessage.value,
                              style: const TextStyle(color: AppColors.error),
                              textAlign: TextAlign.center,
                            ),
                          )
                          : const SizedBox(),
                ),
                const SizedBox(height: AppSpacing.xl),
                // (No OTP flow) Using email & password for login.
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAdminLogin() async {
    // kept for backward compatibility; unused by UI now
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final success = await authService.loginWithPassword(
      email: email,
      password: password,
      requiredRole: 'admin',
    );

    if (success && mounted) {
      context.go(AppRoutes.adminDashboard);
    }
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // This triggers password verification and sends OTP if password matches.
    final otpSent = await authService.loginWithPassword(
      email: email,
      password: password,
      requiredRole: _isAdmin ? 'admin' : 'user',
    );

    if (!otpSent) return; // error message shown by authService

    // Prompt for OTP
    final otpController = TextEditingController();
    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Enter OTP'),
            content: TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '6-digit code'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final ok = await authService.verifyOtp(
                    email: email,
                    otp: otpController.text.trim(),
                  );
                  Navigator.of(ctx).pop(ok);
                },
                child: const Text('Verify'),
              ),
            ],
          ),
    );

    if (verified == true && mounted) {
      if (_isAdmin) {
        context.go(AppRoutes.adminDashboard);
      } else {
        context.go(AppRoutes.userHome);
      }
    }
  }
}
