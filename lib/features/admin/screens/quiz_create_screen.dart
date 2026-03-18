import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/quiz_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/supabase_service.dart';

class QuizCreateScreen extends StatefulWidget {
  final String? quizId;

  const QuizCreateScreen({super.key, this.quizId});

  @override
  State<QuizCreateScreen> createState() => _QuizCreateScreenState();
}

class _QuizCreateScreenState extends State<QuizCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final quizService = Get.find<QuizService>();
  final authService = Get.find<AuthService>();
  final supabaseService = Get.find<SupabaseService>();

  // Quiz basic info
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _pointsCostController = TextEditingController();
  int? _difficulty;

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();
  File? _quizImage;
  String? _quizImageUrl;

  // Questions
  final List<QuestionData> _questions = [];

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.quizId != null) {
      _loadQuiz();
    } else {
      // Add first question by default
      _addQuestion();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _pointsCostController.dispose();
    for (var question in _questions) {
      question.questionController.dispose();
      for (var option in question.options) {
        option.textController.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    // TODO: Load existing quiz for editing
  }

  Future<void> _pickQuizImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _quizImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<String?> _uploadQuizImage() async {
    if (_quizImage == null) return null;

    try {
      final adminId = supabaseService.getCurrentUserId();
      if (adminId == null) return null;

      final fileName = 'quiz_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'quiz_images/$adminId/$fileName';

      final bytes = await _quizImage!.readAsBytes();
      await supabaseService.client.storage
          .from('quiz-images')
          .uploadBinary(filePath, bytes);

      final imageUrl = supabaseService.client.storage
          .from('quiz-images')
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  void _addQuestion() {
    setState(() {
      _questions.add(QuestionData(
        questionController: TextEditingController(),
        timeLimitSeconds: 60, // Default 1 minute
        marks: 1,
        options: [
          OptionData(textController: TextEditingController(), isCorrect: false),
          OptionData(textController: TextEditingController(), isCorrect: false),
        ],
      ));
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions[index].questionController.dispose();
      for (var option in _questions[index].options) {
        option.textController.dispose();
      }
      _questions.removeAt(index);
    });
  }

  void _addOption(int questionIndex) {
    setState(() {
      _questions[questionIndex].options.add(
        OptionData(textController: TextEditingController(), isCorrect: false),
      );
    });
  }

  void _removeOption(int questionIndex, int optionIndex) {
    setState(() {
      _questions[questionIndex].options[optionIndex].textController.dispose();
      _questions[questionIndex].options.removeAt(optionIndex);
    });
  }

  void _setCorrectAnswer(int questionIndex, int optionIndex) {
    setState(() {
      // Unset all other options
      for (var option in _questions[questionIndex].options) {
        option.isCorrect = false;
      }
      // Set this option as correct
      _questions[questionIndex].options[optionIndex].isCorrect = true;
    });
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate questions
    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      if (question.questionController.text.trim().isEmpty) {
        _showError('Question ${i + 1}: Please enter question text');
        return;
      }
      if (question.options.length < 2) {
        _showError('Question ${i + 1}: Please add at least 2 options');
        return;
      }
      bool hasCorrectAnswer = false;
      for (var option in question.options) {
        if (option.textController.text.trim().isEmpty) {
          _showError('Question ${i + 1}: Please fill all options');
          return;
        }
        if (option.isCorrect) {
          hasCorrectAnswer = true;
        }
      }
      if (!hasCorrectAnswer) {
        _showError('Question ${i + 1}: Please mark one option as correct');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final adminId = supabaseService.getCurrentUserId();
      if (adminId == null) {
        throw Exception('Admin not logged in');
      }

      // Upload quiz image if selected
      String? uploadedImageUrl;
      if (_quizImage != null) {
        uploadedImageUrl = await _uploadQuizImage();
        if (uploadedImageUrl != null) {
          _quizImageUrl = uploadedImageUrl;
        }
      }

      // Prepare questions data
      final questionsData = _questions.map((q) {
        return {
          'questionText': q.questionController.text.trim(),
          'timeLimitSeconds': q.timeLimitSeconds,
          'marks': q.marks,
          'answers': q.options.map((opt) {
            return {
              'answerText': opt.textController.text.trim(),
              'isCorrect': opt.isCorrect,
            };
          }).toList(),
        };
      }).toList();

      final pointsCost = int.tryParse(_pointsCostController.text.trim()) ?? 0;
      if (pointsCost < 0) {
        _showError('Points cost must be 0 or greater');
        return;
      }

      final quizId = await quizService.createCompleteQuiz(
        adminId: adminId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        questions: questionsData,
        pointsCost: pointsCost,
        difficulty: _difficulty,
        imageUrl: _quizImageUrl,
      );

      if (quizId != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quiz created successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        _showError(quizService.errorMessage.value);
      }
    } catch (e) {
      _showError('Failed to create quiz: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quizId != null ? 'Edit Quiz' : 'Create Quiz'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quiz Basic Info
              _buildSectionTitle('Quiz Information'),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Quiz Title *',
                hintText: 'Enter quiz title',
                controller: _titleController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter quiz title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Description',
                hintText: 'Enter quiz description',
                controller: _descriptionController,
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.md),
              
              // Quiz Image Selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quiz Image (Optional)',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_quizImage != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          child: Image.file(
                            _quizImage!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: Icon(
                              Icons.close, 
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context).shadowColor.withOpacity(0.54),
                            ),
                            onPressed: () {
                              setState(() {
                                _quizImage = null;
                              });
                            },
                          ),
                        ),
                      ],
                    )
                  else
                    InkWell(
                      onTap: _pickQuizImage,
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.borderLight,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.bgCardDark
                              : AppColors.bgSecondary,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 48,
                                color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Tap to add quiz image',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Category *',
                hintText: 'e.g., Science, Math, History',
                controller: _categoryController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Points Cost (per quiz) *',
                      hintText: 'e.g., 50',
                      controller: _pointsCostController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter points cost';
                        }
                        final n = int.tryParse(value.trim());
                        if (n == null || n < 0) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Difficulty',
                        border: OutlineInputBorder(),
                      ),
                      value: _difficulty,
                      items: [1, 2, 3, 4, 5].map((level) {
                        return DropdownMenuItem(
                          value: level,
                          child: Text('Level $level'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _difficulty = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Questions Section
              Row(
                children: [
                  Expanded(
                    child: _buildSectionTitle('Questions (${_questions.length})'),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  SizedBox(
                    width: 120,
                    child: AppButton(
                      label: 'Add',
                      onPressed: _addQuestion,
                      icon: Icons.add,
                      type: ButtonType.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Questions List
              ...List.generate(_questions.length, (index) {
                return _buildQuestionCard(index);
              }),

              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Save Button
              AppButton(
                label: widget.quizId != null ? 'Update Quiz' : 'Create Quiz',
                onPressed: _isLoading ? null : _saveQuiz,
                isLoading: _isLoading,
                icon: Icons.save,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.primaryLight : AppColors.primary,
          ),
    );
  }

  Widget _buildQuestionCard(int questionIndex) {
    final question = _questions[questionIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AppCard(
      backgroundColor: isDark ? AppColors.bgCardDark : AppColors.bgCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  'Q${questionIndex + 1}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.error),
                onPressed: _questions.length > 1
                    ? () => _removeQuestion(questionIndex)
                    : null,
                tooltip: 'Remove Question',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Question Text
          AppTextField(
            label: 'Question Text *',
            hintText: 'Enter your question',
            controller: question.questionController,
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.md),

          // Time Limit + Marks
          Row(
            children: [
              Text(
                'Time: ',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
              Expanded(
                child: Slider(
                  value: question.timeLimitSeconds.toDouble(),
                  min: 10,
                  max: 300,
                  divisions: 29,
                  label: '${question.timeLimitSeconds}s',
                  onChanged: (value) {
                    setState(() {
                      question.timeLimitSeconds = value.toInt();
                    });
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '${question.timeLimitSeconds}s',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 100,
                child: DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'Marks',
                    labelStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  value: question.marks,
                  items: List.generate(20, (i) => i + 1)
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(
                              '$m',
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      question.marks = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Options',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () => _addOption(questionIndex),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Option'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Options List
          ...List.generate(question.options.length, (optionIndex) {
            return _buildOptionCard(questionIndex, optionIndex);
          }),

          if (question.options.length < 2)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'Add at least 2 options',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(int questionIndex, int optionIndex) {
    final option = _questions[questionIndex].options[optionIndex];
    final optionLetter = String.fromCharCode(65 + optionIndex); // A, B, C, D...

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: option.isCorrect
            ? AppColors.success.withOpacity(0.1)
            : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: option.isCorrect
              ? AppColors.success
              : AppColors.borderLight,
          width: option.isCorrect ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Option Letter Badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: option.isCorrect
                  ? AppColors.success
                  : AppColors.primary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Center(
              child: Text(
                optionLetter,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Option Text Field
          Expanded(
            child: TextFormField(
              controller: option.textController,
              decoration: InputDecoration(
                hintText: 'Enter option text',
                border: InputBorder.none,
                suffixIcon: option.isCorrect
                    ? const Icon(Icons.check_circle, color: AppColors.success)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Correct Answer Toggle
          IconButton(
            icon: Icon(
              option.isCorrect ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: option.isCorrect ? AppColors.success : AppColors.textTertiary,
            ),
            onPressed: () => _setCorrectAnswer(questionIndex, optionIndex),
            tooltip: 'Mark as Correct Answer',
          ),
          // Remove Option
          if (_questions[questionIndex].options.length > 2)
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.error),
              onPressed: () => _removeOption(questionIndex, optionIndex),
              tooltip: 'Remove Option',
            ),
        ],
      ),
    );
  }
}

// Helper Classes
class QuestionData {
  final TextEditingController questionController;
  int timeLimitSeconds;
  int marks;
  final List<OptionData> options;

  QuestionData({
    required this.questionController,
    required this.timeLimitSeconds,
    required this.marks,
    required this.options,
  });
}

class OptionData {
  final TextEditingController textController;
  bool isCorrect;

  OptionData({
    required this.textController,
    required this.isCorrect,
  });
}
