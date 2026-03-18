import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/models/quiz_model.dart';
import '../../../core/models/subscription_plan_model.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/points_service.dart';
import '../../../core/services/quiz_service.dart';
import '../../../core/services/subscription_plan_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/widgets/app_widgets.dart';

class PaymentScreen extends StatefulWidget {
  final String quizId;

  const PaymentScreen({super.key, required this.quizId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPaymentMethod = 'card';
  String? _selectedPlanCode;

  final supabaseService = Get.find<SupabaseService>();
  final userService = Get.find<UserService>();
  final SubscriptionPlanService planService = Get.find<SubscriptionPlanService>();
  final QuizService quizService = Get.find<QuizService>();
  final PointsService pointsService = Get.find<PointsService>();

  Quiz? _quiz;
  bool _quizLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
    _loadQuiz();
  }

  Future<void> _loadPlans() async {
    final plans = await planService.fetchPlans();
    if (!mounted) return;

    final active = plans.where((p) => p.isActive).toList();
    if (active.isEmpty) return;

    // Default selection: keep current selection if still valid, otherwise first active plan.
    if (_selectedPlanCode == null ||
        !active.any((p) => p.code == _selectedPlanCode)) {
      setState(() {
        _selectedPlanCode = active.first.code;
      });
    }
  }

  Future<void> _loadQuiz() async {
    setState(() => _quizLoading = true);
    try {
      final q = await quizService.getQuizById(widget.quizId);
      if (!mounted) return;
      setState(() {
        _quiz = q;
        _quizLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _quiz = null;
        _quizLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final activePlans =
          planService.plans.where((p) => p.isActive).toList(growable: false);
      final selectedPlan = _getSelectedPlan(activePlans);
      final selectedPrice = selectedPlan?.price ?? 0.0;
      final quizTitle = _quiz?.title ?? 'Quiz';
      final quizCostPoints = _quiz == null ? 0 : _requiredPoints(_quiz!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quiz Info Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quiz: $quizTitle',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Price: ₹${selectedPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_quizLoading)
                    const Text('Loading quiz details...')
                  else
                    Text(
                      'Unlock cost: 🪙 $quizCostPoints points',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Subscription Plans
            Text(
              'Select Plan',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            if (planService.isLoading.value)
              const Center(child: CircularProgressIndicator())
            else if (activePlans.isEmpty)
              AppCard(
                backgroundColor: AppColors.bgSecondary,
                child: const Text('No subscription plans available right now.'),
              )
            else
              ...activePlans.map((plan) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _buildPlanCard(
                      title: plan.name,
                      subtitle:
                          '${plan.durationDays} days • ${plan.points} points',
                      price: '₹${plan.price.toStringAsFixed(2)}',
                      planCode: plan.code,
                      isSelected: _selectedPlanCode == plan.code,
                    ),
                  )),
            const SizedBox(height: AppSpacing.lg),
            // Payment Methods
            Text(
              'Payment Method',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            ...[
              {'id': 'card', 'title': 'Credit/Debit Card', 'icon': Icons.credit_card},
              {'id': 'upi', 'title': 'UPI', 'icon': Icons.mobile_friendly},
              {'id': 'wallet', 'title': 'Wallet', 'icon': Icons.account_balance_wallet},
              {'id': 'net_banking', 'title': 'Net Banking', 'icon': Icons.account_balance},
            ].map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _buildPaymentMethodCard(
                    title: e['title']! as String,
                    icon: e['icon'] as IconData,
                    methodId: e['id']! as String,
                    isSelected: _selectedPaymentMethod == (e['id'] as String),
                  ),
                )),
            const SizedBox(height: AppSpacing.lg),
            // Terms & Conditions
            Row(
              children: [
                Checkbox(
                  value: true,
                  onChanged: (_) {},
                ),
                Expanded(
                  child: Text(
                    'I agree to the terms and conditions',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Pay Button
            AppButton(
              label: 'Proceed to Payment',
              onPressed: _handlePayment,
            ),
            const SizedBox(height: AppSpacing.md),
            // Cancel Button
            AppButton(
              label: 'Cancel',
              onPressed: () => context.pop(),
              type: ButtonType.secondary,
            ),
          ],
        ),
      ),
    );
    });
  }

  Widget _buildPlanCard({
    required String title,
    required String subtitle,
    required String price,
    required String planCode,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlanCode = planCode;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.bgCard,
          border: Border.all(
            color:
                isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  price,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required String title,
    required IconData icon,
    required String methodId,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = methodId;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.bgCard,
          border: Border.all(
            color:
                isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePayment() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 2));

      // Close loading dialog
      Navigator.pop(context);

      // Get current user
      final userId = supabaseService.getCurrentUserId();
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to purchase a subscription.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final activePlans =
          planService.plans.where((p) => p.isActive).toList(growable: false);
      final selectedPlan = _getSelectedPlan(activePlans);
      if (selectedPlan == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a subscription plan.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Assign subscription + reward points using shared admin method
      final success = await userService.adminAssignSubscription(
        userId: userId,
        plan: selectedPlan.code,
        amount: selectedPlan.price,
      );

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userService.errorMessage.value.isNotEmpty
                ? userService.errorMessage.value
                : 'Failed to activate subscription.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Refresh points after subscription reward and deduct quiz cost.
      await pointsService.getUserPoints(userId);
      final q = _quiz;
      if (q != null) {
        final cost = _requiredPoints(q);
        if (cost > 0) {
          final deducted = await pointsService.deductPoints(
            userId: userId,
            points: cost,
          );
          if (!deducted) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(pointsService.errorMessage.value.isNotEmpty
                    ? pointsService.errorMessage.value
                    : 'Subscription activated, but could not deduct quiz points.'),
                backgroundColor: AppColors.error,
              ),
            );
            return;
          }
        }
      }

      // Show success dialog
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Subscription Activated'),
          content: Text(
            'Your ${selectedPlan.name} subscription is active. '
            'You have received reward points for this plan.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to quiz
                context.push(
                  AppRoutes.quizTaking.replaceFirst(':quizId', widget.quizId),
                );
              },
              child: const Text('Continue to Quiz'),
            ),
          ],
        ),
      );
    } catch (_) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong while processing payment.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  int _requiredPoints(Quiz quiz) {
    if (quiz.pointsCost > 0) return quiz.pointsCost;

    final difficulty = (quiz.difficulty ?? 1).clamp(1, 5);
    final perQuestion = (difficulty * 2);
    final derived = (quiz.totalQuestions * perQuestion).clamp(5, 500);
    return derived;
  }

  SubscriptionPlan? _getSelectedPlan(List<SubscriptionPlan> activePlans) {
    if (activePlans.isEmpty) return null;
    final code = _selectedPlanCode;
    if (code == null) return activePlans.first;
    for (final p in activePlans) {
      if (p.code == code) return p;
    }
    return activePlans.first;
  }
}
