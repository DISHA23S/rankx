import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/points_model.dart';
import 'supabase_service.dart';

class UserWithStats {
  final User user;
  final UserPoints? points;
  final int quizzesTaken;
  final int totalPayments;
  final double totalSpent;
  final bool hasActiveSubscription;
  final String? subscriptionPlan;
  final DateTime? subscriptionEndDate;
  final int rank; // Rank based on total points
  final int totalMarks; // Total marks from all quiz results
  final int pointsUsed; // Points used/spent on quizzes
  final int totalTimeSpent; // Total time spent in seconds on all quizzes

  UserWithStats({
    required this.user,
    this.points,
    required this.quizzesTaken,
    required this.totalPayments,
    required this.totalSpent,
    required this.hasActiveSubscription,
    this.subscriptionPlan,
    this.subscriptionEndDate,
    required this.rank,
    required this.totalMarks,
    required this.pointsUsed,
    required this.totalTimeSpent,
  });
}

class UserService extends GetxService {
  late final SupabaseService supabaseService;

  final RxList<UserWithStats> users = RxList<UserWithStats>();
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    supabaseService = Get.find<SupabaseService>();
  }

  // Get All Users with Stats
  Future<List<UserWithStats>> getAllUsersWithStats() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Get all users with role = 'user' (regular app users, not admins)
      final usersData = await supabaseService.query(
        table: AppConstants.usersTable,
        filters: {'role': AppConstants.userRole},
        orderBy: 'created_at',
        ascending: false,
      );

      final List<UserWithStats> usersWithStats = [];

      // First, get all quiz results to calculate total marks for ranking
      final allQuizResults = await supabaseService.query(
        table: 'quiz_results',
      );

      // Calculate total marks per user
      final Map<String, int> userTotalMarks = {};
      for (var result in allQuizResults) {
        final userId = result['user_id'] as String? ?? '';
        if (userId.isEmpty) continue;
        
        final marks = result['marks_obtained'];
        int marksValue = 0;
        if (marks is int) {
          marksValue = marks;
        } else if (marks is num) {
          marksValue = marks.toInt();
        } else if (marks is String) {
          marksValue = int.tryParse(marks) ?? 0;
        }
        
        userTotalMarks[userId] = (userTotalMarks[userId] ?? 0) + marksValue;
      }

      // Calculate total time per user for tiebreaker
      final Map<String, int> userTotalTime = {};
      for (var result in allQuizResults) {
        final userId = result['user_id'] as String? ?? '';
        if (userId.isEmpty) continue;
        
        final timeTaken = result['time_taken_seconds'];
        int timeValue = 0;
        if (timeTaken is int) {
          timeValue = timeTaken;
        } else if (timeTaken is num) {
          timeValue = timeTaken.toInt();
        } else if (timeTaken is String) {
          timeValue = int.tryParse(timeTaken) ?? 0;
        }
        
        userTotalTime[userId] = (userTotalTime[userId] ?? 0) + timeValue;
      }

      // Create a list of entries and sort by total marks (descending), then by time (ascending)
      final sortedUserMarks = userTotalMarks.entries.toList()
        ..sort((a, b) {
          // First compare marks (higher is better)
          final marksCompare = b.value.compareTo(a.value);
          if (marksCompare != 0) return marksCompare;
          
          // If marks are equal, compare time (lower is better)
          final aTime = userTotalTime[a.key] ?? 999999;
          final bTime = userTotalTime[b.key] ?? 999999;
          return aTime.compareTo(bTime);
        });

      // Create a map of userId -> rank
      // Users with same marks AND same time get same rank
      final Map<String, int> userRankMap = {};
      int currentRank = 1;
      int? lastMarks;
      int? lastTime;
      
      for (int i = 0; i < sortedUserMarks.length; i++) {
        final userId = sortedUserMarks[i].key;
        final marks = sortedUserMarks[i].value;
        final time = userTotalTime[userId] ?? 999999;
        
        // If marks OR time are different from previous, update rank
        if (lastMarks != null && (marks < lastMarks || (marks == lastMarks && time > lastTime!))) {
          currentRank = i + 1;
        }
        
        userRankMap[userId] = currentRank;
        lastMarks = marks;
        lastTime = time;
      }
      
      // Users without quiz results get rank = total users with results + 1
      final maxRankForNoResults = sortedUserMarks.length;

      // Also get user points for display purposes
      final allPoints = await supabaseService.query(
        table: AppConstants.userPointsTable,
      );

      // Process each user
      for (var userData in usersData) {
        final user = User.fromJson(userData);

        // Get user points
        UserPoints? userPoints;
        final pointsData = allPoints.firstWhere(
          (p) => p['user_id'] == user.id,
          orElse: () => {},
        );
        if (pointsData.isNotEmpty) {
          userPoints = UserPoints.fromJson(pointsData);
        }

        // Count unique quizzes taken from quiz_results (completed quizzes)
        int quizzesTaken = 0;
        try {
          final quizResultsData = await supabaseService.query(
            table: 'quiz_results',
            filters: {'user_id': user.id},
          );
          final uniqueQuizIds = <String>{};
          for (var result in quizResultsData) {
            final quizId = result['quiz_id'] as String? ?? '';
            if (quizId.isNotEmpty) {
              uniqueQuizIds.add(quizId);
            }
          }
          quizzesTaken = uniqueQuizIds.length;
        } catch (_) {
          quizzesTaken = 0;
        }

        // Get total marks and total time spent from quiz results
        int totalMarks = 0;
        int totalTimeSpent = 0;
        try {
          final quizResultsData = await supabaseService.query(
            table: 'quiz_results',
            filters: {'user_id': user.id},
          );
          totalMarks = quizResultsData.fold<int>(0, (sum, result) {
            final marks = result['marks_obtained'];
            if (marks is int) {
              return sum + marks;
            } else if (marks is num) {
              return sum + marks.toInt();
            } else if (marks is String) {
              return sum + (int.tryParse(marks) ?? 0);
            }
            return sum;
          });
          
          // Calculate total time spent
          totalTimeSpent = quizResultsData.fold<int>(0, (sum, result) {
            final timeTaken = result['time_taken_seconds'];
            if (timeTaken is int) {
              return sum + timeTaken;
            } else if (timeTaken is num) {
              return sum + timeTaken.toInt();
            } else if (timeTaken is String) {
              return sum + (int.tryParse(timeTaken) ?? 0);
            }
            return sum;
          });
        } catch (_) {
          totalMarks = 0;
          totalTimeSpent = 0;
        }

        // Calculate points used (from quiz costs or payments)
        // Points used = sum of quiz costs that user has taken
        int pointsUsed = 0;
        try {
          // Get all quiz results to find which quizzes were taken
          final quizResults = await supabaseService.query(
            table: 'quiz_results',
            filters: {'user_id': user.id},
          );
          final takenQuizIds = quizResults.map((r) => r['quiz_id'] as String? ?? '').toSet();
          
          // Get quiz costs for taken quizzes
          if (takenQuizIds.isNotEmpty) {
            final quizzesData = await supabaseService.query(
              table: 'quizzes',
            );
            for (var quiz in quizzesData) {
              final quizId = quiz['id'] as String? ?? '';
              if (takenQuizIds.contains(quizId)) {
                final pointsCost = quiz['points_cost'] as int? ?? 0;
                if (pointsCost > 0) {
                  pointsUsed += pointsCost;
                } else {
                  // If no points_cost, estimate based on difficulty
                  final difficulty = (quiz['difficulty'] as int? ?? 1).clamp(1, 5);
                  final totalQuestions = quiz['total_questions'] as int? ?? 0;
                  final estimatedCost = (difficulty * 2 * totalQuestions).clamp(5, 500);
                  pointsUsed += estimatedCost;
                }
              }
            }
          }
        } catch (_) {
          // Fallback: use quizzes taken as estimate
          pointsUsed = quizzesTaken * 10; // Rough estimate
        }

        // Get payments
        final paymentsData = await supabaseService.query(
          table: AppConstants.paymentsTable,
          filters: {'user_id': user.id},
        );
        final totalPayments = paymentsData.length;
        final totalSpent = paymentsData
            .where((p) => p['status'] == 'completed')
            .fold<double>(0.0, (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0.0));

        // Get active subscription
        final subscriptionsData = await supabaseService.query(
          table: AppConstants.subscriptionsTable,
          filters: {'user_id': user.id},
        );
        
        bool hasActiveSubscription = false;
        String? subscriptionPlan;
        DateTime? subscriptionEndDate;
        
        final activeSub = subscriptionsData.firstWhere(
          (s) => s['is_active'] == true,
          orElse: () => {},
        );
        if (activeSub.isNotEmpty) {
          hasActiveSubscription = true;
          subscriptionPlan = activeSub['plan'] as String?;
          final endDateStr = activeSub['end_date'] as String?;
          if (endDateStr != null) {
            subscriptionEndDate = DateTime.parse(endDateStr);
          }
        }

        // Get rank - if user has no quiz results, assign rank after all users with results
        final rank = userRankMap[user.id] ?? (maxRankForNoResults + 1);

        usersWithStats.add(UserWithStats(
          user: user,
          points: userPoints,
          quizzesTaken: quizzesTaken,
          totalPayments: totalPayments,
          totalSpent: totalSpent,
          hasActiveSubscription: hasActiveSubscription,
          subscriptionPlan: subscriptionPlan,
          subscriptionEndDate: subscriptionEndDate,
          rank: rank,
          totalMarks: totalMarks,
          pointsUsed: pointsUsed,
          totalTimeSpent: totalTimeSpent,
        ));
      }

      // Sort by rank (total marks) - highest marks first (rank 1 at top)
      usersWithStats.sort((a, b) => a.rank.compareTo(b.rank));

      users.value = usersWithStats;
      isLoading.value = false;
      return usersWithStats;
    } catch (e) {
      errorMessage.value = 'Failed to fetch users: ${e.toString()}';
      isLoading.value = false;
      return [];
    }
  }

  // Get User by ID with Stats
  Future<UserWithStats?> getUserWithStats(String userId) async {
    try {
      final userData = await supabaseService.querySingle(
        table: AppConstants.usersTable,
        filters: {'id': userId},
      );
      final user = User.fromJson(userData);

      // Get user points
      UserPoints? userPoints;
      try {
        final pointsData = await supabaseService.querySingle(
          table: AppConstants.userPointsTable,
          filters: {'user_id': userId},
        );
        userPoints = UserPoints.fromJson(pointsData);
      } catch (_) {
        // No points record
      }

      // Count quizzes taken from quiz_results
      int quizzesTaken = 0;
      try {
        final quizResultsData = await supabaseService.query(
          table: 'quiz_results',
          filters: {'user_id': userId},
        );
        final uniqueQuizIds = <String>{};
        for (var result in quizResultsData) {
          final quizId = result['quiz_id'] as String? ?? '';
          if (quizId.isNotEmpty) {
            uniqueQuizIds.add(quizId);
          }
        }
        quizzesTaken = uniqueQuizIds.length;
      } catch (_) {
        quizzesTaken = 0;
      }

      // Get payments
      final paymentsData = await supabaseService.query(
        table: AppConstants.paymentsTable,
        filters: {'user_id': userId},
      );
      final totalPayments = paymentsData.length;
      final totalSpent = paymentsData
          .where((p) => p['status'] == 'completed')
          .fold<double>(0.0, (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0.0));

      // Get active subscription
      final subscriptionsData = await supabaseService.query(
        table: AppConstants.subscriptionsTable,
        filters: {'user_id': userId},
      );
      
      bool hasActiveSubscription = false;
      String? subscriptionPlan;
      DateTime? subscriptionEndDate;
      
      final activeSub = subscriptionsData.firstWhere(
        (s) => s['is_active'] == true,
        orElse: () => {},
      );
      if (activeSub.isNotEmpty) {
        hasActiveSubscription = true;
        subscriptionPlan = activeSub['plan'] as String?;
        final endDateStr = activeSub['end_date'] as String?;
        if (endDateStr != null) {
          subscriptionEndDate = DateTime.parse(endDateStr);
        }
      }

      // Get rank (simplified - would need all users for accurate rank)
      final rank = 0; // Will be calculated when fetching all users

      // Get total marks and total time spent for single user
      int totalMarks = 0;
      int totalTimeSpent = 0;
      try {
        final quizResultsData = await supabaseService.query(
          table: 'quiz_results',
          filters: {'user_id': userId},
        );
        totalMarks = quizResultsData.fold<int>(0, (sum, result) {
          final marks = result['marks_obtained'];
          if (marks is int) {
            return sum + marks;
          } else if (marks is num) {
            return sum + marks.toInt();
          }
          return sum;
        });
        
        // Calculate total time spent
        totalTimeSpent = quizResultsData.fold<int>(0, (sum, result) {
          final timeTaken = result['time_taken_seconds'];
          if (timeTaken is int) {
            return sum + timeTaken;
          } else if (timeTaken is num) {
            return sum + timeTaken.toInt();
          } else if (timeTaken is String) {
            return sum + (int.tryParse(timeTaken) ?? 0);
          }
          return sum;
        });
      } catch (_) {
        totalMarks = 0;
        totalTimeSpent = 0;
      }

      // Calculate points used
      int pointsUsed = quizzesTaken * 10; // Rough estimate for single user

      return UserWithStats(
        user: user,
        points: userPoints,
        quizzesTaken: quizzesTaken,
        totalPayments: totalPayments,
        totalSpent: totalSpent,
        hasActiveSubscription: hasActiveSubscription,
        subscriptionPlan: subscriptionPlan,
        subscriptionEndDate: subscriptionEndDate,
        rank: rank,
        totalMarks: totalMarks,
        pointsUsed: pointsUsed,
        totalTimeSpent: totalTimeSpent,
      );
    } catch (e) {
      errorMessage.value = 'Failed to fetch user: ${e.toString()}';
      return null;
    }
  }

  // Admin: Assign Points to User
  Future<bool> adminAssignPoints({
    required String userId,
    required int points,
  }) async {
    try {
      // Check if user_points record exists
      UserPoints? userPoints;
      try {
        final pointsData = await supabaseService.querySingle(
          table: AppConstants.userPointsTable,
          filters: {'user_id': userId},
        );
        userPoints = UserPoints.fromJson(pointsData);
      } catch (_) {
        // Create new user_points record if doesn't exist
        await supabaseService.insert(
          table: AppConstants.userPointsTable,
          data: [
            {
              'user_id': userId,
              'daily_points': 0,
              'weekly_points': 0,
              'total_points': points,
              'last_updated': DateTime.now().toIso8601String(),
            }
          ],
        );
        return true;
      }

      // Update existing points
      final now = DateTime.now();
      final lastUpdated = userPoints.lastUpdated;
      
      int newDailyPoints = userPoints.dailyPoints;
      int newWeeklyPoints = userPoints.weeklyPoints;

      // Reset daily points if different day
      if (now.day != lastUpdated.day ||
          now.month != lastUpdated.month ||
          now.year != lastUpdated.year) {
        newDailyPoints = points;
      } else {
        newDailyPoints += points;
      }

      // Reset weekly points if different week
      if (now.difference(lastUpdated).inDays >= 7) {
        newWeeklyPoints = points;
      } else {
        newWeeklyPoints += points;
      }

      final newTotalPoints = userPoints.totalPoints + points;

      await supabaseService.update(
        table: AppConstants.userPointsTable,
        data: {
          'daily_points': newDailyPoints,
          'weekly_points': newWeeklyPoints,
          'total_points': newTotalPoints,
          'last_updated': DateTime.now().toIso8601String(),
        },
        columnName: 'user_id',
        columnValue: userId,
      );

      return true;
    } catch (e) {
      errorMessage.value = 'Failed to assign points: ${e.toString()}';
      return false;
    }
  }

  // Admin: Assign Subscription to User
  Future<bool> adminAssignSubscription({
    required String userId,
    required String plan, // 'daily', 'weekly', 'monthly'
    double? amount,
  }) async {
    try {
      // Deactivate existing subscriptions
      await supabaseService.client
          .from(AppConstants.subscriptionsTable)
          .update({'is_active': false})
          .eq('user_id', userId)
          .eq('is_active', true);

      // Defaults (fallback) if no subscription_plans row exists
      double subscriptionAmount = amount ?? 0.0;
      int durationDays = 1;
      int rewardPoints = 0;

      // Try to load plan configuration from subscription_plans so admins can manage
      // price/duration/points and users will see the same plans.
      try {
        final planRow = await supabaseService.client
            .from(AppConstants.subscriptionPlansTable)
            .select('price, duration_days, points')
            .eq('code', plan)
            .maybeSingle();

        if (planRow != null) {
          final dbPrice = (planRow['price'] as num?)?.toDouble();
          final dbDuration = (planRow['duration_days'] as num?)?.toInt();
          final dbPoints = (planRow['points'] as num?)?.toInt();

          if (amount == null && dbPrice != null) {
            subscriptionAmount = dbPrice;
          }
          if (dbDuration != null && dbDuration > 0) {
            durationDays = dbDuration;
          }
          if (dbPoints != null && dbPoints > 0) {
            rewardPoints = dbPoints;
          }
        }
      } catch (_) {
        // Ignore and fall back to hardcoded defaults
      }

      // If plan wasn't found in DB and amount wasn't provided, fall back to previous constants
      if (amount == null && subscriptionAmount == 0.0) {
        switch (plan) {
          case AppConstants.planDaily:
            subscriptionAmount = 9.99;
            durationDays = 1;
            rewardPoints = AppConstants.planDailyPoints;
            break;
          case AppConstants.planWeekly:
            subscriptionAmount = 49.99;
            durationDays = 7;
            rewardPoints = AppConstants.planWeeklyPoints;
            break;
          case AppConstants.planMonthly:
            subscriptionAmount = 149.99;
            durationDays = 30;
            rewardPoints = AppConstants.planMonthlyPoints;
            break;
          case AppConstants.planYearly:
            subscriptionAmount = 999.99;
            durationDays = 365;
            rewardPoints = AppConstants.planYearlyPoints;
            break;
          default:
            subscriptionAmount = 9.99;
            durationDays = 1;
            rewardPoints = AppConstants.planDailyPoints;
        }
      }

      final now = DateTime.now();
      final endDate = now.add(Duration(days: durationDays));

      await supabaseService.insert(
        table: AppConstants.subscriptionsTable,
        data: [
          {
            'user_id': userId,
            'plan': plan,
            'amount': subscriptionAmount,
            'start_date': now.toIso8601String().split('T')[0],
            'end_date': endDate.toIso8601String().split('T')[0],
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
          }
        ],
      );

      if (rewardPoints > 0) {
        await adminAssignPoints(userId: userId, points: rewardPoints);
      }

      return true;
    } catch (e) {
      errorMessage.value = 'Failed to assign subscription: ${e.toString()}';
      return false;
    }
  }

  // Get Points Used for Quizzes (count unique quizzes taken)
  Future<int> getPointsUsedForQuizzes(String userId) async {
    try {
      final userAnswersData = await supabaseService.client
          .from(AppConstants.userAnswersTable)
          .select('quiz_id')
          .eq('user_id', userId);
      
      final uniqueQuizIds = <String>{};
      if (userAnswersData.isNotEmpty) {
        for (var answer in userAnswersData) {
          uniqueQuizIds.add(answer['quiz_id'] as String);
        }
      }
      // Assuming each quiz costs 1 point (can be adjusted)
      return uniqueQuizIds.length;
    } catch (e) {
      return 0;
    }
  }
}
