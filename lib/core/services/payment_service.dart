import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../models/payment_model.dart';
import 'supabase_service.dart';

class PaymentService extends GetxService {
  final supabaseService = SupabaseService();
  
  final RxList<Payment> payments = RxList<Payment>();
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Create Payment
  Future<Payment?> createPayment({
    required String userId,
    required String quizId,
    required double amount,
    required String paymentMethod,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final result = await supabaseService.insert(
        table: AppConstants.paymentsTable,
        data: [
          {
            'user_id': userId,
            'quiz_id': quizId,
            'amount': amount,
            'payment_method': paymentMethod,
            'status': AppConstants.paymentPending,
            'created_at': DateTime.now().toIso8601String(),
          }
        ],
      );

      isLoading.value = false;
      if (result.isNotEmpty) {
        return Payment.fromJson(result[0]);
      }
      return null;
    } catch (e) {
      errorMessage.value = 'Failed to create payment: ${e.toString()}';
      isLoading.value = false;
      return null;
    }
  }

  // Update Payment Status
  Future<bool> updatePaymentStatus({
    required String paymentId,
    required String status,
    String? transactionId,
  }) async {
    try {
      await supabaseService.update(
        table: AppConstants.paymentsTable,
        data: {
          'status': status,
          if (transactionId != null) 'transaction_id': transactionId,
          if (status == AppConstants.paymentCompleted)
            'completed_at': DateTime.now().toIso8601String(),
        },
        columnName: 'id',
        columnValue: paymentId,
      );
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to update payment: ${e.toString()}';
      return false;
    }
  }

  // Get User Payments
  Future<List<Payment>> getUserPayments(String userId) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final data = await supabaseService.query(
        table: AppConstants.paymentsTable,
        filters: {'user_id': userId},
        orderBy: 'created_at',
        ascending: false,
      );

      final paymentsList = data.map((e) => Payment.fromJson(e)).toList();
      payments.value = paymentsList;
      isLoading.value = false;
      return paymentsList;
    } catch (e) {
      errorMessage.value = 'Failed to fetch payments: ${e.toString()}';
      isLoading.value = false;
      return [];
    }
  }

  // Create Subscription
  Future<bool> createSubscription({
    required String userId,
    required String plan,
    required double amount,
    String? paymentId,
  }) async {
    try {
      final now = DateTime.now();
      DateTime endDate;

      switch (plan) {
        case AppConstants.planDaily:
          endDate = now.add(const Duration(days: 1));
          break;
        case AppConstants.planWeekly:
          endDate = now.add(const Duration(days: 7));
          break;
        case AppConstants.planMonthly:
          endDate = now.add(const Duration(days: 30));
          break;
        case AppConstants.planYearly:
          endDate = now.add(const Duration(days: 365));
          break;
        default:
          endDate = now.add(const Duration(days: 1));
      }

      await supabaseService.insert(
        table: AppConstants.subscriptionsTable,
        data: [
          {
            'user_id': userId,
            'plan': plan,
            'amount': amount,
            'start_date': now.toIso8601String().split('T')[0],
            'end_date': endDate.toIso8601String().split('T')[0],
            'is_active': true,
            'payment_id': paymentId,
          }
        ],
      );
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to create subscription: ${e.toString()}';
      return false;
    }
  }

  // Get Active Subscription
  Future<Subscription?> getActiveSubscription(String userId) async {
    try {
      final data = await supabaseService.client
          .from(AppConstants.subscriptionsTable)
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('end_date', ascending: false)
          .limit(1)
          .single();
      
      return Subscription.fromJson(data);
    } catch (e) {
      return null;
    }
  }
}
