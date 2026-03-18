import 'package:get/get.dart';

import '../constants/app_constants.dart';
import '../models/subscription_plan_model.dart';
import 'supabase_service.dart';

class SubscriptionPlanService extends GetxService {
  final SupabaseService supabaseService = SupabaseService();

  final RxList<SubscriptionPlan> plans = <SubscriptionPlan>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  Future<List<SubscriptionPlan>> fetchPlans() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final data = await supabaseService.query(
        table: AppConstants.subscriptionPlansTable,
        orderBy: 'created_at',
        ascending: false,
      );
      final list = data.map((e) => SubscriptionPlan.fromJson(e)).toList();
      plans.assignAll(list);
      return list;
    } catch (e) {
      errorMessage.value = 'Failed to load subscription plans: ${e.toString()}';
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createOrUpdatePlan({
    String? id,
    required String name,
    required String code,
    String? description,
    required int durationDays,
    required double price,
    required int points,
    bool isActive = true,
  }) async {
    try {
      if (id == null) {
        await supabaseService.insert(
          table: AppConstants.subscriptionPlansTable,
          data: [
            {
              'name': name,
              'code': code,
              'description': description,
              'duration_days': durationDays,
              'price': price,
              'points': points,
              'is_active': isActive,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            }
          ],
        );
      } else {
        await supabaseService.update(
          table: AppConstants.subscriptionPlansTable,
          data: {
            'name': name,
            'code': code,
            'description': description,
            'duration_days': durationDays,
            'price': price,
            'points': points,
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          },
          columnName: 'id',
          columnValue: id,
        );
      }
      await fetchPlans();
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to save plan: ${e.toString()}';
      return false;
    }
  }

  Future<bool> deletePlan(String id) async {
    try {
      await supabaseService.delete(
        table: AppConstants.subscriptionPlansTable,
        columnName: 'id',
        columnValue: id,
      );
      plans.removeWhere((p) => p.id == id);
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to delete plan: ${e.toString()}';
      return false;
    }
  }
}


