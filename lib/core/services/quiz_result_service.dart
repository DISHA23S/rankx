import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../models/quiz_result_model.dart';
import 'supabase_service.dart';

// Leaderboard Entry Model
class LeaderboardEntry {
  final String userId;
  final String userName;
  final int totalMarks;
  final int totalQuizzes;
  final int rank;
  final int totalTimeSeconds; // Total time taken across all quizzes

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    required this.totalMarks,
    required this.totalQuizzes,
    required this.rank,
    this.totalTimeSeconds = 0,
  });
}

class QuizResultService extends GetxService {
  late final SupabaseService supabaseService;
  
  @override
  void onInit() {
    super.onInit();
    supabaseService = Get.find<SupabaseService>();
  }

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Save Quiz Result
  Future<bool> saveQuizResult({
    required String userId,
    required String quizId,
    required int totalQuestions,
    required int correctAnswers,
    required int marksObtained,
    required int totalMarks,
    required int timeTakenSeconds,
    required int maxTimeSeconds,
    required List<Map<String, dynamic>> questionResults,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final accuracy = totalQuestions > 0
          ? double.parse((correctAnswers / totalQuestions * 100).toStringAsFixed(2))
          : 0.0;

      final result = await supabaseService.insert(
        table: 'quiz_results',
        data: [
          {
            'user_id': userId,
            'quiz_id': quizId,
            'total_questions': totalQuestions,
            'correct_answers': correctAnswers,
            'marks_obtained': marksObtained,
            'total_marks': totalMarks,
            'time_taken_seconds': timeTakenSeconds,
            'max_time_seconds': maxTimeSeconds,
            'accuracy': accuracy,
            'question_results': questionResults,
          }
        ],
      );

      isLoading.value = false;
      return result.isNotEmpty;
    } catch (e) {
      errorMessage.value = 'Failed to save quiz result: ${e.toString()}';
      isLoading.value = false;
      return false;
    }
  }

  // Get Quiz Result by ID
  Future<QuizResult?> getQuizResultById(String resultId) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final data = await supabaseService.querySingle(
        table: 'quiz_results',
        filters: {'id': resultId},
      );

      isLoading.value = false;
      return QuizResult.fromJson(data);
    } catch (e) {
      errorMessage.value = 'Failed to fetch quiz result: ${e.toString()}';
      isLoading.value = false;
      return null;
    }
  }

  // Get User's Quiz Results
  Future<List<QuizResult>> getUserQuizResults(String userId) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final data = await supabaseService.query(
        table: 'quiz_results',
        filters: {'user_id': userId},
        orderBy: 'attempted_at',
        ascending: false,
      );

      isLoading.value = false;
      return data.map((e) => QuizResult.fromJson(e)).toList();
    } catch (e) {
      errorMessage.value = 'Failed to fetch user results: ${e.toString()}';
      isLoading.value = false;
      return [];
    }
  }

  // Get User's Results for Specific Quiz
  Future<List<QuizResult>> getUserQuizAttempts(String userId, String quizId) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final data = await supabaseService.query(
        table: 'quiz_results',
        filters: {
          'user_id': userId,
          'quiz_id': quizId,
        },
        orderBy: 'attempted_at',
        ascending: false,
      );

      isLoading.value = false;
      return data.map((e) => QuizResult.fromJson(e)).toList();
    } catch (e) {
      errorMessage.value = 'Failed to fetch quiz attempts: ${e.toString()}';
      isLoading.value = false;
      return [];
    }
  }

  // Get Best Result for a Quiz
  Future<QuizResult?> getBestQuizResult(String userId, String quizId) async {
    try {
      final attempts = await getUserQuizAttempts(userId, quizId);
      if (attempts.isEmpty) return null;

      // Sort by marks obtained (descending)
      attempts.sort((a, b) => b.marksObtained.compareTo(a.marksObtained));
      return attempts.first;
    } catch (e) {
      errorMessage.value = 'Failed to get best result: ${e.toString()}';
      return null;
    }
  }

  // Get Average Score for User
  Future<double> getUserAverageScore(String userId) async {
    try {
      final results = await getUserQuizResults(userId);
      if (results.isEmpty) return 0;

      final totalMarks = results.fold<int>(0, (sum, r) => sum + r.marksObtained);
      final maxMarks = results.fold<int>(0, (sum, r) => sum + r.totalMarks);

      return maxMarks > 0 ? (totalMarks / maxMarks) * 100 : 0;
    } catch (e) {
      errorMessage.value = 'Failed to calculate average: ${e.toString()}';
      return 0;
    }
  }

  // Get User Statistics
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final results = await getUserQuizResults(userId);
      if (results.isEmpty) {
        return {
          'total_attempts': 0,
          'total_quizzes': 0,
          'average_accuracy': 0.0,
          'total_marks': 0,
          'total_time': 0,
        };
      }

      final totalMarks = results.fold<int>(0, (sum, r) => sum + r.marksObtained);
      final totalPossible = results.fold<int>(0, (sum, r) => sum + r.totalMarks);
      final totalAccuracy = results.fold<double>(0.0, (sum, r) => sum + r.accuracy);
      final totalTime = results.fold<int>(0, (sum, r) => sum + r.timeTakenSeconds);
      final uniqueQuizzes = results.map((r) => r.quizId).toSet().length;

      return {
        'total_attempts': results.length,
        'total_quizzes': uniqueQuizzes,
        'average_accuracy': totalAccuracy / results.length,
        'total_marks': totalMarks,
        'total_time': totalTime,
        'average_marks_per_quiz': totalMarks / uniqueQuizzes,
      };
    } catch (e) {
      errorMessage.value = 'Failed to calculate stats: ${e.toString()}';
      return {};
    }
  }


  // Get Leaderboard by Total Marks
  Future<List<LeaderboardEntry>> getLeaderboardByMarks({int limit = 50}) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Get all quiz results first (to ensure we capture all users with results)
      // Don't use select parameter - get all fields to ensure marks_obtained is included
      final allResults = await supabaseService.query(
        table: 'quiz_results',
        // No filters - get ALL quiz results from all users
      );

      // Get all users to get user names
      final allUsers = await supabaseService.query(
        table: AppConstants.usersTable,
        filters: {'role': AppConstants.userRole},
      );

      // Create a map of user IDs to user data for quick lookup
      // Normalize user IDs to strings and trim whitespace for consistent matching
      final Map<String, Map<String, dynamic>> usersMap = {};
      for (var user in allUsers) {
        final userIdRaw = user['id'];
        if (userIdRaw == null) continue;
        final userId = userIdRaw.toString().trim();
        usersMap[userId] = user;
      }

      // Aggregate marks by user from quiz results
      // Key: user_id (normalized string), Value: {total_marks: int, total_time: int, quiz_ids: Set<String>}
      final Map<String, Map<String, dynamic>> userMarksMap = {};
      
      // STEP 1: Process ALL quiz results and SUM marks_obtained and time_taken for each user_id
      // Each row in quiz_results = one quiz attempt with marks_obtained and time_taken_seconds
      // We need to SUM all marks_obtained and time_taken_seconds for the same user_id
      for (var result in allResults) {
        try {
          // Get and normalize user_id
          final userIdRaw = result['user_id'];
          if (userIdRaw == null) continue;
          final userId = userIdRaw.toString().trim();
          if (userId.isEmpty) continue;
          
          // Read marks_obtained - this is what we need to SUM
          int marks = 0;
          final marksValue = result['marks_obtained'];
          
          if (marksValue != null) {
            if (marksValue is int) {
              marks = marksValue;
            } else if (marksValue is double) {
              marks = marksValue.toInt();
            } else if (marksValue is num) {
              marks = marksValue.toInt();
            } else if (marksValue is String) {
              marks = int.tryParse(marksValue) ?? 0;
            } else {
              try {
                marks = int.parse(marksValue.toString());
              } catch (_) {
                marks = 0;
              }
            }
          }
          
          // Read time_taken_seconds - this is what we need to SUM for tiebreaker
          int timeTaken = 0;
          final timeValue = result['time_taken_seconds'];
          
          if (timeValue != null) {
            if (timeValue is int) {
              timeTaken = timeValue;
            } else if (timeValue is double) {
              timeTaken = timeValue.toInt();
            } else if (timeValue is num) {
              timeTaken = timeValue.toInt();
            } else if (timeValue is String) {
              timeTaken = int.tryParse(timeValue) ?? 0;
            } else {
              try {
                timeTaken = int.parse(timeValue.toString());
              } catch (_) {
                timeTaken = 0;
              }
            }
          }
          
          // Get quiz_id to track unique quizzes
          final quizIdRaw = result['quiz_id'];
          final quizId = quizIdRaw?.toString().trim();
          
          // Initialize user entry if this is the first quiz result for this user
          if (!userMarksMap.containsKey(userId)) {
            userMarksMap[userId] = {
              'total_marks': 0,
              'total_time': 0,
              'quiz_ids': <String>{},
            };
          }
          
          // SUM: Add marks_obtained to this user's total_marks
          // This accumulates marks across ALL quiz attempts for this user
          final currentTotal = userMarksMap[userId]!['total_marks'] as int;
          userMarksMap[userId]!['total_marks'] = currentTotal + marks;
          
          // SUM: Add time_taken_seconds to this user's total_time
          final currentTime = userMarksMap[userId]!['total_time'] as int;
          userMarksMap[userId]!['total_time'] = currentTime + timeTaken;
          
          // Track unique quiz IDs (for total quizzes count)
          if (quizId != null && quizId.isNotEmpty) {
            (userMarksMap[userId]!['quiz_ids'] as Set<String>).add(quizId);
          }
        } catch (e) {
          // Skip invalid entries but continue processing
          continue;
        }
      }

      // STEP 2: Initialize users who don't have any quiz results (with 0 marks and 0 time)
      // This ensures all users appear in leaderboard, even with 0 marks
      for (var user in allUsers) {
        final userIdRaw = user['id'];
        if (userIdRaw == null) continue;
        final userId = userIdRaw.toString().trim();
        
        if (!userMarksMap.containsKey(userId)) {
          userMarksMap[userId] = {
            'total_marks': 0,
            'total_time': 0,
            'quiz_ids': <String>{},
          };
        }
      }

      // STEP 3: Build leaderboard with all users and their aggregated marks
      final List<LeaderboardEntry> leaderboard = [];
      final Set<String> addedUserIds = <String>{};
      
      // First, add users who have quiz results (with their SUM of marks and time)
      for (var entry in userMarksMap.entries) {
        final userId = entry.key; // This is already normalized
        final totalMarks = entry.value['total_marks'] as int; // SUM of all marks_obtained
        final totalTime = entry.value['total_time'] as int; // SUM of all time_taken_seconds
        final quizIds = entry.value['quiz_ids'] as Set<String>; // Unique quiz IDs
        
        // Get user name from users map (normalize user ID for lookup)
        String userName = 'User';
        if (usersMap.containsKey(userId)) {
          final userData = usersMap[userId]!;
          userName = userData['name'] as String? ?? userData['email'] as String? ?? 'User';
        } else {
          // User has quiz results but not in users table - use fallback name
          userName = 'User $userId';
        }
        
        leaderboard.add(LeaderboardEntry(
          userId: userId,
          userName: userName,
          totalMarks: totalMarks, // This is the SUM of all marks_obtained for this user
          totalQuizzes: quizIds.length, // Count of unique quizzes
          totalTimeSeconds: totalTime, // This is the SUM of all time_taken_seconds
          rank: 0, // Will be set after sorting
        ));
        
        addedUserIds.add(userId);
      }
      
      // Then, add users who don't have quiz results yet (with 0 marks and 0 time)
      for (var user in allUsers) {
        final userIdRaw = user['id'];
        if (userIdRaw == null) continue;
        final userId = userIdRaw.toString().trim();
        
        if (!addedUserIds.contains(userId)) {
          final userName = user['name'] as String? ?? user['email'] as String? ?? 'User';
          
          leaderboard.add(LeaderboardEntry(
            userId: userId,
            userName: userName,
            totalMarks: 0,
            totalQuizzes: 0,
            totalTimeSeconds: 0,
            rank: 0, // Will be set after sorting
          ));
        }
      }

      // STEP 4: Sort by total marks (descending), then by time (ascending - less time is better)
      // This ensures users with higher total marks appear first
      // If marks are equal, users who completed faster (less time) rank higher
      leaderboard.sort((a, b) {
        // Primary sort: by total marks (descending - highest first)
        final marksCompare = b.totalMarks.compareTo(a.totalMarks);
        if (marksCompare != 0) return marksCompare;
        
        // Secondary sort: by total time (ascending - less time is better)
        // If both have same marks, the one with less time ranks higher
        final timeCompare = a.totalTimeSeconds.compareTo(b.totalTimeSeconds);
        if (timeCompare != 0) return timeCompare;
        
        // Tertiary sort: by user name (ascending) for complete ties
        return a.userName.compareTo(b.userName);
      });

      // STEP 5: Assign ranks based on sorted total marks and time
      // Same total marks AND same time = same rank
      // Different marks OR different time = different rank
      final List<LeaderboardEntry> rankedLeaderboard = [];
      
      if (leaderboard.isEmpty) {
        isLoading.value = false;
        return [];
      }
      
      // Assign ranks: rank 1 for highest marks/fastest time, increment when marks or time differ
      int currentRank = 1;
      
      for (int i = 0; i < leaderboard.length; i++) {
        // If this is not the first entry, check if marks OR time changed from previous
        if (i > 0) {
          final prevEntry = leaderboard[i - 1];
          final currEntry = leaderboard[i];
          
          // Update rank if marks decreased OR (marks same but time increased)
          if (currEntry.totalMarks < prevEntry.totalMarks ||
              (currEntry.totalMarks == prevEntry.totalMarks && 
               currEntry.totalTimeSeconds > prevEntry.totalTimeSeconds)) {
            // Rank is based on position (1-indexed)
            currentRank = i + 1;
          }
        }
        
        // Create ranked entry with the calculated rank
        rankedLeaderboard.add(LeaderboardEntry(
          userId: leaderboard[i].userId,
          userName: leaderboard[i].userName,
          totalMarks: leaderboard[i].totalMarks, // This is the SUM of all marks_obtained
          totalQuizzes: leaderboard[i].totalQuizzes, // Count of unique quizzes
          totalTimeSeconds: leaderboard[i].totalTimeSeconds, // This is the SUM of all time_taken_seconds
          rank: currentRank,
        ));
      }

      isLoading.value = false;
      return rankedLeaderboard.take(limit).toList();
    } catch (e) {
      errorMessage.value = 'Failed to fetch leaderboard: ${e.toString()}';
      isLoading.value = false;
      return [];
    }
  }

  // Get User's Rank by Total Marks
  Future<int> getUserRankByMarks(String userId) async {
    try {
      final leaderboard = await getLeaderboardByMarks(limit: 1000);
      final userEntry = leaderboard.firstWhere(
        (entry) => entry.userId == userId,
        orElse: () => LeaderboardEntry(
          userId: userId,
          userName: 'User',
          totalMarks: 0,
          totalQuizzes: 0,
          rank: leaderboard.length + 1,
        ),
      );
      return userEntry.rank;
    } catch (e) {
      errorMessage.value = 'Failed to get user rank: ${e.toString()}';
      return 0;
    }
  }

  // Get User's Total Marks
  Future<int> getUserTotalMarks(String userId) async {
    try {
      final results = await getUserQuizResults(userId);
      return results.fold<int>(0, (sum, r) => sum + r.marksObtained);
    } catch (e) {
      return 0;
    }
  }
}
