import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/quiz_result_service.dart'
    show QuizResultService, LeaderboardEntry;
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/rankx_stat_widgets.dart';
import '../../../core/widgets/rankx_card.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final quizResultService = Get.find<QuizResultService>();
  final authService = Get.find<AuthService>();

  int _userRank = 0;
  int _userTotalMarks = 0;
  List<LeaderboardEntry> _leaderboard = [];
  bool _isLoadingLeaderboard = false;

  @override
  void initState() {
    super.initState();
    _loadUserRankAndLeaderboard();
  }

  Future<void> _loadUserRankAndLeaderboard() async {
    final userId = authService.currentUser.value?.id;
    if (userId == null) return;

    setState(() {
      _isLoadingLeaderboard = true;
    });

    try {
      _userRank = await quizResultService.getUserRankByMarks(userId);
      _userTotalMarks = await quizResultService.getUserTotalMarks(userId);
      // Get all users to show complete leaderboard
      _leaderboard = await quizResultService.getLeaderboardByMarks(limit: 1000);
    } catch (e) {
      // Handle error silently
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLeaderboard = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = authService.currentUser.value?.id;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress & Leaderboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserRankAndLeaderboard,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserRankAndLeaderboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // User Stats Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Your Progress',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // User Rank Display
                    if (_userRank > 0)
                      _buildProfileHighlight(
                        icon: Icons.emoji_events,
                        iconColor: Colors.amber,
                        label: 'Global Rank',
                        value: '$_userRank',
                      ),
                    if (_userRank > 0) const SizedBox(height: AppSpacing.md),
                    _buildProfileHighlight(
                      icon: Icons.stars,
                      iconColor: Colors.lightBlueAccent,
                      label: 'Total Marks',
                      value: _userTotalMarks.toString(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),

              // Leaderboard Section
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.leaderboard,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Leaderboard',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (_isLoadingLeaderboard)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (_isLoadingLeaderboard)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Center(child: AppLoadingWidget()),
                      )
                    else if (_leaderboard.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Center(
                          child: Text(
                            'No leaderboard data available',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          // Top 3 Podium (only show if we have at least 3 entries)
                          if (_leaderboard.length >= 3)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth > 400;
                                final podiumWidth =
                                    isWide
                                        ? 80.0
                                        : (constraints.maxWidth / 3) - 16;
                                return Container(
                                  margin: const EdgeInsets.only(
                                    bottom: AppSpacing.lg,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // 2nd Place
                                      SizedBox(
                                        width: podiumWidth,
                                        child: _buildPodiumEntry(
                                          _leaderboard[1],
                                          _leaderboard[1].rank,
                                          currentUserId,
                                          podiumWidth,
                                        ),
                                      ),
                                      SizedBox(
                                        width: isWide ? AppSpacing.sm : 4,
                                      ),
                                      // 1st Place
                                      SizedBox(
                                        width: podiumWidth,
                                        child: _buildPodiumEntry(
                                          _leaderboard[0],
                                          _leaderboard[0].rank,
                                          currentUserId,
                                          podiumWidth,
                                        ),
                                      ),
                                      SizedBox(
                                        width: isWide ? AppSpacing.sm : 4,
                                      ),
                                      // 3rd Place
                                      SizedBox(
                                        width: podiumWidth,
                                        child: _buildPodiumEntry(
                                          _leaderboard[2],
                                          _leaderboard[2].rank,
                                          currentUserId,
                                          podiumWidth,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          else if (_leaderboard.isNotEmpty)
                            // Show available entries in a row if less than 3
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final availableWidth = constraints.maxWidth;
                                final entryCount = _leaderboard.length;
                                final podiumWidth =
                                    entryCount > 0
                                        ? (availableWidth / entryCount) -
                                            (AppSpacing.xs * 2 * entryCount)
                                        : 80.0;
                                return Container(
                                  margin: const EdgeInsets.only(
                                    bottom: AppSpacing.lg,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children:
                                        _leaderboard.map((user) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.xs,
                                            ),
                                            child: SizedBox(
                                              width: podiumWidth,
                                              child: _buildPodiumEntry(
                                                user,
                                                user.rank,
                                                currentUserId,
                                                podiumWidth,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                );
                              },
                            ),
                          // Full Leaderboard List - show all users with their ranks
                          ..._leaderboard.map((user) {
                            final isCurrentUser = user.userId == currentUserId;
                            return _buildLeaderboardRow(
                              user,
                              user.rank,
                              isCurrentUser,
                            );
                          }),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    if (seconds == 0) return '0s';

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  Widget _buildPodiumEntry(
    LeaderboardEntry entry,
    int rank,
    String? currentUserId,
    double width,
  ) {
    final isCurrentUser = entry.userId == currentUserId;
    final colors = [
      Colors.amber, // 1st
      Colors.grey.shade400, // 2nd
      Colors.brown.shade400, // 3rd
    ];
    final heights = [120.0, 90.0, 70.0];
    final rankIndex = rank <= 3 ? rank - 1 : 2;
    final isWide = width > 70;

    return Column(
      children: [
        Container(
          width: width,
          height: heights[rankIndex] * (isWide ? 1.0 : 0.8),
          decoration: BoxDecoration(
            color: rank <= 3 ? colors[rankIndex] : Colors.grey.shade300,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border:
                isCurrentUser
                    ? Border.all(color: AppColors.primary, width: 3)
                    : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events,
                color:
                    rank == 1
                        ? AppColors.textLight
                        : rank == 2
                        ? Colors.grey.shade800
                        : Colors.brown.shade800,
                size: 32,
              ),
              const SizedBox(height: 4),
              Text(
                '$rank',
                style: TextStyle(
                  color:
                      rank == 1
                          ? AppColors.textLight
                          : rank == 2
                          ? Colors.grey.shade800
                          : Colors.brown.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: width,
          padding: EdgeInsets.all(isWide ? 8 : 6),
          decoration: BoxDecoration(
            color:
                isCurrentUser
                    ? AppColors.primaryLight
                    : Theme.of(context).cardColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            border:
                isCurrentUser
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry.userName.length > (isWide ? 8 : 6)
                    ? '${entry.userName.substring(0, isWide ? 8 : 6)}...'
                    : entry.userName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isWide ? 12 : 10,
                  color:
                      isCurrentUser
                          ? AppColors.textLight
                          : Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${entry.totalMarks} pts',
                  style: TextStyle(
                    fontSize: isWide ? 11 : 10,
                    color:
                        isCurrentUser
                            ? AppColors.textLight
                            : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (entry.totalTimeSeconds > 0) ...[
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer,
                        size: isWide ? 10 : 8,
                        color:
                            isCurrentUser
                                ? AppColors.primary
                                : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        _formatTime(entry.totalTimeSeconds),
                        style: TextStyle(
                          fontSize: isWide ? 9 : 8,
                          color:
                              isCurrentUser
                                  ? AppColors.primary
                                  : Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardRow(
    LeaderboardEntry entry,
    int rank,
    bool isCurrentUser,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:
            isCurrentUser
                ? AppColors.primaryLight
                : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color:
              isCurrentUser
                  ? AppColors.primary
                  : Theme.of(context).dividerColor,
          width: isCurrentUser ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  rank <= 3
                      ? (rank == 1
                          ? Colors.amber
                          : rank == 2
                          ? Colors.grey.shade400
                          : Colors.brown.shade400)
                      : AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              border:
                  isCurrentUser
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: rank <= 3 
                    ? Theme.of(context).colorScheme.onPrimary 
                    : Theme.of(context).colorScheme.primary,
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color:
                              isCurrentUser
                                  ? AppColors.textLight
                                  : Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    if (isCurrentUser)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 300;
                    if (isWide) {
                      return Row(
                        children: [
                          Icon(Icons.star, size: 14, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            '${entry.totalMarks} Total Marks',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  isCurrentUser
                                      ? AppColors.textLight
                                      : Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withOpacity(0.75),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Icon(Icons.quiz, size: 14, color: AppColors.info),
                          const SizedBox(width: 4),
                          Text(
                            '${entry.totalQuizzes} Quizzes',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  isCurrentUser
                                      ? AppColors.textLight
                                      : Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withOpacity(0.75),
                            ),
                          ),
                          if (entry.totalTimeSeconds > 0) ...[
                            const SizedBox(width: AppSpacing.md),
                            Icon(
                              Icons.timer,
                              size: 14,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(entry.totalTimeSeconds),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    isCurrentUser
                                        ? AppColors.textLight
                                        : Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withOpacity(0.75),
                              ),
                            ),
                          ],
                        ],
                      );
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 12,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${entry.totalMarks} Marks',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isCurrentUser
                                          ? AppColors.textLight
                                          : Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.color
                                              ?.withOpacity(0.75),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.quiz, size: 12, color: AppColors.info),
                              const SizedBox(width: 4),
                              Text(
                                '${entry.totalQuizzes} Quizzes',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isCurrentUser
                                          ? AppColors.textLight
                                          : Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.color
                                              ?.withOpacity(0.75),
                                ),
                              ),
                            ],
                          ),
                          if (entry.totalTimeSeconds > 0) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.timer,
                                  size: 12,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTime(entry.totalTimeSeconds),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        isCurrentUser
                                            ? AppColors.textLight
                                            : Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color
                                                ?.withOpacity(0.75),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHighlight({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(icon, color: iconColor, size: AppSpacing.iconMd),
        ),
        const SizedBox(width: AppSpacing.md),
        const SizedBox(width: AppSpacing.sm),
        RankXProfileStat(
          label: label,
          value: value,
          valueColor: Theme.of(context).colorScheme.onPrimary,
          labelColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
        ),
      ],
    );
  }
}
