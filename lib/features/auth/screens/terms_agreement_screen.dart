import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/models/user_model.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_widgets.dart';

class TermsAgreementScreen extends StatefulWidget {
  const TermsAgreementScreen({super.key});

  @override
  State<TermsAgreementScreen> createState() => _TermsAgreementScreenState();
}

class _TermsAgreementScreenState extends State<TermsAgreementScreen> {
  bool _isLoading = false;
  bool _isFetchingTerms = true;
  bool _agreedToTerms = false;
  final authService = Get.find<AuthService>();
  String _termsTitle = 'RankX User Agreement & Terms of Service';
  String _termsContent = '';
  String? _termsError;

  @override
  void initState() {
    super.initState();
    _loadTermsFromAdmin();
  }

  Future<void> _loadTermsFromAdmin() async {
    setState(() {
      _isFetchingTerms = true;
      _termsError = null;
    });

    try {
      // Fetch active terms from the agreements table posted by admin
      final response = await authService.supabaseService.client
          .from(AppConstants.agreementsTable)
          .select('title, content')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1);

      if (response != null && response.isNotEmpty) {
        final termsData = response.first;
        setState(() {
          _termsTitle = termsData['title'] ?? 'RankX User Agreement & Terms of Service';
          _termsContent = termsData['content'] ?? '';
          _isFetchingTerms = false;
        });
      } else {
        // No terms posted by admin yet - show default message
        setState(() {
          _termsContent =
              'No terms of service have been posted by the administrator yet. Please contact support.';
          _isFetchingTerms = false;
        });
      }
    } catch (e) {
      setState(() {
        _termsError = 'Failed to load terms: ${e.toString()}';
        _isFetchingTerms = false;
      });
    }
  }

  Future<void> _handleAcceptTerms() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please read and agree to the Terms of Service to continue.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = authService.currentUser.value;
      if (user?.id != null) {
        // Update user profile to mark terms as accepted
        await authService.supabaseService.client
            .from('users')
            .update({
              'terms_accepted': true,
              'terms_accepted_at': DateTime.now().toIso8601String(),
            })
            .eq('id', user!.id);

        // Refresh current user by getting it from database
        final userData =
            await authService.supabaseService.client
                .from('users')
                .select()
                .eq('id', user.id)
                .single();

        if (userData != null) {
          authService.currentUser.value = User.fromJson(userData);
        }

        if (mounted) {
          // Navigate to appropriate home screen based on role
          final role = user.role;
          if (role == 'admin') {
            context.go(AppRoutes.adminDashboard);
          } else {
            context.go(AppRoutes.userHome);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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

  Future<void> _handleDecline() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Decline Terms?'),
            content: const Text(
              'You must agree to the Terms of Service to use this app. '
              'Declining will log you out.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Decline & Logout'),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      await authService.logout();
      if (mounted) {
        context.go(AppRoutes.authStart);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: isSmallScreen ? 50 : 60,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Terms of Service',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Please review and accept our terms',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textLight.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Terms Content
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child:
                            _isFetchingTerms
                                ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                : _termsError != null
                                ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.lg,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          size: 60,
                                          color: AppColors.error,
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        Text(
                                          _termsError!,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: AppColors.error,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        AppButton(
                                          label: 'Retry',
                                          onPressed: _loadTermsFromAdmin,
                                          type: ButtonType.secondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                : SingleChildScrollView(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (_termsContent.isEmpty)
                                        Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(
                                              AppSpacing.xl,
                                            ),
                                            child: Column(
                                              children: [
                                                const Icon(
                                                  Icons.info_outline,
                                                  size: 60,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                                const SizedBox(
                                                  height: AppSpacing.md,
                                                ),
                                                Text(
                                                  'No terms available',
                                                  style:
                                                      Theme.of(
                                                        context,
                                                      ).textTheme.titleMedium,
                                                ),
                                                const SizedBox(
                                                  height: AppSpacing.sm,
                                                ),
                                                const Text(
                                                  'The administrator has not posted any terms of service yet.',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      else
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _termsTitle,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleLarge?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.lg,
                                            ),
                                            _FormattedText(
                                              content: _termsContent,
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.lg,
                                            ),
                                            Text(
                                              'Last updated: ${DateTime.now().toString().split(' ')[0]}',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall?.copyWith(
                                                color: AppColors.textSecondary,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                      ),
                      // Agreement Section
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.bgCardDark
                              : AppColors.bgSecondary,
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.textTertiaryDark.withOpacity(0.2)
                                  : AppColors.borderLight,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Checkbox
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _agreedToTerms = !_agreedToTerms;
                                });
                              },
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: _agreedToTerms,
                                    onChanged: (value) {
                                      setState(() {
                                        _agreedToTerms = value ?? false;
                                      });
                                    },
                                    activeColor: AppColors.primary,
                                  ),
                                  Expanded(
                                    child: Text(
                                      'I have read and agree to the Terms of Service',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: AppButton(
                                    label: 'Accept',
                                    onPressed: _handleAcceptTerms,
                                    isEnabled: _agreedToTerms && !_isLoading,
                                    isLoading: _isLoading,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: AppButton(
                                    label: 'Decline',
                                    onPressed: _handleDecline,
                                    type: ButtonType.secondary,
                                    isEnabled: !_isLoading,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget to display formatted text with basic markdown-style rendering
class _FormattedText extends StatelessWidget {
  final String content;

  const _FormattedText({required this.content});

  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (var line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: AppSpacing.sm));
        continue;
      }

      // Heading (##)
      if (line.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.md,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              line.substring(3),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
        continue;
      }

      // Bullet point
      if (line.startsWith('- ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              bottom: AppSpacing.xs,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: _parseInlineFormatting(context, line.substring(2)),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Numbered list
      if (RegExp(r'^\d+\. ').hasMatch(line)) {
        final parts = line.split('. ');
        final number = parts[0];
        final text = parts.sublist(1).join('. ');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              bottom: AppSpacing.xs,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '$number. ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(child: _parseInlineFormatting(context, text)),
              ],
            ),
          ),
        );
        continue;
      }

      // Quote
      if (line.startsWith('> ')) {
        widgets.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.bgSecondaryDark
                  : AppColors.bgSecondary,
              border: Border(
                left: BorderSide(color: AppColors.primary, width: 4),
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: _parseInlineFormatting(context, line.substring(2)),
          ),
        );
        continue;
      }

      // Regular paragraph
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _parseInlineFormatting(context, line),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _parseInlineFormatting(BuildContext context, String text) {
    final spans = <TextSpan>[];
    final buffer = StringBuffer();
    var i = 0;

    while (i < text.length) {
      // Bold (**text**)
      if (i < text.length - 1 && text[i] == '*' && text[i + 1] == '*') {
        if (buffer.isNotEmpty) {
          spans.add(TextSpan(text: buffer.toString()));
          buffer.clear();
        }
        i += 2;
        final start = i;
        while (i < text.length - 1) {
          if (text[i] == '*' && text[i + 1] == '*') {
            spans.add(
              TextSpan(
                text: text.substring(start, i),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
            i += 2;
            break;
          }
          i++;
        }
        continue;
      }

      // Italic (*text*)
      if (text[i] == '*') {
        if (buffer.isNotEmpty) {
          spans.add(TextSpan(text: buffer.toString()));
          buffer.clear();
        }
        i++;
        final start = i;
        while (i < text.length) {
          if (text[i] == '*') {
            spans.add(
              TextSpan(
                text: text.substring(start, i),
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            );
            i++;
            break;
          }
          i++;
        }
        continue;
      }

      buffer.write(text[i]);
      i++;
    }

    if (buffer.isNotEmpty) {
      spans.add(TextSpan(text: buffer.toString()));
    }

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.6,
        ),
        children: spans.isEmpty ? [TextSpan(text: text)] : spans,
      ),
    );
  }
}
