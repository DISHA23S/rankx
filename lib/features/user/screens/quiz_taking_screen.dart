import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/models/question_model.dart';
import '../../../core/models/quiz_model.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/quiz_service.dart';
import '../../../core/services/quiz_result_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/quiz_security_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/quiz_security_overlay.dart';

class QuizTakingScreen extends StatefulWidget {
  final String quizId;

  const QuizTakingScreen({super.key, required this.quizId});

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  final quizService = Get.find<QuizService>();
  final quizResultService = Get.find<QuizResultService>();
  final authService = Get.find<AuthService>();
  final _securityService = QuizSecurityService();

  late Quiz _quiz;
  late List<Question> _questions;
  late Map<String, List<Answer>> _answersMap;
  
  int _currentQuestionIndex = 0;
  late int _timeRemaining;
  String? _selectedAnswerId;
  Map<int, String> _selectedAnswersMap = {}; // question index -> selected answer id
  bool _isLoading = true;
  String? _errorMessage;
  final Map<int, String> _selectedAnswerTexts = {}; // For tracking selected answer text
  bool _isSubmitting = false; // Prevent double submission

  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }
  
  @override
  void dispose() {
    // Disable security when leaving screen
    _securityService.disableQuizSecurity();
    super.dispose();
  }

  Future<void> _loadQuizData() async {
    try {
      // Fetch quiz details
      _quiz = (await quizService.getQuizById(widget.quizId))!;
      
      // Fetch questions
      _questions = await quizService.getQuestionsByQuiz(widget.quizId);
      
      if (_questions.isEmpty) {
        setState(() {
          _errorMessage = 'No questions found for this quiz';
          _isLoading = false;
        });
        return;
      }

      // Fetch answers for all questions
      _answersMap = {};
      for (var question in _questions) {
        final answers = await quizService.getAnswersByQuestion(question.id);
        _answersMap[question.id] = answers;
      }

      setState(() {
        _timeRemaining = _quiz.durationSeconds;
        _isLoading = false;
      });

      _startTimer();
      
      // Enable quiz security after quiz is loaded
      _enableQuizSecurity();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load quiz: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  /// Enable quiz security features
  Future<void> _enableQuizSecurity() async {
    await _securityService.enableQuizSecurity(
      context: context,
      onFirstWarning: _showFirstWarning,
      onSecondWarning: _showSecondWarning,
      onAutoSubmit: _handleAutoSubmit,
      onTabSwitch: _showTabSwitchWarning,
    );
  }
  
  /// Show first warning for screenshot/tab switch
  void _showFirstWarning() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => QuizSecurityWarningDialog(
        title: 'Warning #1',
        message: 'Screenshot detected! Please do not take screenshots during the quiz. This is your first warning.',
        onContinue: () => Navigator.of(context).pop(),
      ),
    );
  }
  
  /// Show second warning
  void _showSecondWarning() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => QuizSecurityWarningDialog(
        title: 'Final Warning',
        message: 'Second screenshot detected! This is your final warning. One more screenshot will automatically submit your quiz.',
        onContinue: () => Navigator.of(context).pop(),
      ),
    );
  }
  
  /// Handle auto-submit due to security violation
  void _handleAutoSubmit() {
    if (!mounted || _isSubmitting) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => QuizAutoSubmitDialog(
        message: 'You have violated quiz security rules too many times. Your quiz has been automatically submitted.',
      ),
    ).then((_) {
      _submitQuiz(isAutoSubmit: true);
    });
  }
  
  /// Show tab switch warning (Web only)
  void _showTabSwitchWarning() {
    if (!mounted) return;
    
    if (_securityService.tabSwitchCount == 1) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => QuizSecurityWarningDialog(
          title: 'Warning',
          message: 'Tab switching detected! Please stay on this tab during the quiz. Next violation will auto-submit your quiz.',
          onContinue: () => Navigator.of(context).pop(),
        ),
      );
    }
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
        _startTimer();
      } else if (_timeRemaining == 0 && mounted) {
        // Auto submit
        _submitQuiz();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const AppLoadingWidget(message: 'Loading quiz...'),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: AppErrorWidget(
          message: _errorMessage!,
          onRetry: () {
            setState(() => _isLoading = true);
            _loadQuizData();
          },
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: Text('No questions available')),
      );
    }

    final question = _questions[_currentQuestionIndex];
    final answers = _answersMap[question.id] ?? [];
    
    // Get user identifier for watermark
    final userEmail = authService.currentUser.value?.email ?? 'User';

    return QuizSecurityOverlay(
      userIdentifier: userEmail,
      showWatermark: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_quiz.title),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _showExitDialog,
          ),
        ),
      body: Column(
        children: [
          // Progress Bar and Timer
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.bgSecondary,
            child: Column(
              children: [
                // Progress
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Time: ${DateTimeUtil.formatDuration(_timeRemaining)}',
                          style: TextStyle(
                            color: _timeRemaining < 60
                                ? AppColors.error
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_currentQuestionIndex + 1) / _questions.length,
                        minHeight: 6,
                        backgroundColor: AppColors.borderLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Question Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question
                  Text(
                    question.questionText,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Options
                  if (answers.isNotEmpty)
                    ...answers.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _buildOptionButton(
                              answer: entry.value,
                              index: entry.key,
                              isSelected: _selectedAnswersMap[_currentQuestionIndex] == entry.value.id,
                            ),
                          ),
                        )
                  else
                    Center(
                      child: Text(
                        'No options available',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Navigation Buttons
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                if (_currentQuestionIndex > 0)
                  Expanded(
                    child: AppButton(
                      label: 'Previous',
                      onPressed: _goToPreviousQuestion,
                      type: ButtonType.secondary,
                    ),
                  ),
                if (_currentQuestionIndex > 0)
                  const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppButton(
                    label: _currentQuestionIndex == _questions.length - 1
                        ? 'Submit'
                        : 'Next',
                    onPressed: _currentQuestionIndex == _questions.length - 1
                        ? _submitQuiz
                        : _goToNextQuestion,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ), // End of Scaffold
    ); // End of QuizSecurityOverlay
  }

  Widget _buildOptionButton({
    required Answer answer,
    required int index,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAnswersMap[_currentQuestionIndex] = answer.id;
          _selectedAnswerTexts[_currentQuestionIndex] = answer.answerText;
          _selectedAnswerId = answer.id;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? AppColors.primaryLight.withOpacity(0.2) : AppColors.primaryLight)
              : (isDark ? AppColors.bgCardDark : AppColors.bgCard),
          border: Border.all(
            color: isSelected 
                ? (isDark ? AppColors.primaryLight : AppColors.primary)
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected 
                      ? (isDark ? AppColors.primaryLight : AppColors.primary)
                      : (isDark ? AppColors.borderDark : AppColors.borderDark),
                  width: 2,
                ),
              ),
              child: Center(
                child: isSelected
                    ? Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? AppColors.primaryLight : AppColors.primary,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                answer.answerText,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isSelected
                      ? (isDark 
                          ? AppColors.textPrimaryDark 
                          : AppColors.primary)  // Dark blue on light blue background for contrast
                      : (isDark 
                          ? AppColors.textPrimaryDark 
                          : AppColors.textPrimary),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToNextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerId = _selectedAnswersMap.containsKey(_currentQuestionIndex)
            ? _selectedAnswersMap[_currentQuestionIndex]
            : null;
      });
    }
  }

  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _selectedAnswerId = _selectedAnswersMap.containsKey(_currentQuestionIndex)
            ? _selectedAnswersMap[_currentQuestionIndex]
            : null;
      });
    }
  }

  Future<void> _submitQuiz({bool isAutoSubmit = false}) async {
    // Prevent double submission
    if (_isSubmitting) return;
    _isSubmitting = true;
    
    // Disable quiz security before submission
    await _securityService.disableQuizSecurity();
    
    try {
      int correctAnswers = 0;
      int marksObtained = 0;
      final int timeSpent = _quiz.durationSeconds - _timeRemaining;
      final List<Map<String, dynamic>> questionResults = [];

      // Calculate score and build question results
      for (int i = 0; i < _questions.length; i++) {
        final question = _questions[i];
        final selectedAnswerId = _selectedAnswersMap[i];

        if (selectedAnswerId != null) {
          final answers = _answersMap[question.id] ?? [];
          final selectedAnswer = answers.firstWhereOrNull((a) => a.id == selectedAnswerId);
          final correctAnswer = answers.firstWhereOrNull((a) => a.isCorrect);

          final isCorrect = selectedAnswer?.isCorrect ?? false;
          if (isCorrect) {
            correctAnswers++;
            marksObtained += question.marks;
          }

          questionResults.add({
            'question_id': question.id,
            'question_text': question.questionText,
            'selected_answer': selectedAnswer?.answerText,
            'correct_answer': correctAnswer?.answerText,
            'is_correct': isCorrect,
            'marks': question.marks,
            'time_spent_seconds': question.timeLimitSeconds,
          });
        } else {
          final correctAnswer = (_answersMap[question.id] ?? []).firstWhereOrNull((a) => a.isCorrect);
          questionResults.add({
            'question_id': question.id,
            'question_text': question.questionText,
            'selected_answer': null,
            'correct_answer': correctAnswer?.answerText,
            'is_correct': false,
            'marks': 0,
            'time_spent_seconds': 0,
          });
        }
      }

      final userId = authService.currentUser.value?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Save result to database
      final saved = await quizResultService.saveQuizResult(
        userId: userId,
        quizId: widget.quizId,
        totalQuestions: _questions.length,
        correctAnswers: correctAnswers,
        marksObtained: marksObtained,
        totalMarks: _quiz.totalMarks,
        timeTakenSeconds: timeSpent,
        maxTimeSeconds: _quiz.durationSeconds,
        questionResults: questionResults,
      );

      if (!saved) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Warning: Could not save result: ${quizResultService.errorMessage.value}')),
        );
      }

      final accuracy = _questions.isNotEmpty
          ? (correctAnswers / _questions.length * 100).toInt()
          : 0;

      // Navigate to result screen with data
      if (!mounted) return;
      context.pushReplacement(
        AppRoutes.quizResult.replaceFirst(':quizId', widget.quizId),
        extra: {
          'userId': userId,
          'correctAnswers': correctAnswers,
          'totalQuestions': _questions.length,
          'timeSpent': timeSpent,
          'marksObtained': marksObtained,
          'totalMarks': _quiz.totalMarks,
          'accuracy': accuracy,
          'questionResults': questionResults,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting quiz: ${e.toString()}')),
      );
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Quiz'),
        content: const Text('Are you sure you want to exit? Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
