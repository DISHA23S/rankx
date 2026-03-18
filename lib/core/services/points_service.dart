import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../models/points_model.dart';
import 'supabase_service.dart';

class PointsService extends GetxService {
  late final SupabaseService supabaseService;
  
  @override
  void onInit() {
    super.onInit();
    // Use the shared SupabaseService singleton registered in main().
    supabaseService = Get.find<SupabaseService>();
  }
  
  final Rx<UserPoints?> userPoints = Rx<UserPoints?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Get User Points
  Future<UserPoints?> getUserPoints(String userId) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final data = await supabaseService.querySingle(
        table: AppConstants.userPointsTable,
        filters: {'user_id': userId},
      );
      userPoints.value = UserPoints.fromJson(data);
      isLoading.value = false;
      return userPoints.value;
    } catch (e) {
      errorMessage.value = 'Failed to fetch points: ${e.toString()}';
      isLoading.value = false;
      return null;
    }
  }

  // Add Points
  Future<bool> addPoints({
    required String userId,
    required int points,
  }) async {
    try {
      final currentPoints = await getUserPoints(userId);
      if (currentPoints == null) {
        return false;
      }

      final now = DateTime.now();
      final lastUpdated = currentPoints.lastUpdated;
      
      int newDailyPoints = currentPoints.dailyPoints;
      int newWeeklyPoints = currentPoints.weeklyPoints;

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

      final newTotalPoints = currentPoints.totalPoints + points;

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

      // Refresh local points
      await getUserPoints(userId);
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to add points: ${e.toString()}';
      return false;
    }
  }

  // Reset Daily Points
  Future<bool> resetDailyPoints(String userId) async {
    try {
      await supabaseService.update(
        table: AppConstants.userPointsTable,
        data: {
          'daily_points': 0,
          'last_updated': DateTime.now().toIso8601String(),
        },
        columnName: 'user_id',
        columnValue: userId,
      );
      await getUserPoints(userId);
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to reset daily points: ${e.toString()}';
      return false;
    }
  }

  // Deduct Points (used to unlock quizzes)
  Future<bool> deductPoints({
    required String userId,
    required int points,
  }) async {
    if (points <= 0) return true;
    try {
      final current = await getUserPoints(userId);
      if (current == null) return false;

      if (current.totalPoints < points) {
        errorMessage.value = 'Not enough points.';
        return false;
      }

      final newTotal =
          (current.totalPoints - points).clamp(0, 1 << 31).toInt();
      final newDaily =
          (current.dailyPoints - points).clamp(0, 1 << 31).toInt();
      final newWeekly =
          (current.weeklyPoints - points).clamp(0, 1 << 31).toInt();

      await supabaseService.update(
        table: AppConstants.userPointsTable,
        data: {
          'daily_points': newDaily,
          'weekly_points': newWeekly,
          'total_points': newTotal,
          'last_updated': DateTime.now().toIso8601String(),
        },
        columnName: 'user_id',
        columnValue: userId,
      );

      await getUserPoints(userId);
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to deduct points: ${e.toString()}';
      return false;
    }
  }
}
