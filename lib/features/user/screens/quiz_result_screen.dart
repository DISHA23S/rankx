import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/quiz_result_service.dart'
    show QuizResultService, LeaderboardEntry;
import '../../../core/services/auth_service.dart';
import '../../../core/models/quiz_result_model.dart';
import '../../../core/widgets/app_widgets.dart';

class QuizResultScreen extends StatefulWidget {
  final String quizId;

  const QuizResultScreen({super.key, required this.quizId});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  bool _showDetails = false;
  bool _showLeaderboard = false;
  final quizResultService = Get.find<QuizResultService>();
  final authService = Get.find<AuthService>();

  bool _isFetching = true;
  QuizResult? _fetchedResult;
  int _userRank = 0;
  int _userTotalMarks = 0;
  List<LeaderboardEntry> _leaderboard = [];
  bool _isLoadingLeaderboard = false;

  @override
  void initState() {
    super.initState();
    _fetchSavedResult();
    _loadUserRankAndLeaderboard();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload leaderboard when screen becomes visible to ensure fresh data
    if (!_isLoadingLeaderboard && _leaderboard.isEmpty) {
      _loadUserRankAndLeaderboard();
    }
  }

  Future<void> _fetchSavedResult() async {
    try {
      final userId = authService.currentUser.value?.id;
      if (userId == null) {
        _isFetching = false;
        setState(() {});
        return;
      }

      final attempts = await quizResultService.getUserQuizAttempts(
        userId,
        widget.quizId,
      );
      if (attempts.isNotEmpty) {
        _fetchedResult = attempts.first;
      }
    } catch (e) {
      // keep silent; service has errorMessage populated
    } finally {
      _isFetching = false;
      if (mounted) setState(() {});
    }
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
      // Get all users to show complete leaderboard (no limit to show everyone)
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
    // If we're still fetching the saved result, show a loader
    if (_isFetching) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quiz Results'),
          leading: const SizedBox(),
        ),
        body: const Center(child: AppLoadingWidget()),
      );
    }

    // Prefer fetched result from DB when available, otherwise fall back to route extras
    final extras =
        GoRouter.of(context).routerDelegate.currentConfiguration.extra
            as Map<String, dynamic>?;

    final int correctAnswers =
        _fetchedResult?.correctAnswers ??
        (extras?['correctAnswers'] as int? ?? 0);
    final int totalQuestions =
        _fetchedResult?.totalQuestions ??
        (extras?['totalQuestions'] as int? ?? 0);
    final int timeSpent =
        _fetchedResult?.timeTakenSeconds ?? (extras?['timeSpent'] as int? ?? 0);
    final int marksObtained =
        _fetchedResult?.marksObtained ??
        (extras?['marksObtained'] as int? ?? 0);
    final int totalMarks =
        _fetchedResult?.totalMarks ?? (extras?['totalMarks'] as int? ?? 0);

    final int accuracy =
        _fetchedResult != null
            ? _fetchedResult!.accuracy.toInt()
            : (() {
              final accuracyRaw = extras?['accuracy'];
              return accuracyRaw is double
                  ? accuracyRaw.toInt()
                  : (accuracyRaw as int? ?? 0);
            })();

    final List<dynamic> questionResults =
        _fetchedResult != null
            ? _fetchedResult!.questionResults
            : ((extras?['questionResults'] as List?) ?? []);

    final percentage =
        totalQuestions > 0
            ? (correctAnswers / totalQuestions * 100).toInt()
            : 0;
    final timeTaken = (timeSpent / 60).toStringAsFixed(1);
    final marksPercentage =
        totalMarks > 0 ? (marksObtained / totalMarks * 100).toInt() : 0;

    final performanceLevel = _getPerformanceLevel(accuracy);
    final theme = Theme.of(context);
    final currentUserId = authService.currentUser.value?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        leading: const SizedBox(),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Score Section with Rank
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Quiz Completed!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Performance Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: _getPerformanceColor(
                        performanceLevel,
                      ).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                        color: _getPerformanceColor(performanceLevel),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      performanceLevel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getPerformanceColor(performanceLevel),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // User Rank Display
                  if (_userRank > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onPrimary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        border: Border.all(
                          color: theme.colorScheme.onPrimary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            color: Colors.amber,
                            size: 24,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Rank: $_userRank',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                              Text(
                                'Total Marks: $_userTotalMarks',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimary
                                      .withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  // Accuracy Display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onPrimary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: theme.colorScheme.onPrimary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$percentage%',
                              style: theme.textTheme.displayLarge?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Accuracy',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 14,
                                color: theme.colorScheme.onPrimary.withOpacity(
                                  0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
            // Statistics Cards
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  // Main Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          label: 'Correct',
                          value: '$correctAnswers',
                          color: AppColors.success,
                          icon: Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _buildStatCard(
                          label: 'Incorrect',
                          value: '${totalQuestions - correctAnswers}',
                          color: AppColors.error,
                          icon: Icons.cancel,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          label: 'Time Taken',
                          value: '${timeTaken}m',
                          color: AppColors.info,
                          icon: Icons.timer,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _buildStatCard(
                          label: 'Marks',
                          value: '$marksObtained/$totalMarks',
                          color: AppColors.warning,
                          icon: Icons.star,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Leaderboard Section
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withOpacity(0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withOpacity(
                            Theme.of(context).brightness == Brightness.dark
                                ? 0.6
                                : 0.05,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            final wasExpanded = _showLeaderboard;
                            setState(() {
                              _showLeaderboard = !_showLeaderboard;
                            });
                            // Reload leaderboard when expanding to ensure fresh data
                            if (!wasExpanded && !_isLoadingLeaderboard) {
                              _loadUserRankAndLeaderboard();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.05),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(AppSpacing.radiusMd),
                                topRight: Radius.circular(AppSpacing.radiusMd),
                              ),
                            ),
                            child: Row(
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
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  _showLeaderboard
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_showLeaderboard) ...[
                          const Divider(height: 1),
                          if (_isLoadingLeaderboard)
                            const Padding(
                              padding: EdgeInsets.all(AppSpacing.xl),
                              child: AppLoadingWidget(),
                            )
                          else if (_leaderboard.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Text(
                                'No leaderboard data available',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                children: [
                                  // Top 3 Podium (only show if we have at least 3 entries)
                                  if (_leaderboard.length >= 3)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        // 2nd Place
                                        _buildPodiumEntry(
                                          _leaderboard[1],
                                          _leaderboard[1].rank,
                                          currentUserId,
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        // 1st Place
                                        _buildPodiumEntry(
                                          _leaderboard[0],
                                          _leaderboard[0].rank,
                                          currentUserId,
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        // 3rd Place
                                        _buildPodiumEntry(
                                          _leaderboard[2],
                                          _leaderboard[2].rank,
                                          currentUserId,
                                        ),
                                      ],
                                    )
                                  else if (_leaderboard.isNotEmpty)
                                    // Show available entries in a row if less than 3
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children:
                                          _leaderboard.map((user) {
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: AppSpacing.xs,
                                                  ),
                                              child: _buildPodiumEntry(
                                                user,
                                                user.rank,
                                                currentUserId,
                                              ),
                                            );
                                          }).toList(),
                                    ),
                                  const SizedBox(height: AppSpacing.lg),
                                  // Full Leaderboard List - show all users with their ranks
                                  ..._leaderboard.map((user) {
                                    final isCurrentUser =
                                        user.userId == currentUserId;
                                    return _buildLeaderboardRow(
                                      user,
                                      user.rank,
                                      isCurrentUser,
                                    );
                                  }),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Performance Chart
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Performance Metrics',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          height: 250,
                          child: PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  value: correctAnswers.toDouble(),
                                  title: '$correctAnswers\nCorrect',
                                  color: AppColors.success,
                                  titleStyle: Theme.of(
                                    context,
                                  ).textTheme.labelLarge?.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                  radius: 70,
                                ),
                                PieChartSectionData(
                                  value:
                                      (totalQuestions - correctAnswers)
                                          .toDouble(),
                                  title:
                                      '${totalQuestions - correctAnswers}\nIncorrect',
                                  color: AppColors.error,
                                  titleStyle: Theme.of(
                                    context,
                                  ).textTheme.labelLarge?.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                  radius: 70,
                                ),
                              ],
                              centerSpaceRadius: 50,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Detailed Analysis
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap:
                              () =>
                                  setState(() => _showDetails = !_showDetails),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Detailed Analysis',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Icon(
                                  _showDetails
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_showDetails) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              children: [
                                for (var i = 0; i < questionResults.length; i++)
                                  _buildQuestionRow(i + 1, questionResults[i]),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  // Action Buttons
                  AppButton(
                    label: 'Retake Quiz',
                    onPressed: () {
                      context.go(
                        AppRoutes.quizTaking.replaceFirst(
                          ':quizId',
                          widget.quizId,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Back to Quizzes',
                    onPressed: () => context.go(AppRoutes.quizList),
                    type: ButtonType.secondary,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ],
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

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumEntry(
    LeaderboardEntry entry,
    int position,
    String? currentUserId,
  ) {
    final isCurrentUser = entry.userId == currentUserId;
    final colors = [
      Colors.amber, // 1st
      Colors.grey.shade400, // 2nd
      Colors.brown.shade400, // 3rd
    ];
    final heights = [120.0, 90.0, 70.0];

    return Column(
      children: [
        Container(
          width: 80,
          height: heights[position - 1],
          decoration: BoxDecoration(
            color: colors[position - 1],
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
                    position == 1
                        ? AppColors.textLight
                        : position == 2
                        ? Colors.grey.shade800
                        : Colors.brown.shade800,
                size: 32,
              ),
              const SizedBox(height: 4),
              Text(
                '$position',
                style: TextStyle(
                  color:
                      position == 1
                          ? AppColors.textLight
                          : position == 2
                          ? Colors.grey.shade800
                          : Colors.brown.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 80,
          padding: const EdgeInsets.all(8),
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
            children: [
              Text(
                entry.userName.length > 8
                    ? '${entry.userName.substring(0, 8)}...'
                    : entry.userName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color:
                      isCurrentUser
                          ? AppColors.textLight
                          : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${entry.totalMarks} pts',
                style: TextStyle(
                  fontSize: 11,
                  color:
                      isCurrentUser
                          ? AppColors.textLight
                          : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (entry.totalTimeSeconds > 0) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer,
                      size: 10,
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
                        fontSize: 9,
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
                  color:
                      rank <= 3
                          ? Theme.of(context).colorScheme.onPrimary
                          : AppColors.primary,
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color:
                              isCurrentUser
                                  ? AppColors.textLight
                                  : Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.9),
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
                Row(
                  children: [
                    Icon(Icons.star, size: 14, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.totalMarks} Total Marks',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isCurrentUser
                                ? AppColors.textLight
                                : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Icon(Icons.quiz, size: 14, color: AppColors.info),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.totalQuizzes} Quizzes',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isCurrentUser
                                ? AppColors.primary
                                : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                if (entry.totalTimeSeconds > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.timer, size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        'Total Time: ${_formatTime(entry.totalTimeSeconds)}',
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              isCurrentUser
                                  ? AppColors.primary
                                  : Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionRow(int index, dynamic item) {
    String questionText = '';
    String? selected;
    String? correct;
    bool isCorrect = false;
    int marks = 0;

    if (item is Map) {
      questionText = item['question_text']?.toString() ?? 'Question $index';
      selected = item['selected_answer']?.toString();
      correct = item['correct_answer']?.toString();
      isCorrect = item['is_correct'] == true;
      marks = (item['marks'] as num?)?.toInt() ?? 0;
    } else {
      try {
        questionText = item.questionText ?? 'Question $index';
        selected = item.selectedAnswer;
        correct = item.correctAnswer;
        isCorrect = item.isCorrect ?? false;
        marks = item.marks ?? 0;
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isCorrect ? AppColors.success : AppColors.error,
            child: Icon(
              isCorrect ? Icons.check : Icons.close,
              size: 18,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Q$index. $questionText',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Your answer: ${selected ?? '-'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isCorrect ? AppColors.success : AppColors.error,
                  ),
                ),
                Text(
                  'Correct answer: ${correct ?? '-'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+$marks',
              style: TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPerformanceLevel(int percentage) {
    if (percentage >= 90) return 'Outstanding';
    if (percentage >= 80) return 'Excellent';
    if (percentage >= 70) return 'Good';
    if (percentage >= 60) return 'Satisfactory';
    if (percentage >= 50) return 'Average';
    return 'Needs Improvement';
  }

  Color _getPerformanceColor(String level) {
    switch (level) {
      case 'Outstanding':
      case 'Excellent':
        return AppColors.success;
      case 'Good':
      case 'Satisfactory':
        return AppColors.warning;
      case 'Average':
      case 'Needs Improvement':
        return AppColors.error;
      default:
        return AppColors.textTertiary;
    }
  }
}
