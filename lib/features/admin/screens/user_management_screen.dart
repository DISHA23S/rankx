import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/user_service.dart';
import '../../../core/models/subscription_plan_model.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/subscription_plan_service.dart';

class UserManagementScreen extends StatefulWidget {
  final bool showAppBar;

  const UserManagementScreen({super.key, this.showAppBar = true});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final userService = Get.find<UserService>();
  final SubscriptionPlanService planService = Get.put(SubscriptionPlanService());
  final _searchController = TextEditingController();

  List<UserWithStats> _allUsers = [];
  List<UserWithStats> _filteredUsers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    planService.fetchPlans();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await userService.getAllUsersWithStats();
      setState(() {
        _allUsers = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load users: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        _filteredUsers = _allUsers.where((userStats) {
          return userStats.user.name?.toLowerCase().contains(query) ?? false ||
              userStats.user.email.toLowerCase().contains(query) ||
              userStats.user.id.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _assignPoints(UserWithStats userStats) async {
    final pointsController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign Points to ${userStats.user.name ?? userStats.user.email}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Points: ${userStats.points?.totalPoints ?? 0}'),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: pointsController,
              decoration: const InputDecoration(
                labelText: 'Points to Add',
                hintText: 'Enter points',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (pointsController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );

    if (result == true && pointsController.text.isNotEmpty) {
      final points = int.tryParse(pointsController.text);
      if (points != null && points > 0) {
        final success = await userService.adminAssignPoints(
          userId: userStats.user.id,
          points: points,
        );
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully assigned $points points'),
                backgroundColor: AppColors.success,
              ),
            );
            _loadUsers();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(userService.errorMessage.value),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _assignSubscription(UserWithStats userStats) async {
    String? selectedPlanCode;

    final List<SubscriptionPlan> plans =
        planService.plans.isNotEmpty ? planService.plans.toList() : await planService.fetchPlans();
    final activePlans = plans.where((p) => p.isActive).toList(growable: false);
    if (activePlans.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active subscription plans found. Please create one first.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Assign Subscription to ${userStats.user.name ?? userStats.user.email}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Subscription Plan:'),
              const SizedBox(height: AppSpacing.md),
              ...activePlans.map(
                (plan) => RadioListTile<String>(
                  title: Text(plan.name),
                  subtitle: Text(
                    '₹${plan.price.toStringAsFixed(2)} • ${plan.durationDays} day(s) • ${plan.points} points',
                  ),
                  value: plan.code,
                  groupValue: selectedPlanCode,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedPlanCode = value;
                    });
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: selectedPlanCode != null
                  ? () => Navigator.pop(context, true)
                  : null,
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );

    if (result == true && selectedPlanCode != null) {
      final selectedPlan = activePlans.firstWhere((p) => p.code == selectedPlanCode);
      final success = await userService.adminAssignSubscription(
        userId: userStats.user.id,
        plan: selectedPlan.code,
        amount: selectedPlan.price,
      );
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription assigned successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadUsers();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(userService.errorMessage.value),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        // Curved top spacing
        const SizedBox(height: 20),
        // Search Bar with curved top
        CurvedTopContainer(
          topRadius: 30,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users by name, email, or ID...',
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Theme.of(context).iconTheme.color),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.bgCardDark
                  : AppColors.bgCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.borderLight,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.borderLight,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: 2.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
            ),
          ),
        ),

        // User List
        Expanded(
          child: _isLoading
              ? const AppLoadingWidget(message: 'Loading users...')
              : _errorMessage != null
                  ? AppErrorWidget(
                      message: _errorMessage!,
                      onRetry: _loadUsers,
                    )
                  : _filteredUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Theme.of(context).iconTheme.color?.withOpacity(0.3),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                _allUsers.isEmpty
                                    ? 'No users yet'
                                    : 'No users found',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                _allUsers.isEmpty
                                    ? 'Users will appear here once they register'
                                    : 'Try adjusting your search',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadUsers,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              return _buildUserCard(_filteredUsers[index]);
                            },
                          ),
                        ),
        ),
      ],
    );

    if (!widget.showAppBar) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
          TextButton.icon(
            onPressed: () => context.push(AppRoutes.subscriptionManagement),
            icon: const Icon(Icons.subscriptions_outlined),
            label: const Text('Manage Subscription'),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (value) {
              if (value == 'assign_all') {
                _assignSubscriptionToAllUsers();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'assign_all',
                child: Text('Assign Subscription to All Users'),
              ),
            ],
          ),
        ],
      ),
      body: body,
    );
  }

  Future<void> _assignSubscriptionToAllUsers() async {
    if (_allUsers.isEmpty) return;

    final Set<String> selectedPlanCodes = <String>{};

    final List<SubscriptionPlan> plans =
        planService.plans.isNotEmpty ? planService.plans.toList() : await planService.fetchPlans();
    final activePlans = plans.where((p) => p.isActive).toList(growable: false);
    if (activePlans.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active subscription plans found. Please create one first.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Assign Subscription to All Users'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Subscription Plan for all users:'),
              const SizedBox(height: AppSpacing.md),
              ...activePlans.map(
                (plan) => CheckboxListTile(
                  title: Text(plan.name),
                  subtitle: Text(
                    '₹${plan.price.toStringAsFixed(2)} • ${plan.durationDays} day(s) • ${plan.points} points',
                  ),
                  value: selectedPlanCodes.contains(plan.code),
                  onChanged: (checked) {
                    setDialogState(() {
                      if (checked == true) {
                        selectedPlanCodes.add(plan.code);
                      } else {
                        selectedPlanCodes.remove(plan.code);
                      }
                    });
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: selectedPlanCodes.isNotEmpty
                  ? () => Navigator.pop(context, true)
                  : null,
              child: const Text('Assign to All'),
            ),
          ],
        ),
      ),
    );

    if (result == true && selectedPlanCodes.isNotEmpty) {
      // Keep original list order (UI order) when applying
      final selectedPlans = activePlans
          .where((p) => selectedPlanCodes.contains(p.code))
          .toList(growable: false);
      for (final userStats in _allUsers) {
        for (final plan in selectedPlans) {
          await userService.adminAssignSubscription(
            userId: userStats.user.id,
            plan: plan.code,
            amount: plan.price,
          );
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Assigned ${selectedPlans.length} subscription(s) to all users'),
          backgroundColor: AppColors.success,
        ),
      );

      _loadUsers();
    }
  }

  Widget _buildUserCard(UserWithStats userStats) {
    final user = userStats.user;
    final points = userStats.points;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      backgroundColor: isDark ? AppColors.bgCardDark : AppColors.bgCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              // User Avatar with gradient
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.transparent,
                  child: Text(
                    (user.name?.isNotEmpty == true
                        ? user.name![0].toUpperCase()
                        : user.email[0].toUpperCase()),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name ?? 'No Name',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Role: ${user.role ?? 'user'}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'ID: ${user.id.substring(0, 8)}...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
              // Rank Badge with gradient
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events, color: Theme.of(context).colorScheme.onPrimary, size: 18),
                    const SizedBox(height: 2),
                    Text(
                      '${userStats.rank}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.md),

          // Stats Grid - Responsive with all live data (prevent overflow)
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final chipWidth = (availableWidth - (AppSpacing.sm * 2)) / 2; // 2 columns on mobile
              final isWide = availableWidth > 500;
              final columns = isWide ? 3 : 2;
              
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                alignment: WrapAlignment.start,
                children: [
                  SizedBox(
                    width: isWide ? null : chipWidth,
                    child: _buildStatChip(
                      Icons.emoji_events,
                      'Rank',
                      '${userStats.rank}',
                      AppColors.primary,
                    ),
                  ),
                  SizedBox(
                    width: isWide ? null : chipWidth,
                    child: _buildStatChip(
                      Icons.star,
                      'Total Marks',
                      '${userStats.totalMarks}',
                      AppColors.warning,
                    ),
                  ),
                  SizedBox(
                    width: isWide ? null : chipWidth,
                    child: _buildStatChip(
                      Icons.quiz,
                      'Quizzes',
                      '${userStats.quizzesTaken}',
                      AppColors.info,
                    ),
                  ),
                  SizedBox(
                    width: isWide ? null : chipWidth,
                    child: _buildStatChip(
                      Icons.credit_card,
                      'Points Used',
                      '${userStats.pointsUsed}',
                      AppColors.secondary,
                    ),
                  ),
                  SizedBox(
                    width: isWide ? null : chipWidth,
                    child: _buildStatChip(
                      Icons.payment,
                      'Payments',
                      '${userStats.totalPayments}',
                      AppColors.success,
                    ),
                  ),
                  SizedBox(
                    width: isWide ? null : chipWidth,
                    child: _buildStatChip(
                      Icons.attach_money,
                      'Spent',
                      '₹${userStats.totalSpent.toStringAsFixed(0)}',
                      AppColors.error,
                    ),
                  ),
                  SizedBox(
                    width: isWide ? null : chipWidth,
                    child: _buildStatChip(
                      Icons.stars,
                      'Total Points',
                      '${points?.totalPoints ?? 0}',
                      AppColors.accent,
                    ),
                  ),
                  SizedBox(
                    width: isWide ? null : chipWidth,
                    child: _buildStatChip(
                      Icons.access_time,
                      'Total Time',
                      _formatTime(userStats.totalTimeSpent),
                      AppColors.info,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Subscription Status
          if (userStats.hasActiveSubscription)
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.success.withOpacity(0.15),
                    AppColors.success.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Active Subscription: ${userStats.subscriptionPlan?.toUpperCase() ?? 'N/A'}',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (userStats.subscriptionEndDate != null)
                    Text(
                      'Until ${_formatDate(userStats.subscriptionEndDate!)}',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.warning.withOpacity(0.15),
                    AppColors.warning.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      'No Active Subscription',
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),

          // No per-user actions; subscriptions are managed globally
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, String value, Color accentColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      constraints: const BoxConstraints(
        minWidth: 100,
        maxWidth: double.infinity,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withOpacity(0.15),
            accentColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 14,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$label: ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                          fontSize: 12,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      return secs > 0 ? '${minutes}m ${secs}s' : '${minutes}m';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
  }
}
