import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/app_alerts.dart';
import '../../../core/widgets/error_display_helper.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  late TextEditingController _emailController;
  late TextEditingController _otpController;
  
  // Individual OTP field controllers
  late List<TextEditingController> _otpControllers;
  late List<FocusNode> _otpFocusNodes;
  
  final _formKey = GlobalKey<FormState>();
  final authService = Get.put(AuthService());
  bool _otpSent = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _otpController = TextEditingController();
    
    // Initialize 6 OTP controllers and focus nodes
    _otpControllers = List.generate(6, (index) => TextEditingController());
    _otpFocusNodes = List.generate(6, (index) => FocusNode());
  }

  @override
  void dispose() {
    _emailController.dispose();
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
    // When OTP is not yet sent, validate the whole form (email field)
    // When resending OTP, skip OTP validator (otherwise it shows "OTP is required")
    if (!_otpSent) {
      if (!(_formKey.currentState?.validate() ?? false)) return;
    } else {
      final emailText = _emailController.text.trim();
      if (emailText.isEmpty ||
          !RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(emailText)) {
        AppAlerts.showError('Please enter a valid admin email address');
        return;
      }
    }

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();

    final success = await authService.loginAdminWithOtp(email: email);

    if (success && mounted) {
      setState(() => _otpSent = true);
      AppAlerts.showSuccess('Verification code sent successfully to your email');
    } else if (mounted) {
      final errorMsg = authService.errorMessage.value.isEmpty 
          ? 'Failed to send verification code. Please try again.'
          : authService.errorMessage.value;
      
      // Show error on screen
      ErrorDisplayHelper.showError(context, errorMsg);
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyOtp() async {
    // Combine all 6 digit inputs into one OTP string
    final otp = _otpControllers.map((c) => c.text).join();
    
    if (otp.isEmpty || otp.length < 6) {
      AppAlerts.showError('Please enter the complete 6-digit verification code');
      return;
    }

    setState(() => _isLoading = true);

    final success = await authService.verifyOtp(
      email: _emailController.text.trim(),
      otp: otp,
    );

    if (success && mounted) {
      context.go(AppRoutes.adminDashboard);
    } else if (mounted) {
      final errorMsg = authService.errorMessage.value.isEmpty 
          ? 'Failed to verify code. Please try again.'
          : authService.errorMessage.value;
      
      // Show error on screen
      ErrorDisplayHelper.showError(context, errorMsg);
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_otpSent) {
              setState(() => _otpSent = false);
            } else {
              context.go(AppRoutes.authStart);
            }
          },
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? AppSpacing.md : AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: isSmallScreen ? AppSpacing.md : AppSpacing.lg),
                        
                        if (!_otpSent) ...[
                          // App Logo/Header
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings,
                              size: 48,
                              color: AppColors.textLight,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? AppSpacing.md : AppSpacing.lg),
                          Text(
                            'RankX Admin',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Secure Admin Portal',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isSmallScreen ? AppSpacing.lg : AppSpacing.xxl),
                          // Email Input
                          AppTextField(
                            label: 'Admin Email',
                            hintText: 'Enter your admin email',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
                                  .hasMatch(value.trim())) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // Send OTP Button
                          SizedBox(
                            width: double.infinity,
                            child: AppButton(
                              label: _isLoading ? 'Sending OTP...' : 'Send OTP',
                              onPressed: _isLoading ? null : _handleSendOtp,
                              isLoading: _isLoading,
                            ),
                          ),
                        ],

                        if (_otpSent) ...[
                          // Admin Shield Icon
                          Container(
                            width: isSmallScreen ? 70 : 90,
                            height: isSmallScreen ? 70 : 90,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.mail_outline_rounded,
                              color: AppColors.textLight,
                              size: isSmallScreen ? 35 : 45,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? AppSpacing.md : AppSpacing.lg),
                          Text(
                            'Verification Code',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                            child: Text(
                              'We have sent the verification code to your email address',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? AppSpacing.lg : AppSpacing.xl),
                          // OTP Input
                          _buildModernOtpInput(isSmallScreen),
                          SizedBox(height: isSmallScreen ? AppSpacing.lg : AppSpacing.xl),
                          // Verify Button
                          SizedBox(
                            width: double.infinity,
                            child: AppButton(
                              label: _isLoading ? 'Verifying...' : 'Confirm',
                              onPressed: _isLoading ? null : _handleVerifyOtp,
                              isLoading: _isLoading,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? AppSpacing.md : AppSpacing.lg),
                          // Resend OTP
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                "Didn't receive OTP?  ",
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              TextButton(
                                onPressed: _isLoading ? null : _handleSendOtp,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                    vertical: 0,
                                  ),
                                  minimumSize: const Size(50, 30),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Resend',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildModernOtpInput(bool isSmallScreen) {
    final spacing = isSmallScreen ? 4.0 : 8.0;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(6, (index) {
          return _buildOtpBox(index, isSmallScreen);
        }),
      ),
    );
  }

  Widget _buildOtpBox(int index, bool isSmallScreen) {
    final hasValue = _otpControllers[index].text.isNotEmpty;
    final hasFocus = _otpFocusNodes[index].hasFocus;
    final boxWidth = isSmallScreen ? 42.0 : 48.0;
    final boxHeight = isSmallScreen ? 55.0 : 60.0;
    final fontSize = isSmallScreen ? 24.0 : 28.0;
    
    return Container(
      width: boxWidth,
      height: boxHeight,
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
                  fontSize: fontSize + 4,
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
              fontSize: fontSize,
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
