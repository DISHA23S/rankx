import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/supabase_service.dart';
import 'admin_agreements_settings_screen.dart';
import 'admin_payment_tracking_screen.dart';
import 'user_management_screen.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/rankx_stat_widgets.dart';
import '../../../core/widgets/rankx_card.dart';
import '../../../core/widgets/rankx_button.dart';
import '../../../core/widgets/rankx_common_widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final authService = Get.find<AuthService>();
  final supabaseService = Get.find<SupabaseService>();
  int _selectedIndex = 0;
  bool _statsLoading = true;
  int _totalQuizzes = 0;
  int _liveQuizzes = 0;
  int _totalUsers = 0;
  double _avgScore = 0;
  double _revenue = 0;
  int _accountsLive = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        titleSpacing: 0,
        title: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: isWide ? AppSpacing.lg : AppSpacing.sm),
                Container(
                  width: isWide ? 40 : 32,
                  height: isWide ? 40 : 32,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                        ),
                        child: Icon(
                          Icons.admin_panel_settings,
                          size: isWide ? 20 : 16,
                          color: theme.colorScheme.onPrimary,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: isWide ? AppSpacing.sm : 6),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'RankX Admin',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: isWide ? null : 16,
                          ),
                        ),
                      ),
                      if (isWide)
                        Text(
                          'Control Center',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimary.withOpacity(0.9),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return Obx(() {
                final email = authService.currentUser.value?.email ?? 'Admin';
                if (isWide) {
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onPrimary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person,
                            color: theme.colorScheme.onPrimary,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 140),
                            child: Text(
                              email,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  // Mobile: Just show icon
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onPrimary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        color: theme.colorScheme.onPrimary,
                        size: 18,
                      ),
                    ),
                  );
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: theme.colorScheme.onPrimary),
            onPressed: _handleLogout,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(78),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children:
                    [
                        _buildNavItem(Icons.dashboard_outlined, 'Home', 0),
                        _buildNavItem(Icons.assignment_outlined, 'Quiz', 1),
                        _buildNavItem(Icons.people_alt_outlined, 'Users', 2),
                        _buildNavItem(Icons.assessment_outlined, 'Reports', 3),
                        _buildNavItem(Icons.settings_outlined, 'Settings', 4),
                      ].expand((w) sync* {
                        yield w;
                        yield const SizedBox(width: AppSpacing.md);
                      }).toList()
                      ..removeLast(),
              ),
            ),
          ),
        ),
      ),
      body: _buildTabContent(),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildQuizzesTab();
      case 2:
        return _buildUsersTab();
      case 3:
        return _buildPaymentsTab();
      case 4:
        return _buildAgreementsTab();
      default:
        return _buildDashboardTab();
    }
  }

  Widget _buildDashboardTab() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Top hero / welcome section with curved top
                CurvedTopContainer(
                  topRadius: 30,
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.lg,
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
                                color: AppColors.adminPrimary,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                              ),
                              child: Icon(
                                Icons.dashboard,
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Admin Dashboard',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Obx(() {
                                    final name =
                                        authService.currentUser.value?.name ??
                                        'Admin';
                                    return Text(
                                      'Welcome back, $name. Monitor your platform at a glance.',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // KPI row
                      const RankXSectionHeader(
                        title: 'Platform Overview',
                        icon: Icons.analytics,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildStatsGrid(),
                      const SizedBox(height: AppSpacing.xl),

                      // Management sections
                      const RankXSectionHeader(
                        title: 'Quick Management',
                        icon: Icons.settings,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Column(
                        children: [
                          _buildManagementTile(
                            title: 'Quiz Management',
                            subtitle:
                                'Create, update, delete and preview all quizzes.',
                            icon: Icons.quiz,
                            primaryActionLabel: 'Create Quiz',
                            secondaryActionLabel: 'Manage Quizzes',
                            onPrimary: () => context.push(AppRoutes.quizCreate),
                            onSecondary:
                                () => context.push(AppRoutes.quizManagement),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildManagementTile(
                            title: 'Users',
                            subtitle:
                                'View individual users, points and activity.',
                            icon: Icons.people,
                            primaryActionLabel: 'View Users',
                            secondaryActionLabel: 'User List',
                            onPrimary:
                                () => context.push(AppRoutes.userManagement),
                            onSecondary:
                                () => context.push(AppRoutes.userManagement),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildManagementTile(
                            title: 'Reports & Analytics',
                            subtitle:
                                'Access detailed performance, revenue and usage reports.',
                            icon: Icons.insights,
                            primaryActionLabel: 'Open Reports',
                            secondaryActionLabel: 'View Analytics',
                            onPrimary: () => setState(() => _selectedIndex = 3),
                            onSecondary:
                                () => setState(() => _selectedIndex = 3),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildManagementTile(
                            title: 'Subscriptions',
                            subtitle:
                                'Create, update and delete subscription plans (price, days, points).',
                            icon: Icons.subscriptions,
                            primaryActionLabel: 'Manage Plans',
                            secondaryActionLabel: 'View Plans',
                            onPrimary:
                                () => context.push(
                                  AppRoutes.subscriptionManagement,
                                ),
                            onSecondary:
                                () => context.push(
                                  AppRoutes.subscriptionManagement,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'RankX • Admin Control Panel',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Support: RankXapp@gmail.com',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                '© ${DateTime.now().year} RankX. All rights reserved.',
                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isActive
                  ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.18)
                  : null,
          borderRadius: BorderRadius.circular(12),
          border:
              isActive
                  ? Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withOpacity(0.28),
                    width: 1,
                  )
                  : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color:
                  isActive
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(
                        context,
                      ).colorScheme.onPrimary.withOpacity(0.7),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color:
                    isActive
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(
                          context,
                        ).colorScheme.onPrimary.withOpacity(0.7),
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return AppCard(
      backgroundColor: AppColors.bgCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.onPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String primaryActionLabel,
    required String secondaryActionLabel,
    required VoidCallback onPrimary,
    required VoidCallback onSecondary,
  }) {
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.onPrimary, size: 28),
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
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    TextButton(
                      onPressed: onPrimary,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      child: Text(primaryActionLabel),
                    ),
                    TextButton(
                      onPressed: onSecondary,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      child: Text(secondaryActionLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizzesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment, size: 64, color: AppColors.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Quiz Management',
            style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'View All Quizzes',
            onPressed: () => context.push(AppRoutes.quizManagement),
            width: 200,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Create New Quiz',
            onPressed: () => context.push(AppRoutes.quizCreate),
            width: 200,
            type: ButtonType.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    // Show full user management screen with its own app bar
    // (includes global subscription actions)
    return const UserManagementScreen(showAppBar: true);
  }

  Widget _buildPaymentsTab() {
    return const AdminPaymentTrackingScreen(showAppBar: false);
  }

  Widget _buildAgreementsTab() {
    return const AdminAgreementsSettingsScreen(showAppBar: false);
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
                    context.go(AppRoutes.adminLogin);
                  }
                },
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive breakpoint: 2 columns on wider screens, 1 on mobile
        final isMobile = constraints.maxWidth < 600;
        
        if (isMobile) {
          // Mobile layout: 2 cards per row with fixed height
          return Column(
            children: [
              SizedBox(
                height: 130,
                child: Row(
                  children: [
                    Expanded(
                      child: RankXStatCard(
                        title: 'Total Quiz',
                        value: _totalQuizzes.toString(),
                        icon: Icons.assignment_outlined,
                        color: AppColors.adminPrimary,
                        isDark: Theme.of(context).brightness == Brightness.dark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: RankXStatCard(
                        title: 'Live Quiz',
                        value: _liveQuizzes.toString(),
                        icon: Icons.wifi_tethering,
                        color: AppColors.success,
                        isDark: Theme.of(context).brightness == Brightness.dark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 130,
                child: Row(
                  children: [
                    Expanded(
                      child: RankXStatCard(
                        title: 'Total Users',
                        value: _totalUsers.toString(),
                        icon: Icons.people_alt,
                        color: AppColors.adminSecondary,
                        isDark: Theme.of(context).brightness == Brightness.dark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: RankXStatCard(
                        title: 'Avg Score',
                        value: _avgScore > 0
                            ? '${_avgScore.toStringAsFixed(1)}%'
                            : '0%',
                        icon: Icons.trending_up,
                        color: AppColors.warning,
                        isDark: Theme.of(context).brightness == Brightness.dark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 130,
                child: Row(
                  children: [
                    Expanded(
                      child: RankXStatCard(
                        title: 'Revenue',
                        value: '₹${_revenue.toStringAsFixed(0)}',
                        icon: Icons.attach_money,
                        color: AppColors.accent,
                        isDark: Theme.of(context).brightness == Brightness.dark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: RankXStatCard(
                        title: 'Active Accounts',
                        value: _accountsLive.toString(),
                        icon: Icons.verified_user,
                        color: AppColors.info,
                        isDark: Theme.of(context).brightness == Brightness.dark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        } else {
          // Tablet/Desktop: 2 columns using GridView
          return GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.8,
            children: [
              RankXStatCard(
                title: 'Total Quiz',
                value: _totalQuizzes.toString(),
                icon: Icons.assignment_outlined,
                color: AppColors.adminPrimary,
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
              RankXStatCard(
                title: 'Live Quiz',
                value: _liveQuizzes.toString(),
                icon: Icons.wifi_tethering,
                color: AppColors.success,
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
              RankXStatCard(
                title: 'Total Users',
                value: _totalUsers.toString(),
                icon: Icons.people_alt,
                color: AppColors.adminSecondary,
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
              RankXStatCard(
                title: 'Avg Score',
                value: _avgScore > 0
                    ? '${_avgScore.toStringAsFixed(1)}%'
                    : '0%',
                icon: Icons.trending_up,
                color: AppColors.warning,
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
              RankXStatCard(
                title: 'Revenue',
                value: '₹${_revenue.toStringAsFixed(0)}',
                icon: Icons.attach_money,
                color: AppColors.accent,
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
              RankXStatCard(
                title: 'Active Accounts',
                value: _accountsLive.toString(),
                icon: Icons.verified_user,
                color: AppColors.info,
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
            ],
          );
        }
      },
    );
  }

  Future<void> _loadStats() async {
    try {
      // Total users
      final usersRes = await supabaseService.client.from('users').select('id');
      _totalUsers = (usersRes as List).length;

      // Total quizzes
      final quizzesRes = await supabaseService.client
          .from('quizzes')
          .select('id');
      _totalQuizzes = (quizzesRes as List).length;

      // Live quizzes (published)
      final liveRes = await supabaseService.client
          .from('quizzes')
          .select('id')
          .eq('status', 'published');
      _liveQuizzes = (liveRes as List).length;

      // Avg score (average of total_points from user_points)
      final pointsRes = await supabaseService.client
          .from('user_points')
          .select('total_points');
      if (pointsRes.isNotEmpty) {
        final nums =
            pointsRes
                .map<double>((e) => (e['total_points'] ?? 0).toDouble())
                .toList();
        _avgScore = nums.reduce((a, b) => a + b) / nums.length;
      } else {
        _avgScore = 0;
      }

      // Revenue: sum completed payments.amount
      final paymentsRes = await supabaseService.client
          .from('payments')
          .select('amount, status');
      _revenue = paymentsRes
          .where((p) => (p['status'] ?? '') == 'completed')
          .map<double>((p) => (p['amount'] ?? 0).toDouble())
          .fold(0, (a, b) => a + b);

      // Accounts live (same as total users for now)
      _accountsLive = _totalUsers;
    } catch (_) {
      // Leave defaults on error
    } finally {
      if (mounted) {
        setState(() {
          _statsLoading = false;
        });
      }
    }
  }
}
