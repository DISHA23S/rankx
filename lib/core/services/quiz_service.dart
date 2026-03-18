import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../models/quiz_model.dart';
import '../models/question_model.dart';
import 'supabase_service.dart';

class QuizService extends GetxService {
  late final SupabaseService supabaseService;
  
  @override
  void onInit() {
    super.onInit();
    supabaseService = Get.find<SupabaseService>();
  }
  
  final RxList<Quiz> quizzes = RxList<Quiz>();
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Create Quiz
  Future<bool> createQuiz({
    required String adminId,
    required String title,
    required String description,
    required String category,
    required int totalQuestions,
    required int durationSeconds,
    int pointsCost = 0,
    int totalMarks = 0,
    double? price, // legacy
    int? difficulty,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      await supabaseService.insert(
        table: AppConstants.quizzesTable,
        data: [
          {
            'admin_id': adminId,
            'title': title,
            'description': description,
            'category': category,
            'total_questions': totalQuestions,
            'duration_seconds': durationSeconds,
            // Points-based unlock
            'points_cost': pointsCost,
            'total_marks': totalMarks,
            // Legacy
            'price': price,
            'is_paid': false,
            'status': 'draft',
            'difficulty': difficulty,
            'created_at': DateTime.now().toIso8601String(),
          }
        ],
      );
      isLoading.value = false;
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to create quiz: ${e.toString()}';
      isLoading.value = false;
      return false;
    }
  }

  // Get Quizzes by Admin
  Future<List<Quiz>> getAdminQuizzes(String adminId) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final data = await supabaseService.query(
        table: AppConstants.quizzesTable,
        filters: {'admin_id': adminId},
        orderBy: 'created_at',
        ascending: false,
      );
      
      final quizzesData = data.map((e) => Quiz.fromJson(e)).toList();
      quizzes.value = quizzesData;
      isLoading.value = false;
      return quizzesData;
    } catch (e) {
      errorMessage.value = 'Failed to fetch quizzes: ${e.toString()}';
      isLoading.value = false;
      return [];
    }
  }

  // Get Published Quizzes
  Future<List<Quiz>> getPublishedQuizzes({String? category}) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
        dynamic queryBuilder = supabaseService.client
          .from(AppConstants.quizzesTable)
          .select()
          .eq('status', 'published');
      
      if (category != null) {
        queryBuilder = queryBuilder.eq('category', category);
      }

      queryBuilder = queryBuilder.order('created_at', ascending: false);
      
      final data = await queryBuilder;
      final quizzesData = (data as List).map((e) => Quiz.fromJson(e as Map<String, dynamic>)).toList();
      quizzes.value = quizzesData;
      isLoading.value = false;
      return quizzesData;
    } catch (e) {
      errorMessage.value = 'Failed to fetch quizzes: ${e.toString()}';
      isLoading.value = false;
      return [];
    }
  }

  // Get Quiz by ID
  Future<Quiz?> getQuizById(String quizId) async {
    try {
      final data = await supabaseService.querySingle(
        table: AppConstants.quizzesTable,
        filters: {'id': quizId},
      );
      return Quiz.fromJson(data);
    } catch (e) {
      errorMessage.value = 'Failed to fetch quiz: ${e.toString()}';
      return null;
    }
  }

  // Update Quiz
  Future<bool> updateQuiz({
    required String quizId,
    String? title,
    String? description,
    int? totalQuestions,
    int? durationSeconds,
    String? category,
  }) async {
    try {
      await supabaseService.update(
        table: AppConstants.quizzesTable,
        data: {
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (totalQuestions != null) 'total_questions': totalQuestions,
          if (durationSeconds != null) 'duration_seconds': durationSeconds,
          if (category != null) 'category': category,
          'updated_at': DateTime.now().toIso8601String(),
        },
        columnName: 'id',
        columnValue: quizId,
      );
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to update quiz: ${e.toString()}';
      return false;
    }
  }

  // Publish Quiz
  Future<bool> publishQuiz(String quizId) async {
    try {
      await supabaseService.update(
        table: AppConstants.quizzesTable,
        data: {
          'status': 'published',
          'published_at': DateTime.now().toIso8601String(),
        },
        columnName: 'id',
        columnValue: quizId,
      );
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to publish quiz: ${e.toString()}';
      return false;
    }
  }

  // Archive Quiz
  Future<bool> archiveQuiz(String quizId) async {
    try {
      await supabaseService.update(
        table: AppConstants.quizzesTable,
        data: {'status': 'archived'},
        columnName: 'id',
        columnValue: quizId,
      );
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to archive quiz: ${e.toString()}';
      return false;
    }
  }

  // Delete Quiz
  Future<bool> deleteQuiz(String quizId) async {
    try {
      await supabaseService.delete(
        table: AppConstants.quizzesTable,
        columnName: 'id',
        columnValue: quizId,
      );
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to delete quiz: ${e.toString()}';
      return false;
    }
  }

  // Get Questions by Quiz
  Future<List<Question>> getQuestionsByQuiz(String quizId) async {
    try {
      final data = await supabaseService.query(
        table: AppConstants.questionsTable,
        filters: {'quiz_id': quizId},
        orderBy: 'question_number',
      );
      return data.map((e) => Question.fromJson(e)).toList();
    } catch (e) {
      errorMessage.value = 'Failed to fetch questions: ${e.toString()}';
      return [];
    }
  }

  // Create Question with Answers
  Future<String?> createQuestionWithAnswers({
    required String quizId,
    required String questionText,
    required int questionNumber,
    required int timeLimitSeconds,
    int marks = 1,
    required List<Map<String, dynamic>> answers, // [{answerText, isCorrect, explanation?}]
    String? imageUrl,
  }) async {
    try {
      // Create question
      final questionResult = await supabaseService.insert(
        table: AppConstants.questionsTable,
        data: [
          {
            'quiz_id': quizId,
            'question_text': questionText,
            'question_number': questionNumber,
            'marks': marks,
            'time_limit_seconds': timeLimitSeconds,
            if (imageUrl != null) 'image_url': imageUrl,
            'created_at': DateTime.now().toIso8601String(),
          }
        ],
      );
      
      if (questionResult.isEmpty) {
        throw Exception('Failed to create question');
      }
      
      final questionId = questionResult[0]['id'] as String;
      
      // Create answers
      final answersData = answers.asMap().entries.map((entry) {
        final index = entry.key;
        final answer = entry.value;
        return {
          'question_id': questionId,
          'answer_text': answer['answerText'] as String,
          'answer_number': index + 1,
          'is_correct': answer['isCorrect'] as bool,
          if (answer['explanation'] != null) 'explanation': answer['explanation'] as String,
          'created_at': DateTime.now().toIso8601String(),
        };
      }).toList();
      
      await supabaseService.insert(
        table: AppConstants.answersTable,
        data: answersData,
      );
      
      return questionId;
    } catch (e) {
      errorMessage.value = 'Failed to create question: ${e.toString()}';
      return null;
    }
  }

  // Update Question
  Future<bool> updateQuestion({
    required String questionId,
    String? questionText,
    int? timeLimitSeconds,
    String? imageUrl,
  }) async {
    try {
      await supabaseService.update(
        table: AppConstants.questionsTable,
        data: {
          if (questionText != null) 'question_text': questionText,
          if (timeLimitSeconds != null) 'time_limit_seconds': timeLimitSeconds,
          if (imageUrl != null) 'image_url': imageUrl,
          'updated_at': DateTime.now().toIso8601String(),
        },
        columnName: 'id',
        columnValue: questionId,
      );
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to update question: ${e.toString()}';
      return false;
    }
  }

  // Delete Question (cascade will delete answers)
  Future<bool> deleteQuestion(String questionId) async {
    try {
      await supabaseService.delete(
        table: AppConstants.questionsTable,
        columnName: 'id',
        columnValue: questionId,
      );
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to delete question: ${e.toString()}';
      return false;
    }
  }

  // Get Answers by Question
  Future<List<Answer>> getAnswersByQuestion(String questionId) async {
    try {
      final data = await supabaseService.query(
        table: AppConstants.answersTable,
        filters: {'question_id': questionId},
        orderBy: 'answer_number',
      );
      return data.map((e) => Answer.fromJson(e)).toList();
    } catch (e) {
      errorMessage.value = 'Failed to fetch answers: ${e.toString()}';
      return [];
    }
  }

  // Update Answer
  Future<bool> updateAnswer({
    required String answerId,
    String? answerText,
    bool? isCorrect,
    String? explanation,
  }) async {
    try {
      await supabaseService.update(
        table: AppConstants.answersTable,
        data: {
          if (answerText != null) 'answer_text': answerText,
          if (isCorrect != null) 'is_correct': isCorrect,
          if (explanation != null) 'explanation': explanation,
          'updated_at': DateTime.now().toIso8601String(),
        },
        columnName: 'id',
        columnValue: answerId,
      );
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to update answer: ${e.toString()}';
      return false;
    }
  }

  // Delete Answer
  Future<bool> deleteAnswer(String answerId) async {
    try {
      await supabaseService.delete(
        table: AppConstants.answersTable,
        columnName: 'id',
        columnValue: answerId,
      );
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to delete answer: ${e.toString()}';
      return false;
    }
  }

  // Create Quiz with Questions and Answers (Complete)
  Future<String?> createCompleteQuiz({
    required String adminId,
    required String title,
    required String description,
    required String category,
    required List<Map<String, dynamic>> questions, // [{questionText, timeLimitSeconds, marks, answers: [{answerText, isCorrect}]}]
    int pointsCost = 0,
    double? price, // legacy
    int? difficulty,
    String? imageUrl,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Create quiz
      final totalMarks = questions.fold<int>(
        0,
        (sum, q) => sum + ((q['marks'] as int?) ?? 1),
      );
      final quizResult = await supabaseService.insert(
        table: AppConstants.quizzesTable,
        data: [
          {
            'admin_id': adminId,
            'title': title,
            'description': description,
            'category': category,
            'total_questions': questions.length,
            'duration_seconds': questions.fold<int>(0, (sum, q) => sum + (q['timeLimitSeconds'] as int? ?? 60)),
            'points_cost': pointsCost,
            'total_marks': totalMarks,
            // Legacy
            'price': price,
            'is_paid': false,
            'status': 'draft',
            'difficulty': difficulty,
            'thumbnail_url': imageUrl,
            'created_at': DateTime.now().toIso8601String(),
          }
        ],
      );

      if (quizResult.isEmpty) {
        throw Exception('Failed to create quiz');
      }

      final quizId = quizResult[0]['id'] as String;

      // Create questions with answers
      for (int i = 0; i < questions.length; i++) {
        final question = questions[i];
        await createQuestionWithAnswers(
          quizId: quizId,
          questionText: question['questionText'] as String,
          questionNumber: i + 1,
          timeLimitSeconds: question['timeLimitSeconds'] as int? ?? 60,
          marks: (question['marks'] as int?) ?? 1,
          answers: (question['answers'] as List).map((a) => a as Map<String, dynamic>).toList(),
        );
      }

      isLoading.value = false;
      return quizId;
    } catch (e) {
      errorMessage.value = 'Failed to create quiz: ${e.toString()}';
      isLoading.value = false;
      return null;
    }
  }
}
