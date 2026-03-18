import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/export_text_file.dart';
import '../../../core/widgets/app_widgets.dart';

class AdminPaymentTrackingScreen extends StatefulWidget {
  final bool showAppBar;

  const AdminPaymentTrackingScreen({super.key, this.showAppBar = true});

  @override
  State<AdminPaymentTrackingScreen> createState() =>
      _AdminPaymentTrackingScreenState();
}

class _AdminPaymentTrackingScreenState extends State<AdminPaymentTrackingScreen> {
  final supabaseService = Get.find<SupabaseService>();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _payments = const [];
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      dynamic q = supabaseService.client
          .from(AppConstants.paymentsTable)
          .select(
            'id,user_id,quiz_id,amount,payment_method,status,transaction_id,created_at,completed_at',
          )
          .order('created_at', ascending: false);

      if (_statusFilter != 'all') {
        q = q.eq('status', _statusFilter);
      }

      final rows = await q;
      setState(() {
        _payments = (rows as List)
            .cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load payments: ${e.toString()}';
        _loading = false;
      });
    }
  }

  String _toCsv(List<Map<String, dynamic>> rows) {
    const headers = [
      'id',
      'user_id',
      'quiz_id',
      'amount',
      'payment_method',
      'status',
      'transaction_id',
      'created_at',
      'completed_at',
    ];

    String esc(Object? v) {
      final s = (v ?? '').toString();
      final escaped = s.replaceAll('"', '""');
      return '"$escaped"';
    }

    final sb = StringBuffer();
    sb.writeln(headers.map(esc).join(','));
    for (final r in rows) {
      sb.writeln(headers.map((h) => esc(r[h])).join(','));
    }
    return sb.toString();
  }

  Future<void> _exportPayments() async {
    final csv = _toCsv(_payments);
    final ts = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final fileName = 'payments_report_$ts.csv';
    await exportTextFile(
      filename: fileName,
      content: csv,
      mimeType: 'text/csv',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report downloaded.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Curved top spacing
          const SizedBox(height: 20),
          // Content with curved top
          CurvedTopContainer(
            topRadius: 30,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Responsive Header Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              if (isWide) {
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Payment Tracking',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    DropdownButton<String>(
                      value: _statusFilter,
                      isDense: true,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _statusFilter = v);
                        _loadPayments();
                      },
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(
                            value: AppConstants.paymentPending,
                            child: Text('Pending')),
                        DropdownMenuItem(
                            value: AppConstants.paymentCompleted,
                            child: Text('Completed')),
                        DropdownMenuItem(
                            value: AppConstants.paymentFailed,
                            child: Text('Failed')),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: _loadPayments,
                      icon: const Icon(Icons.refresh),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    TextButton.icon(
                      onPressed: _payments.isEmpty ? null : _exportPayments,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Download Excel'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Tracking',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            value: _statusFilter,
                            isDense: true,
                            isExpanded: true,
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _statusFilter = v);
                              _loadPayments();
                            },
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All')),
                              DropdownMenuItem(
                                  value: AppConstants.paymentPending,
                                  child: Text('Pending')),
                              DropdownMenuItem(
                                  value: AppConstants.paymentCompleted,
                                  child: Text('Completed')),
                              DropdownMenuItem(
                                  value: AppConstants.paymentFailed,
                                  child: Text('Failed')),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Refresh',
                          onPressed: _loadPayments,
                          icon: const Icon(Icons.refresh),
                        ),
                        IconButton(
                          tooltip: 'Download Excel',
                          onPressed: _payments.isEmpty ? null : _exportPayments,
                          icon: const Icon(Icons.download),
                        ),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_loading)
            const AppLoadingWidget(message: 'Loading payments...')
          else if (_error != null)
            AppErrorWidget(message: _error!, onRetry: _loadPayments)
          else if (_payments.isEmpty)
            Center(
              child: AppCard(
                backgroundColor: AppColors.bgSecondary,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.payment_outlined,
                      size: 64,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No payments found.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Payments will appear here once users make transactions.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                if (isWide) {
                  return AppCard(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Amount')),
                          DataColumn(label: Text('Method')),
                          DataColumn(label: Text('User')),
                          DataColumn(label: Text('Quiz')),
                          DataColumn(label: Text('Created')),
                          DataColumn(label: Text('Txn')),
                        ],
                        rows: _payments.map((p) {
                          final status = (p['status'] ?? '').toString();
                          final amount = (p['amount'] ?? 0).toString();
                          final method = (p['payment_method'] ?? '').toString();
                          final userId = (p['user_id'] ?? '').toString();
                          final quizId = (p['quiz_id'] ?? '').toString();
                          final createdAt = (p['created_at'] ?? '').toString();
                          final txn = (p['transaction_id'] ?? '').toString();
                          return DataRow(cells: [
                            DataCell(Text(status)),
                            DataCell(Text('₹$amount')),
                            DataCell(Text(method)),
                            DataCell(Text(userId.isEmpty ? '-' : '${userId.substring(0, 8)}...')),
                            DataCell(Text(quizId.isEmpty ? '-' : '${quizId.substring(0, 8)}...')),
                            DataCell(Text(createdAt.isEmpty ? '-' : createdAt)),
                            DataCell(Text(txn.isEmpty ? '-' : txn)),
                          ]);
                        }).toList(),
                      ),
                    ),
                  );
                } else {
                  // Mobile-friendly card layout
                  return Column(
                    children: _payments.map((p) {
                      final status = (p['status'] ?? '').toString();
                      final amount = (p['amount'] ?? 0).toString();
                      final method = (p['payment_method'] ?? '').toString();
                      final userId = (p['user_id'] ?? '').toString();
                      final quizId = (p['quiz_id'] ?? '').toString();
                      final createdAt = (p['created_at'] ?? '').toString();
                      final txn = (p['transaction_id'] ?? '').toString();
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: status == 'completed' 
                                          ? AppColors.success.withOpacity(0.1)
                                          : status == 'pending'
                                              ? AppColors.warning.withOpacity(0.1)
                                              : AppColors.error.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        color: status == 'completed' 
                                            ? AppColors.success
                                            : status == 'pending'
                                                ? AppColors.warning
                                                : AppColors.error,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '₹$amount',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _buildInfoRow(Icons.payment, 'Method', method),
                              _buildInfoRow(Icons.person, 'User', userId.isEmpty ? '-' : '${userId.substring(0, 8)}...'),
                              _buildInfoRow(Icons.quiz, 'Quiz', quizId.isEmpty ? '-' : '${quizId.substring(0, 8)}...'),
                              if (createdAt.isNotEmpty)
                                _buildInfoRow(Icons.calendar_today, 'Created', createdAt),
                              if (txn.isNotEmpty)
                                _buildInfoRow(Icons.receipt, 'Transaction', txn),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }
              },
            ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );

    if (!widget.showAppBar) return body;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Tracking'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPayments),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _payments.isEmpty ? null : _exportPayments,
            tooltip: 'Download CSV',
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}


