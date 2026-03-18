import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/controllers/theme_controller.dart';
import '../../settings/pages/about_rankx_page.dart';
import '../../payment/pages/checkout_page.dart';
import '../../settings/pages/refund_policy_page.dart';
import '../../settings/pages/privacy_policy_page.dart';
import '../../settings/pages/contact_us_page.dart';

class SettingsScreenController extends GetxController {
  late ThemeController themeController;

  @override
  void onInit() {
    super.onInit();
    themeController = Get.find<ThemeController>();
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsScreenController controller;
  final supabaseService = Get.find<SupabaseService>();
  String? _termsContent;
  bool _loadingTerms = false;

  @override
  void initState() {
    super.initState();
    controller = Get.put(SettingsScreenController());
    _loadTermsAndConditions();
  }

  Future<void> _loadTermsAndConditions() async {
    setState(() {
      _loadingTerms = true;
    });
    try {
      // Get active terms and conditions from agreements table
      final agreements = await supabaseService.query(
        table: AppConstants.agreementsTable,
        filters: {'is_active': true},
        orderBy: 'created_at',
        ascending: false,
        limit: 1,
      );
      if (agreements.isNotEmpty) {
        setState(() {
          _termsContent = agreements.first['content'] as String?;
        });
      }
    } catch (e) {
      // Keep null if failed to load
    } finally {
      setState(() {
        _loadingTerms = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Display Settings
            _buildSectionHeader(context, 'Display Settings'),
            _buildSettingItem(
              context: context,
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              subtitle: 'Enable dark theme',
              trailing: Obx(
                () => Switch(
                  value: controller.themeController.isDarkMode,
                  onChanged: (value) {
                    controller.themeController.toggleDarkMode(value);
                  },
                ),
              ),
            ),
            _buildDivider(),
            _buildSettingItem(
              context: context,
              icon: Icons.language_outlined,
              title: 'Language',
              subtitle: Obx(() {
                final lang = controller.themeController.language.value;
                final langNames = {
                  'en': 'English',
                  'es': 'Spanish',
                  'fr': 'French',
                  'de': 'German',
                  'zh': 'Chinese',
                };
                return Text('Current: ${langNames[lang] ?? lang}');
              }),
              onTap: _showLanguageDialog,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Account Settings
            _buildSectionHeader(context, 'Account Settings'),
            _buildSettingItem(
              context: context,
              icon: Icons.description_outlined,
              title: 'Terms & Conditions',
              subtitle: _loadingTerms 
                  ? 'Loading...' 
                  : (_termsContent != null ? 'Read our terms and conditions' : 'No terms available'),
              onTap: _termsContent != null ? _showTermsDialog : null,
            ),
            _buildDivider(),
            _buildSettingItem(
              context: context,
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'This page explains how you handle user data',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Payment Settings
            _buildSectionHeader(context, 'Payment Settings'),
            _buildSettingItem(
              context: context,
              icon: Icons.receipt_long_outlined,
              title: 'Checkout',
              subtitle: 'View checkout page',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CheckoutPage()),
                );
              },
            ),
            _buildDivider(),
            _buildSettingItem(
              context: context,
              icon: Icons.money_off_outlined,
              title: 'Refund / Cancellation',
              subtitle: 'Read our refund policy',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RefundPolicyPage()),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // App Information
            _buildSectionHeader(context, 'App Information'),
            _buildSettingItem(
              context: context,
              icon: Icons.info_outlined,
              title: 'About RankX',
              subtitle: 'Learn more about our app',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutRankXPage()),
                );
              },
            ),
            _buildDivider(),
            _buildSettingItem(
              context: context,
              icon: Icons.contact_phone_outlined,
              title: 'Contact Us',
              subtitle: 'Get in touch with us',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ContactUsPage()),
                );
              },
            ),
            _buildDivider(),
            _buildSettingItem(
              context: context,
              icon: Icons.star_outline,
              title: 'Rate App',
              subtitle: 'Share your feedback on the app store',
              onTap: _rateApp,
            ),
            const SizedBox(height: AppSpacing.lg * 2),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required dynamic subtitle, // Can be String or Widget
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: subtitle is Widget 
          ? subtitle 
          : Text(
              subtitle as String,
              style: Theme.of(context).textTheme.bodySmall,
            ),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: trailing == null ? onTap : null,
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Divider(
        color: Colors.grey.withOpacity(0.2),
        height: 1,
      ),
    );
  }

  void _showLanguageDialog() {
    final languages = [
      {'code': 'en', 'name': 'English'},
      {'code': 'es', 'name': 'Spanish'},
      {'code': 'fr', 'name': 'French'},
      {'code': 'de', 'name': 'German'},
      {'code': 'zh', 'name': 'Chinese'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final lang = languages[index];
              return Obx(() => ListTile(
                title: Text(lang['name']!),
                onTap: () {
                  controller.themeController.setLanguage(lang['code']!);
                  Navigator.pop(context);
                },
                trailing: controller.themeController.language.value == lang['code']
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
              ));
            },
          ),
        ),
      ),
    );
  }

  void _showTermsDialog() {
    if (_termsContent == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms & Conditions'),
        content: SingleChildScrollView(
          child: Text(
            _termsContent!,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _rateApp() async {
    try {
      // Open app store - replace with your actual app package name/ID
      // For Android: https://play.google.com/store/apps/details?id=YOUR_PACKAGE_NAME
      // For iOS: https://apps.apple.com/app/idYOUR_APP_ID
      const storeUrl = 'https://play.google.com/store/apps/details?id=com.example.rankx';
      
      final url = Uri.parse(storeUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to open app store. Please update the app store URL in settings_screen.dart')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }


}
