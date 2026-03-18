import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_widgets.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  late TextEditingController _otpController;
  final _formKey = GlobalKey<FormState>();
  final authService = Get.find<AuthService>();
  int _remainingSeconds = 300;
  late Future<void> _timerFuture;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
    _startTimer();
  }

  void _startTimer() {
    _timerFuture = _runTimer();
  }

  Future<void> _runTimer() async {
    for (int i = 300; i > 0; i--) {
      if (mounted) {
        setState(() {
          _remainingSeconds = i;
        });
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header
                const Icon(
                  Icons.verified_user,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Verify Your Email',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'We sent a verification code to\n${widget.email}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xxl),
                // OTP Input
                AppTextField(
                  label: 'Enter OTP',
                  hintText: '000000',
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  validator: TextFieldValidator.validateOtp,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Verify Button
                Obx(
                  () => AppButton(
                    label:
                        authService.isLoading.value
                            ? 'Verifying...'
                            : 'Verify OTP',
                    onPressed: _handleVerifyOtp,
                    isLoading: authService.isLoading.value,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Resend OTP
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Resend in $_remainingSeconds seconds',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (_remainingSeconds == 0) ...[
                      const SizedBox(width: AppSpacing.sm),
                      TextButton(
                        onPressed: _handleResendOtp,
                        child: const Text('Resend OTP'),
                      ),
                    ],
                  ],
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleVerifyOtp() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await authService.verifyOtp(
        email: widget.email,
        otp: _otpController.text.trim(),
      );

      if (success && mounted) {
        // After successful OTP verification, check if user exists
        if (authService.currentUser.value != null) {
          final user = authService.currentUser.value!;

          // Check if terms have been accepted
          if (user.termsAccepted == true) {
            // Terms already accepted - redirect based on role
            final role = user.role;
            if (role == 'admin') {
              context.go(AppRoutes.adminDashboard);
            } else {
              context.go(AppRoutes.userHome);
            }
          } else {
            // Terms not accepted - redirect to terms agreement
            context.go(AppRoutes.termsAgreement);
          }
        } else {
          // New user - redirect to role selection
          context.go(AppRoutes.roleSelection, extra: widget.email);
        }
      }
    }
  }

  Future<void> _handleResendOtp() async {
    final success = await authService.sendOtp(
      email: widget.email,
      isEmail: true,
    );
    if (success && mounted) {
      setState(() {
        _remainingSeconds = 300;
      });
      _startTimer();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text('Verification code resent successfully to your email.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
