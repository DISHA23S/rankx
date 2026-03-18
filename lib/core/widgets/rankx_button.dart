import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

/// RankX reusable button components
/// Consistent styling across the app

enum RankXButtonType { primary, secondary, text, gradient }

class RankXButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final RankXButtonType type;
  final bool fullWidth;
  final IconData? icon;
  final bool loading;
  final double? height;

  const RankXButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = RankXButtonType.primary,
    this.fullWidth = false,
    this.icon,
    this.loading = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget buttonChild =
        loading
            ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  type == RankXButtonType.primary
                      ? theme.colorScheme.onPrimary
                      : AppColors.primary,
                ),
              ),
            )
            : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: AppSpacing.iconSm),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(text),
              ],
            );

    Widget button;

    switch (type) {
      case RankXButtonType.primary:
        button = ElevatedButton(
          onPressed: loading ? null : onPressed,
          child: buttonChild,
        );
        break;

      case RankXButtonType.secondary:
        button = OutlinedButton(
          onPressed: loading ? null : onPressed,
          child: buttonChild,
        );
        break;

      case RankXButtonType.text:
        button = TextButton(
          onPressed: loading ? null : onPressed,
          child: buttonChild,
        );
        break;

      case RankXButtonType.gradient:
        button = Container(
          height: height ?? AppSpacing.buttonHeight,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: loading ? null : onPressed,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.buttonHorizontal,
                  ),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                    child: buttonChild,
                  ),
                ),
              ),
            ),
          ),
        );
        break;
    }

    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        height: height ?? AppSpacing.buttonHeight,
        child: button,
      );
    }

    return button;
  }
}
