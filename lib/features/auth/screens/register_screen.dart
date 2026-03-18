import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/error_display_helper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 0; // 0: Role Selection, 1: Details, 2: OTP Verification
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _otpController;
  
  // Individual OTP field controllers
  late List<TextEditingController> _otpControllers;
  late List<FocusNode> _otpFocusNodes;
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _selectedRole; // only 'user' allowed

  final authService = Get.find<AuthService>();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _otpController = TextEditingController();
    
    // Initialize 6 OTP controllers and focus nodes
    _otpControllers = List.generate(6, (index) => TextEditingController());
    _otpFocusNodes = List.generate(6, (index) => FocusNode());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    
    // Dispose OTP controllers and focus nodes
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    // Basic validation
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields to continue.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 8 characters long.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match. Please ensure both passwords are identical.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // If account already exists -> prompt to login instead
    final existing = await authService.supabaseService.getUserProfileByEmail(email);
    if (existing != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An account with this email already exists. Please login instead.'),
          backgroundColor: AppColors.warning,
        ),
      );
      // Navigate to user login
      Future.microtask(() => context.go(AppRoutes.userLogin));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await authService.sendOtp(
        email: email,
        isEmail: true,
      );

      if (success && mounted) {
        setState(() => _currentStep = 2);
        ErrorDisplayHelper.showSuccess(
          context,
          'Verification code sent successfully to your email.',
        );
      } else if (mounted) {
        final errorMsg = authService.errorMessage.value.isEmpty 
            ? 'Failed to send verification code. Please try again.'
            : authService.errorMessage.value;
        ErrorDisplayHelper.showError(context, errorMsg);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleVerifyOtp() async {
    // Combine all 6 digit inputs into one OTP string
    final otp = _otpControllers.map((c) => c.text).join();
    
    if (otp.isEmpty || otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit verification code.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await authService.verifyOtp(
        email: _emailController.text.trim(),
        otp: otp,
      );

      if (success && mounted) {
        // Get current user and create basic profile with password
        final user = authService.currentUser.value;
        if (user != null) {
          // Create/update profile with email, password, and role but empty name/phone
          await authService.completeRegistration(
            userId: user.id ?? '',
            email: _emailController.text.trim(),
            role: 'user',
            name: '', // Will be filled in role selection screen
            phone: '', // Will be filled in role selection screen
            password: _passwordController.text,
          );
          
          // Navigate to role selection screen to collect name and phone
          if (mounted) {
            context.go(AppRoutes.roleSelection, extra: _emailController.text.trim());
          }
        }
      } else if (mounted) {
        final errorMsg = authService.errorMessage.value.isEmpty 
            ? 'Failed to verify code. Please try again.'
            : authService.errorMessage.value;
        ErrorDisplayHelper.showError(context, errorMsg);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              context.go(AppRoutes.authStart);
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            // Progress Indicator
            if (_currentStep > 0)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: (_currentStep + 1) / 3,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            // Step 0: Role Selection
            if (_currentStep == 0) ...[
              Text(
                'Create Account',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Choose your role to get started',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              // Only allow user registration (admin registration disabled)
              _buildRoleCard(
                        role: 'user',
                        title: 'Student',
                        description: 'Take Quiz and earn points',
                        icon: Icons.school,
                        isSelected: _selectedRole == 'user' || true,
                      ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Continue',
                onPressed: () {
                  setState(() {
                    _selectedRole = 'user';
                    _currentStep = 1;
                  });
                },
              ),
            ],
            // Step 1: Details
            if (_currentStep == 1) ...[
              Text(
                'Create Account',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Enter your details',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              // Email Field
              Text(
                'Email Address',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _emailController,
                hintText: 'name@example.com',
                prefixIcon: const Icon(Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.lg),
              // Password Field
              Text(
                'Password',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _passwordController,
                hintText: 'Create a strong password',
                prefixIcon: const Icon(Icons.lock_outline),
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Confirm Password Field
              Text(
                'Confirm Password',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _confirmPasswordController,
                hintText: 'Confirm your password',
                prefixIcon: const Icon(Icons.lock_outline),
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: _isLoading ? 'Sending OTP...' : 'Send OTP',
                onPressed: _isLoading ? null : _handleSendOtp,
                isLoading: _isLoading,
              ),
            ],
            // Step 2: OTP Verification
            if (_currentStep == 2) ...[
              // Full screen gradient background for OTP
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withOpacity(0.05),
                      AppColors.primaryLight.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    // Email Icon Circle
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.email_outlined,
                        color: AppColors.textLight,
                        size: 50,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Verification Code',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'We have sent the verification\ncode to your email address',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // Modern OTP Input
                    _buildModernOtpInput(),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Verify Button with gradient
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.textLight),
                          ),
                        )
                      : const Text(
                          'Confirm',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textLight,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive OTP?  ",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _handleSendOtp,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Resend',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                icon,
                color: isSelected ? Theme.of(context).colorScheme.onPrimary : AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.textLight, size: 32)
            else
              Icon(Icons.circle_outlined, color: AppColors.borderLight),
          ],
        ),
      ),
    );
  }
  
  Widget _buildModernOtpInput() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate box size based on available width
        final availableWidth = constraints.maxWidth;
        final spacing = 8.0;
        final totalSpacing = spacing * 5; // 5 gaps between 6 boxes
        final boxWidth = ((availableWidth - totalSpacing - 32) / 6).clamp(40.0, 50.0);
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            return Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : spacing / 2,
                right: index == 5 ? 0 : spacing / 2,
              ),
              child: _buildOtpBox(index, boxWidth),
            );
          }),
        );
      },
    );
  }

  Widget _buildOtpBox(int index, double boxWidth) {
    final hasValue = _otpControllers[index].text.isNotEmpty;
    final hasFocus = _otpFocusNodes[index].hasFocus;
    
    return Container(
      width: boxWidth,
      height: boxWidth * 1.2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: hasFocus 
            ? AppColors.primary.withOpacity(0.05)
            : hasValue 
                ? Theme.of(context).colorScheme.surface
                : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: hasFocus 
                ? AppColors.primary
                : hasValue 
                    ? AppColors.primary
                    : AppColors.borderMedium,
            width: hasFocus ? 3 : 2.5,
          ),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Placeholder underscore when empty
          if (!hasValue)
            Positioned(
              bottom: 0,
              child: Text(
                '_',
                style: TextStyle(
                  fontSize: boxWidth * 0.65,
                  fontWeight: FontWeight.w300,
                  color: AppColors.borderMedium,
                  height: 1.2,
                ),
              ),
            ),
          // TextField
          TextField(
            controller: _otpControllers[index],
            focusNode: _otpFocusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: TextStyle(
              fontSize: boxWidth * 0.58,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              height: 1.2,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.only(bottom: 8),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                _otpFocusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                _otpFocusNodes[index - 1].requestFocus();
              }
              
              if (index == 5 && value.isNotEmpty) {
                final allFilled = _otpControllers.every((c) => c.text.isNotEmpty);
                if (allFilled) {
                  FocusScope.of(context).unfocus();
                }
              }
              setState(() {});
            },
            onTap: () {
              _otpControllers[index].selection = TextSelection(
                baseOffset: 0,
                extentOffset: _otpControllers[index].text.length,
              );
            },
          ),
        ],
      ),
    );
  }
}
