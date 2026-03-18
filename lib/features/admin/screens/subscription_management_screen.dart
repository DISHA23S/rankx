import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/models/subscription_plan_model.dart';
import '../../../core/services/subscription_plan_service.dart';
import '../../../core/widgets/app_widgets.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends State<SubscriptionManagementScreen> {
  final SubscriptionPlanService planService =
      Get.put(SubscriptionPlanService());

  @override
  void initState() {
    super.initState();
    planService.fetchPlans();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Subscription'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: planService.fetchPlans,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openPlanDialog(),
          ),
        ],
      ),
      body: Obx(() {
        if (planService.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (planService.plans.isEmpty) {
          return const Center(
            child: Text('No subscription plans yet. Tap + to create one.'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: planService.plans.length,
          itemBuilder: (context, index) {
            final plan = planService.plans[index];
            return _buildPlanCard(plan);
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openPlanDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        backgroundColor: isDark ? AppColors.bgCardDark : AppColors.bgCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Code: ${plan.code} • ${plan.durationDays} days',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: plan.isActive,
                  onChanged: (value) {
                    planService.createOrUpdatePlan(
                      id: plan.id,
                      name: plan.name,
                      code: plan.code,
                      description: plan.description,
                      durationDays: plan.durationDays,
                      price: plan.price,
                      points: plan.points,
                      isActive: value,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              plan.description ?? '',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.md,
              children: [
                Chip(
                  avatar: const Icon(Icons.currency_rupee, size: 16),
                  label: Text(plan.price.toStringAsFixed(2)),
                ),
                Chip(
                  avatar: const Icon(Icons.stars, size: 16),
                  label: Text('${plan.points} points'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _openPlanDialog(plan: plan),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton.icon(
                  onPressed: () => _confirmDelete(plan),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPlanDialog({SubscriptionPlan? plan}) async {
    final nameController = TextEditingController(text: plan?.name ?? '');
    final codeController = TextEditingController(text: plan?.code ?? '');
    final descController =
        TextEditingController(text: plan?.description ?? '');
    final priceController =
        TextEditingController(text: plan?.price.toString() ?? '');
    final durationController =
        TextEditingController(text: plan?.durationDays.toString() ?? '');
    final pointsController =
        TextEditingController(text: plan?.points.toString() ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(plan == null ? 'Create Plan' : 'Edit Plan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Name',
                controller: nameController,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: 'Code (unique, e.g. daily, weekly)',
                controller: codeController,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: 'Description',
                controller: descController,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: 'Duration (days)',
                controller: durationController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: 'Price (₹)',
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: 'Reward Points',
                controller: pointsController,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(plan == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      final name = nameController.text.trim();
      final code = codeController.text.trim();
      final duration = int.tryParse(durationController.text.trim()) ?? 0;
      final price = double.tryParse(priceController.text.trim()) ?? 0;
      final points = int.tryParse(pointsController.text.trim()) ?? 0;

      if (name.isEmpty || code.isEmpty || duration <= 0 || price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all required fields correctly.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final success = await planService.createOrUpdatePlan(
        id: plan?.id,
        name: name,
        code: code,
        description: descController.text.trim().isEmpty
            ? null
            : descController.text.trim(),
        durationDays: duration,
        price: price,
        points: points,
        isActive: plan?.isActive ?? true,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(planService.errorMessage.value),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(SubscriptionPlan plan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text('Are you sure you want to delete "${plan.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await planService.deletePlan(plan.id);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(planService.errorMessage.value),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}


