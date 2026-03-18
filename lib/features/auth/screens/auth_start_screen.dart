import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_widgets.dart';

class AuthStartScreen extends StatelessWidget {
  const AuthStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 600;

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // Header Section - Make it flexible instead of expanded
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height:
                                    isSmallScreen
                                        ? AppSpacing.sm
                                        : AppSpacing.md,
                              ),
                              // App Icon/Logo
                              Container(
                                width: isSmallScreen ? 80 : 100,
                                height: isSmallScreen ? 80 : 100,
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (
                                    context,
                                    error,
                                    stackTrace,
                                  ) {
                                    return const Icon(
                                      Icons.quiz,
                                      size: 50,
                                      color: AppColors.primary,
                                    );
                                  },
                                ),
                              ),
                              SizedBox(
                                height:
                                    isSmallScreen
                                        ? AppSpacing.sm
                                        : AppSpacing.md,
                              ),
                              Text(
                                'RankX',
                                style: Theme.of(
                                  context,
                                ).textTheme.displaySmall?.copyWith(
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 28 : 32,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Learn, Quiz, Achieve',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                                ),
                              ),
                              SizedBox(
                                height:
                                    isSmallScreen
                                        ? AppSpacing.sm
                                        : AppSpacing.md,
                              ),
                            ],
                          ),
                        ),
                        // Action Buttons Section - Use flexible to prevent overflow
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(40),
                              topRight: Radius.circular(40),
                            ),
                          ),
                          padding: EdgeInsets.all(
                            isSmallScreen ? AppSpacing.md : AppSpacing.xl,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                SizedBox(
                                  height:
                                      isSmallScreen
                                          ? AppSpacing.sm
                                          : AppSpacing.md,
                                ),
                                Text(
                                  'Get Started',
                                  style: Theme.of(context).textTheme.headlineSmall
                                      ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).textTheme.headlineSmall?.color,
                                  ),
                                ),
                                SizedBox(
                                  height:
                                      isSmallScreen
                                          ? AppSpacing.md
                                          : AppSpacing.lg,
                                ),
                                // Login button
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        screenWidth > 600 ? 400 : double.infinity,
                                  ),
                                  child: AppButton(
                                    label: 'Login',
                                    icon: Icons.login,
                                    onPressed: () => _showLoginChooser(context),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                // Create Account button
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        screenWidth > 600 ? 400 : double.infinity,
                                  ),
                                  child: AppButton(
                                    label: 'Create Account',
                                    icon: Icons.person_add,
                                    onPressed:
                                        () => context.go(AppRoutes.register),
                                    type: ButtonType.secondary,
                                  ),
                                ),
                                SizedBox(
                                  height:
                                      isSmallScreen
                                          ? AppSpacing.md
                                          : AppSpacing.lg,
                                ),
                                // Terms Text
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                  ),
                                  child: RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      text: 'By continuing, you agree to our ',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      children: [
                                        WidgetSpan(
                                          alignment: PlaceholderAlignment.baseline,
                                          baseline: TextBaseline.alphabetic,
                                          child: GestureDetector(
                                            onTap: () => _showTermsOfService(context),
                                            child: Text(
                                              'Terms of Service',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall?.copyWith(
                                                color: AppColors.primary,
                                                decoration: TextDecoration.underline,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height:
                                      isSmallScreen
                                          ? AppSpacing.sm
                                          : AppSpacing.md,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showLoginChooser(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (ctx) => Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.login, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Login as',
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Admin',
                  icon: Icons.admin_panel_settings,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.go(AppRoutes.adminLogin);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Student',
                  icon: Icons.school,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.go(AppRoutes.userLogin);
                  },
                  type: ButtonType.secondary,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
    );
  }

  void _showTermsOfService(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Fetch active terms from the agreements table posted by admin
      final response = await Get.find<AuthService>().supabaseService.client
          .from('agreements')
          .select('title, content')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1);

      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      String title = 'Terms of Service';
      String content = '';

      if (response != null && response.isNotEmpty) {
        final termsData = response.first;
        title = termsData['title'] ?? 'Terms of Service';
        content = termsData['content'] ?? '';
      } else {
        content =
            'No terms of service have been posted by the administrator yet. Please contact support.';
      }

      // Show terms in a dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.description, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(ctx).size.width * 0.9,
              height: MediaQuery.of(ctx).size.height * 0.6,
              child: SingleChildScrollView(
                child: content.isEmpty
                    ? const Center(
                        child: Text(
                          'No terms available',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      )
                    : _FormattedText(content: content),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) Navigator.of(context).pop();

      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load terms and conditions. Please try again later.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// Widget to display formatted text with markdown-like syntax
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
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.blue[300]
                    : AppColors.primary,
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
                Text(
                  '• ',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
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
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
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
                  ? Colors.grey[800]
                  : AppColors.bgSecondary,
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.blue[300]!
                      : AppColors.primary,
                  width: 4,
                ),
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
          color: Theme.of(context).textTheme.bodyMedium?.color,
          height: 1.6,
        ),
        children: spans.isEmpty ? [TextSpan(text: text)] : spans,
      ),
    );
  }
}
