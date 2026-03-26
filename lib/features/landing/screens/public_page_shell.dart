import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import 'home_landing_screen.dart';

class PublicPageShell extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const PublicPageShell({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 980;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  colors: [AppColors.bgPrimaryDark, AppColors.primaryDark],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : const LinearGradient(
                  colors: [AppColors.primaryGradientStart, AppColors.primary],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.screenVertical,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                child: PublicTopNavBar(
                  isMobile: isMobile,
                  key: ValueKey(currentRoute),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    0,
                    AppSpacing.screenHorizontal,
                    AppSpacing.screenVertical,
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      scaffoldBackgroundColor: Colors.white,
                      appBarTheme: const AppBarTheme(
                        backgroundColor: Colors.white,
                        toolbarHeight: 0,
                        elevation: 0,
                        surfaceTintColor: Colors.white,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.transparent,
                        iconTheme: IconThemeData(color: Colors.transparent),
                        titleTextStyle: TextStyle(
                          color: Colors.transparent,
                          fontSize: 0,
                        ),
                      ),
                    ),
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
