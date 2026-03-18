import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import 'rankx_button.dart';

/// RankX reusable card component
/// Consistent card styling with elevation and spacing

class RankXCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? elevation;
  final Gradient? gradient;
  final Border? border;

  const RankXCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.elevation,
    this.gradient,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Widget cardContent = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color:
            gradient == null
                ? (backgroundColor ?? theme.cardTheme.color)
                : null,
        gradient: gradient,
        border: border,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow:
            elevation != null
                ? [
                  BoxShadow(
                    color: theme.shadowColor
                        .withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: elevation! * 2,
                    offset: Offset(0, elevation! / 2),
                  ),
                ]
                : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return Container(
        margin:
            margin ??
            const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: cardContent,
          ),
        ),
      );
    }

    return Container(
      margin:
          margin ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
      child: cardContent,
    );
  }
}

/// Quiz card component with consistent styling
class RankXQuizCard extends StatelessWidget {
  final String title;
  final String difficulty;
  final int questionCount;
  final VoidCallback onTap;
  final String? category;
  final String? description;
  final String? durationLabel;
  final int? points;
  final int? totalMarks;
  final int? attempts;
  final String? imageUrl;

  const RankXQuizCard({
    super.key,
    required this.title,
    required this.difficulty,
    required this.questionCount,
    required this.onTap,
    this.category,
    this.description,
    this.durationLabel,
    this.points,
    this.totalMarks,
    this.attempts,
    this.imageUrl,
  });

  Color _getDifficultyColor() {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'hard':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final difficultyColor = _getDifficultyColor();

    return RankXCard(
      onTap: onTap,
      elevation: AppSpacing.elevationSm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quiz image if available
          if (imageUrl != null && imageUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Image.network(
                imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 150,
                  color: AppColors.bgSecondary,
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          
          // Category chip + Difficulty badge
          Row(
            children: [
              if (category != null && category!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  ),
                  child: Text(
                    category!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.brightness == Brightness.dark
                          ? theme.colorScheme.primary.withOpacity(0.9)
                          : theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const Spacer(),
              if (points != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? AppColors.infoLight.withOpacity(0.15)
                        : AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  ),
                  child: Text(
                    '💎 $points',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.brightness == Brightness.dark
                          ? AppColors.infoLight
                          : AppColors.info,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (points != null) const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: difficultyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
                child: Text(
                  difficulty,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: difficultyColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Quiz title
          Text(
            title,
            style: theme.textTheme.titleLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          if (description != null && description!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              description!,
              style: theme.textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: AppSpacing.sm),

          // Metadata
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _buildMeta(
                theme,
                Icons.quiz_outlined,
                '$questionCount Questions',
              ),
              if (durationLabel != null)
                _buildMeta(theme, Icons.timer_outlined, durationLabel!),
              if (totalMarks != null)
                _buildMeta(theme, Icons.flag_outlined, '${totalMarks!} marks'),
              if (attempts != null)
                _buildMeta(
                  theme,
                  Icons.people_outline,
                  '${attempts!} attempts',
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Start button
          SizedBox(
            width: double.infinity,
            child: RankXButton(
              text: 'Start Quiz',
              onPressed: onTap,
              type: RankXButtonType.secondary,
              fullWidth: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeta(ThemeData theme, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: AppSpacing.iconSm,
          color: theme.textTheme.bodySmall?.color,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
