import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/models/quiz_model.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/points_service.dart';
import '../../../core/services/quiz_service.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/rankx_card.dart';
import '../../../core/widgets/rankx_common_widgets.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  final quizService = Get.find<QuizService>();
  final pointsService = Get.find<PointsService>();
  final authService = Get.find<AuthService>();

  String _selectedCategory = 'All';
  List<String> _categories = const ['All'];
  List<Quiz> _allQuizzes = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
    final userId = authService.currentUser.value?.id;
    if (userId != null) {
      pointsService.getUserPoints(userId);
    }
  }

  Future<void> _loadQuizzes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final quizzes = await quizService.getPublishedQuizzes();
      final cats = <String>{};
      for (final q in quizzes) {
        if (q.category.trim().isNotEmpty) cats.add(q.category.trim());
      }
      setState(() {
        _allQuizzes = quizzes;
        _categories = ['All', ...cats.toList()..sort()];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load quizzes: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleQuizzes =
        _selectedCategory == 'All'
            ? _allQuizzes
            : _allQuizzes
                .where((q) => q.category == _selectedCategory)
                .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quizzes'),
        actions: [
          Obx(() {
            final balance = pointsService.userPoints.value?.totalPoints ?? 0;
            return Container(
              margin: const EdgeInsets.only(right: AppSpacing.md),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Text(
                '💎 $balance',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            );
          }),
        ],
      ),
      body: Column(
        children: [
          // Curved top spacing
          const SizedBox(height: 20),
          // Category Filter with curved top
          CurvedTopContainer(
            topRadius: 30,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: FilterChip(
                      label: Text(
                        category,
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selected: isSelected,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      selectedColor: Theme.of(context).colorScheme.primary,
                      checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                      onSelected: (value) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Quiz List
          Expanded(
            child:
                _isLoading
                    ? const AppLoadingWidget(message: 'Loading quizzes...')
                    : _errorMessage != null
                    ? AppErrorWidget(
                      message: _errorMessage!,
                      onRetry: _loadQuizzes,
                    )
                    : visibleQuizzes.isEmpty
                    ? RankXEmptyState(
                      icon: Icons.quiz_outlined,
                      title: 'No quizzes found',
                      message:
                          _selectedCategory == 'All'
                              ? 'Admins will publish quizzes here. Check back soon!'
                              : 'No quizzes available in $_selectedCategory category.',
                    )
                    : RefreshIndicator(
                      onRefresh: _loadQuizzes,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        itemCount: visibleQuizzes.length,
                        itemBuilder:
                            (context, index) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: _buildQuizCard(visibleQuizzes[index]),
                            ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(Quiz quiz) {
    final costPoints = _requiredPoints(quiz);
    final difficultyLabel = _difficultyLabel(quiz.difficulty);

    return RankXQuizCard(
      title: quiz.title,
      description:
          quiz.description?.trim().isNotEmpty == true
              ? quiz.description!.trim()
              : null,
      category: quiz.category.trim().isNotEmpty ? quiz.category : null,
      difficulty: difficultyLabel,
      questionCount: quiz.totalQuestions,
      durationLabel: '${(quiz.durationSeconds / 60).round()} min',
      points: costPoints,
      totalMarks: quiz.totalMarks > 0 ? quiz.totalMarks : null,
      imageUrl: quiz.thumbnailUrl,
      onTap: () => _handleQuizTap(quiz),
    );
  }

  Future<void> _handleQuizTap(Quiz quiz) async {
    final userId = authService.currentUser.value?.id;
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login again.')));
      return;
    }

    // Ensure we have fresh points.
    await pointsService.getUserPoints(userId);
    final balance = pointsService.userPoints.value?.totalPoints ?? 0;
    final cost = _requiredPoints(quiz);

    if (!mounted) return;

    if (balance >= cost) {
      final ok = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Unlock Quiz'),
              content: Text('Spend $cost points to start "${quiz.title}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Start'),
                ),
              ],
            ),
      );

      if (ok != true) return;

      // Deduct and start quiz.
      final success = await pointsService.deductPoints(
        userId: userId,
        points: cost,
      );
      if (!success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              pointsService.errorMessage.value.isNotEmpty
                  ? pointsService.errorMessage.value
                  : 'Unable to deduct points.',
            ),
          ),
        );
        return;
      }

      if (!mounted) return;
      context.push(AppRoutes.quizTaking.replaceFirst(':quizId', quiz.id));
      return;
    }

    // Not enough points → take subscription/payment (₹ plans give points).
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Not enough points'),
            content: Text(
              'You need $cost points but you have $balance.\n\nBuy a subscription to get more points and start this quiz.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Later'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.push(
                    AppRoutes.payment.replaceFirst(':quizId', quiz.id),
                  );
                },
                child: const Text('Buy Subscription'),
              ),
            ],
          ),
    );
  }

  int _requiredPoints(Quiz quiz) {
    // Primary source: admin-defined quiz points.
    if (quiz.pointsCost > 0) return quiz.pointsCost;

    final difficulty = (quiz.difficulty ?? 1).clamp(1, 5);
    final perQuestion = (difficulty * 2);
    final derived = (quiz.totalQuestions * perQuestion).clamp(5, 500);
    return derived;
  }

  String _difficultyLabel(int? difficulty) {
    final d = difficulty ?? 0;
    if (d <= 2) return 'Easy';
    if (d == 3) return 'Medium';
    if (d >= 4) return 'Hard';
    return 'Mixed';
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'hard':
        return AppColors.error;
      default:
        return AppColors.textTertiary;
    }
  }
}
