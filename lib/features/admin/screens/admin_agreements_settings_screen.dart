import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/app_widgets.dart';

class AdminAgreementsSettingsScreen extends StatefulWidget {
  final bool showAppBar;

  const AdminAgreementsSettingsScreen({super.key, this.showAppBar = true});

  @override
  State<AdminAgreementsSettingsScreen> createState() =>
      _AdminAgreementsSettingsScreenState();
}

class _AdminAgreementsSettingsScreenState
    extends State<AdminAgreementsSettingsScreen> {
  final supabaseService = Get.find<SupabaseService>();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _agreements = const [];

  @override
  void initState() {
    super.initState();
    _loadAgreements();
  }

  Future<void> _loadAgreements() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await supabaseService.client
          .from(AppConstants.agreementsTable)
          .select(
            'id,title,content,document_url,is_active,created_at,updated_at',
          )
          .order('created_at', ascending: false);

      setState(() {
        _agreements = (rows as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load agreements: ${e.toString()}';
        _loading = false;
      });
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> agreement, bool value) async {
    try {
      await supabaseService.client
          .from(AppConstants.agreementsTable)
          .update({
            'is_active': value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', agreement['id']);
      await _loadAgreements();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _openAgreementDialog({Map<String, dynamic>? agreement}) async {
    // Navigate to full-screen editor
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => _AgreementEditorScreen(agreement: agreement),
      ),
    );

    if (result != null) {
      try {
        if (agreement == null) {
          await supabaseService.client
              .from(AppConstants.agreementsTable)
              .insert({
                'title': result['title'],
                'content': result['content'],
                'document_url': result['document_url'],
                'is_active': result['is_active'],
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              });
        } else {
          await supabaseService.client
              .from(AppConstants.agreementsTable)
              .update({
                'title': result['title'],
                'content': result['content'],
                'document_url': result['document_url'],
                'is_active': result['is_active'],
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', agreement['id']);
        }
        await _loadAgreements();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> agreement) async {
    final title = agreement['title']?.toString() ?? 'this agreement';
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Agreement'),
            content: Text('Are you sure you want to delete "$title"?'),
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
    if (confirm != true) return;
    try {
      await supabaseService.client
          .from(AppConstants.agreementsTable)
          .delete()
          .eq('id', agreement['id']);
      await _loadAgreements();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Agreement Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _loadAgreements,
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: AppSpacing.xs),
              TextButton.icon(
                onPressed: () => _openAgreementDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_loading)
            const AppLoadingWidget(message: 'Loading agreements...')
          else if (_error != null)
            AppErrorWidget(message: _error!, onRetry: _loadAgreements)
          else if (_agreements.isEmpty)
            AppCard(
              backgroundColor: AppColors.bgSecondary,
              child: const Text('No agreements found. Tap Add to create one.'),
            )
          else
            ..._agreements.map((a) {
              final title = a['title']?.toString() ?? '';
              final content = a['content']?.toString() ?? '';
              final isActive = (a['is_active'] as bool?) ?? true;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Switch(
                            value: isActive,
                            onChanged: (v) => _toggleActive(a, v),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        content,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _openAgreementDialog(agreement: a),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit'),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          TextButton.icon(
                            onPressed: () => _confirmDelete(a),
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
            }),
        ],
      ),
    );

    if (!widget.showAppBar) return body;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agreement Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAgreements,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openAgreementDialog(),
          ),
        ],
      ),
      body: body,
    );
  }
}

// Full-screen Agreement Editor
class _AgreementEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? agreement;

  const _AgreementEditorScreen({this.agreement});

  @override
  State<_AgreementEditorScreen> createState() => _AgreementEditorScreenState();
}

class _AgreementEditorScreenState extends State<_AgreementEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _urlController;
  late bool _isActive;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.agreement?['title']?.toString() ?? '',
    );
    _contentController = TextEditingController(
      text: widget.agreement?['content']?.toString() ?? '',
    );
    _urlController = TextEditingController(
      text: widget.agreement?['document_url']?.toString() ?? '',
    );
    _isActive = (widget.agreement?['is_active'] as bool?) ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _insertFormatting(String before, String after) {
    final text = _contentController.text;
    final selection = _contentController.selection;

    if (selection.start == -1) {
      // No selection, insert at end
      _contentController.text = text + before + after;
      _contentController.selection = TextSelection.collapsed(
        offset: text.length + before.length,
      );
    } else {
      final selectedText = selection.textInside(text);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        before + selectedText + after,
      );
      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(
        offset: selection.start + before.length + selectedText.length,
      );
    }
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(context, {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'document_url':
            _urlController.text.trim().isEmpty
                ? null
                : _urlController.text.trim(),
        'is_active': _isActive,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.agreement == null ? 'Create Agreement' : 'Edit Agreement',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Field
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g., Terms of Service',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Title is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Formatting Toolbar
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Formatting Guide:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.xs,
                              children: [
                                _FormatButton(
                                  icon: Icons.format_bold,
                                  label: 'Bold',
                                  onTap: () => _insertFormatting('**', '**'),
                                ),
                                _FormatButton(
                                  icon: Icons.format_italic,
                                  label: 'Italic',
                                  onTap: () => _insertFormatting('*', '*'),
                                ),
                                _FormatButton(
                                  icon: Icons.title,
                                  label: 'Heading',
                                  onTap: () => _insertFormatting('\n## ', '\n'),
                                ),
                                _FormatButton(
                                  icon: Icons.format_list_bulleted,
                                  label: 'Bullet',
                                  onTap: () => _insertFormatting('\n- ', ''),
                                ),
                                _FormatButton(
                                  icon: Icons.format_list_numbered,
                                  label: 'Number',
                                  onTap: () => _insertFormatting('\n1. ', ''),
                                ),
                                _FormatButton(
                                  icon: Icons.format_quote,
                                  label: 'Quote',
                                  onTap: () => _insertFormatting('\n> ', ''),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            const Text(
                              'Use line breaks for paragraphs. Supports markdown-style formatting.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Content Field
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: 'Content',
                        hintText:
                            'Enter the agreement content here...\n\nUse formatting buttons above for styling.',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 20,
                      minLines: 15,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        height: 1.6,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Content is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Document URL (optional)
                    TextFormField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        labelText: 'Document URL (Optional)',
                        hintText: 'https://example.com/terms.pdf',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Active Toggle
                    SwitchListTile(
                      title: const Text('Active'),
                      subtitle: const Text(
                        'Make this agreement visible to users',
                      ),
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Agreement'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Format Button Widget
class _FormatButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FormatButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
