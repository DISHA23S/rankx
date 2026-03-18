import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/quiz_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/models/quiz_model.dart';
import '../../../core/routes/app_router.dart';

class QuizManagementScreen extends StatefulWidget {
  const QuizManagementScreen({super.key});

  @override
  State<QuizManagementScreen> createState() => _QuizManagementScreenState();
}

class _QuizManagementScreenState extends State<QuizManagementScreen> {
  final quizService = Get.find<QuizService>();
  final authService = Get.find<AuthService>();
  final supabaseService = Get.find<SupabaseService>();
  final _searchController = TextEditingController();

  List<Quiz> _allQuizzes = [];
  List<Quiz> _filteredQuizzes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
    _searchController.addListener(_filterQuizzes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadQuizzes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final adminId = supabaseService.getCurrentUserId();
      if (adminId == null) {
        throw Exception('Admin not logged in');
      }

      final quizzes = await quizService.getAdminQuizzes(adminId);
      setState(() {
        _allQuizzes = quizzes;
        _filteredQuizzes = quizzes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load quizzes: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _filterQuizzes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredQuizzes = _allQuizzes;
      } else {
        _filteredQuizzes = _allQuizzes.where((quiz) {
          return quiz.title.toLowerCase().contains(query) ||
              (quiz.description?.toLowerCase().contains(query) ?? false) ||
              quiz.category.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _deleteQuiz(Quiz quiz) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: Text('Are you sure you want to delete "${quiz.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await quizService.deleteQuiz(quiz.id);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quiz deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadQuizzes();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(quizService.errorMessage.value),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _publishQuiz(Quiz quiz) async {
    final success = await quizService.publishQuiz(quiz.id);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quiz published successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadQuizzes();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(quizService.errorMessage.value),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _archiveQuiz(Quiz quiz) async {
    final success = await quizService.archiveQuiz(quiz.id);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quiz archived successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadQuizzes();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(quizService.errorMessage.value),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Quizzes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuizzes,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search quizzes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ),

          // Create Quiz Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: AppButton(
              label: 'Create New Quiz',
              onPressed: () async {
                final result = await context.push(AppRoutes.quizCreate);
                if (result == true) {
                  _loadQuizzes();
                }
              },
              icon: Icons.add,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Quiz List
          Expanded(
            child: _isLoading
                ? const AppLoadingWidget(message: 'Loading quizzes...')
                : _errorMessage != null
                    ? AppErrorWidget(
                        message: _errorMessage!,
                        onRetry: _loadQuizzes,
                      )
                    : _filteredQuizzes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.quiz_outlined,
                                  size: 64,
                                  color: AppColors.textTertiary,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  _allQuizzes.isEmpty
                                      ? 'No quizzes yet'
                                      : 'No quizzes found',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  _allQuizzes.isEmpty
                                      ? 'Create your first quiz to get started'
                                      : 'Try adjusting your search',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (_allQuizzes.isEmpty) ...[
                                  const SizedBox(height: AppSpacing.lg),
                                  AppButton(
                                    label: 'Create Quiz',
                                    onPressed: () async {
                                      final result = await context.push(AppRoutes.quizCreate);
                                      if (result == true) {
                                        _loadQuizzes();
                                      }
                                    },
                                    width: 150,
                                  ),
                                ],
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadQuizzes,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.lg,
                              ),
                              itemCount: _filteredQuizzes.length,
                              itemBuilder: (context, index) {
                                return _buildQuizCard(_filteredQuizzes[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(Quiz quiz) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AppCard(
      backgroundColor: isDark ? AppColors.bgCardDark : AppColors.bgCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quiz Image if available
          if (quiz.thumbnailUrl != null && quiz.thumbnailUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Image.network(
                quiz.thumbnailUrl!,
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
          
          // Header Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    if (quiz.description != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        quiz.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildStatusBadge(quiz.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Quiz Details
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _buildInfoChip(
                Icons.category,
                quiz.category,
              ),
              _buildInfoChip(
                Icons.help_outline,
                '${quiz.totalQuestions} Questions',
              ),
              _buildInfoChip(
                Icons.timer_outlined,
                '${(quiz.durationSeconds / 60).toStringAsFixed(0)} min',
              ),
              if (quiz.pointsCost > 0)
                _buildInfoChip(
                  Icons.emoji_events_outlined,
                  '${quiz.pointsCost} pts',
                ),
              if (quiz.totalMarks > 0)
                _buildInfoChip(
                  Icons.flag_outlined,
                  '${quiz.totalMarks} marks',
                ),
              if (quiz.difficulty != null)
                _buildInfoChip(
                  Icons.star,
                  'Level ${quiz.difficulty}',
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Actions
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.end,
            children: [
              if (quiz.status == 'draft')
                TextButton.icon(
                  onPressed: () => _publishQuiz(quiz),
                  icon: const Icon(Icons.publish, size: 18),
                  label: const Text('Publish'),
                ),
              if (quiz.status == 'published')
                TextButton.icon(
                  onPressed: () => _archiveQuiz(quiz),
                  icon: const Icon(Icons.archive, size: 18),
                  label: const Text('Archive'),
                ),
              TextButton.icon(
                onPressed: () async {
                  final result = await context.push('/admin/quiz-edit/${quiz.id}');
                  if (result == true) {
                    _loadQuizzes();
                  }
                },
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                onPressed: () => _deleteQuiz(quiz),
                icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
                label: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case 'published':
        color = AppColors.success;
        icon = Icons.check_circle;
        label = 'Published';
        break;
      case 'archived':
        color = AppColors.textTertiary;
        icon = Icons.archive;
        label = 'Archived';
        break;
      default:
        color = AppColors.warning;
        icon = Icons.edit;
        label = 'Draft';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCardDark : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: isDark ? Border.all(color: AppColors.textTertiaryDark.withOpacity(0.3)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
