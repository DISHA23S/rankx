import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/points_service.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/rankx_card.dart';
import '../../../core/widgets/rankx_stat_widgets.dart';
import '../../../core/widgets/rankx_button.dart';
import '../../../core/widgets/rankx_common_widgets.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final authService = Get.find<AuthService>();
  final pointsService = Get.find<PointsService>();

  int _selectedNavIndex = 0;
  bool _pointsLoaded = false;

  @override
  void initState() {
    super.initState();
    // Try loading points immediately if user is already available.
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensurePointsLoaded());
  }

  Future<void> _ensurePointsLoaded() async {
    final userId = authService.currentUser.value?.id;
    if (userId == null || _pointsLoaded) return;
    _pointsLoaded = true;
    await pointsService.getUserPoints(userId);
  }

  @override
  Widget build(BuildContext context) {
    _ensurePointsLoaded();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                    child: Icon(
                      Icons.assignment,
                      size: 20,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('RankX'),
          ],
        ),
        actions: [
          Obx(() {
            final pts = pointsService.userPoints.value?.totalPoints ?? 0;
            return Container(
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('💎', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    pts.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: _showProfileMenu,
            tooltip: 'Profile',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final userId = authService.currentUser.value?.id;
                if (userId != null) {
                  await pointsService.getUserPoints(userId);
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Curved top spacing
                    const SizedBox(height: 20),
                    // Points Overview with curved top
                    CurvedTopContainer(
                      topRadius: 30,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Your Points',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => context.go(AppRoutes.quizList),
                                icon: Icon(
                                  Icons.assignment,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  size: 18,
                                ),
                                label: Text(
                                  'Quiz',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          Obx(() {
                            final pts = pointsService.userPoints.value;
                            final daily = pts?.dailyPoints ?? 0;
                            final weekly = pts?.weeklyPoints ?? 0;
                            final balance = pts?.totalPoints ?? 0;

                            return Row(
                              children: [
                                Expanded(
                                  child: _buildPointsTile(
                                    emoji: '🔥',
                                    label: 'Daily',
                                    points: daily,
                                    accent: const Color(0xFFFFC107),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: _buildPointsTile(
                                    emoji: '🏆',
                                    label: 'Weekly',
                                    points: weekly,
                                    accent: const Color(0xFF4CAF50),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: _buildPointsTile(
                                    emoji: '💎',
                                    label: 'Balance',
                                    points: balance,
                                    accent: const Color(0xFF00BCD4),
                                  ),
                                ),
                              ],
                            );
                          }),

                          const SizedBox(height: AppSpacing.sm),

                          Obx(() {
                            final name =
                                authService.currentUser.value?.name ?? 'Player';
                            return Text(
                              'Hi $name — spend points to unlock Quiz.',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onPrimary.withOpacity(0.9),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    // Main Content with curved top
                    CurvedTopContainer(
                      topRadius: 30,
                      margin: EdgeInsets.zero,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RankXCard(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.auto_graph,
                                    color: theme.colorScheme.onPrimary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Your Learning Hub',
                                        style: theme.textTheme.titleLarge,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        'Take Quiz, earn points, and climb the ranks',
                                        style: theme.textTheme.bodyMedium,
                                        overflow: TextOverflow.visible,
                                        maxLines: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          Text(
                            'Quick Actions',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          RankXButton(
                            text: 'Browse All Quiz',
                            type: RankXButtonType.gradient,
                            fullWidth: true,
                            icon: Icons.assignment,
                            onPressed: () => context.go(AppRoutes.quizList),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: RankXButton(
                                  text: 'Progress',
                                  type: RankXButtonType.secondary,
                                  icon: Icons.trending_up,
                                  onPressed:
                                      () => context.go(AppRoutes.userProgress),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: RankXButton(
                                  text: 'Leaderboard',
                                  type: RankXButtonType.secondary,
                                  icon: Icons.leaderboard,
                                  onPressed:
                                      () => ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Coming soon'),
                                        ),
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          Text(
                            'Featured Quiz',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          RankXInfoBanner(
                            message:
                                'New Quiz are added regularly by admins. Check the Quiz list for the latest content!',
                            icon: Icons.info_outline,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsTile({
    required String emoji,
    required String label,
    required int points,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.18),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            points.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: 3,
            width: double.infinity,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.9),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('View Profile'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.userProfile);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.userSettings);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Help & Support'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.userHelpSupport);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _handleLogout();
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  await authService.logout();
                  if (mounted) {
                    context.go(AppRoutes.userLogin);
                  }
                },
                child: const Text(
                  'Logout',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );
  }
}
