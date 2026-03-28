import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/routes/app_router.dart';

class HomeLandingScreen extends StatelessWidget {
  final String currentRoute;

  const HomeLandingScreen({super.key, this.currentRoute = AppRoutes.root});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 980;

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
                child: PublicTopNavBar(isMobile: isMobile),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    0,
                    AppSpacing.screenHorizontal,
                    AppSpacing.screenVertical,
                  ),
                  child: _PageContent(
                    isMobile: isMobile,
                    currentRoute: currentRoute,
                    isDark: isDark,
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

class PublicTopNavBar extends StatelessWidget {
  final bool isMobile;

  const PublicTopNavBar({super.key, required this.isMobile});

  static const navItems = <_NavItem>[
    _NavItem(label: 'Home', route: AppRoutes.root),
    _NavItem(label: 'About RankX', route: AppRoutes.publicAbout),
    _NavItem(label: 'Terms & Conditions', route: AppRoutes.publicTerms),
    _NavItem(label: 'Privacy Policy', route: AppRoutes.publicPrivacy),
    _NavItem(label: 'Payment', route: AppRoutes.publicCheckout),
    _NavItem(label: 'Refund / Cancellation', route: AppRoutes.publicRefund),
    _NavItem(label: 'Contact Us', route: AppRoutes.publicContact),
  ];

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 34,
                height: 34,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.auto_graph_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'RankX',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
              ),
            ],
          ),
          if (!isMobile) ...[
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.sm,
                runSpacing: 8,
                children: navItems.map(
                  (item) {
                    final isActive = currentPath == item.route;
                    return TextButton(
                      onPressed: () => context.go(item.route),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        backgroundColor: isActive
                            ? AppColors.secondary.withOpacity(0.12)
                            : Colors.transparent,
                      ),
                      child: Text(
                        item.label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: isActive
                                  ? AppColors.secondary
                                  : AppColors.primary,
                              fontWeight:
                                  isActive ? FontWeight.w800 : FontWeight.w600,
                            ),
                      ),
                    );
                  },
                ).toList(),
              ),
            ),
          ],
          if (isMobile)
            PopupMenuButton<String>(
              onSelected: (route) => context.go(route),
              itemBuilder: (_) => [
                ...navItems.map(
                  (item) => PopupMenuItem<String>(
                    value: item.route,
                    child: Text(
                      item.label,
                      style: TextStyle(
                        color: currentPath == item.route
                            ? AppColors.secondary
                            : AppColors.primary,
                        fontWeight: currentPath == item.route
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: AppRoutes.authStart,
                  child: Text('Login'),
                ),
              ],
              offset: const Offset(0, 40),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Icon(Icons.menu, color: AppColors.primary),
              ),
            ),
          const SizedBox(width: AppSpacing.sm),
          if (!isMobile)
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.authStart),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Login'),
            ),
        ],
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final bool isMobile;
  final String currentRoute;
  final bool isDark;

  const _PageContent({
    required this.isMobile,
    required this.currentRoute,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (currentRoute == AppRoutes.root) {
      if (isMobile) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isDark ? 0.08 : 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.22 : 0.28),
            ),
          ),
          child: const Column(
            children: [
              _HeroSection(isMobile: true),
              SizedBox(height: AppSpacing.lg),
              _AnimatedQuizVisual(),
            ],
          ),
        );
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(isDark ? 0.08 : 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: Colors.white.withOpacity(isDark ? 0.22 : 0.28),
          ),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: _HeroSection(isMobile: false)),
            SizedBox(width: AppSpacing.xl),
            Expanded(flex: 4, child: _AnimatedQuizVisual()),
          ],
        ),
      );
    }

    return _InfoSectionCard(currentRoute: currentRoute);
  }
}

class _HeroSection extends StatelessWidget {
  final bool isMobile;

  const _HeroSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final align = isMobile ? TextAlign.center : TextAlign.left;
    final crossAxis =
        isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final w = MediaQuery.sizeOf(context).width;
    final titleSize = w < 1100 ? 26.0 : null;

    return Column(
      crossAxisAlignment: crossAxis,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'RankX — Quiz. Practice. Rank up.',
          textAlign: align,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.15,
                fontSize: titleSize,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'RankX is an online quiz platform for exam preparation: practice by topic or take full-length tests, '
          'see how you score against others, and build a steady daily study habit.',
          textAlign: align,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.94),
                height: 1.45,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'How it works',
          textAlign: align,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.secondaryLight,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '1. Sign in\n'
          '2. Choose a quiz\n'
          '3. Pay in ₹ only when the quiz is paid\n'
          '4. Attempt the quiz and earn marks\n'
          '5. View instant results and your live rank',
          textAlign: align,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.9),
                height: 1.55,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.22),
            // borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.secondaryLight.withOpacity(0.85),
              width: 1.5,
            ),
          ),
          child: Text.rich(
            TextSpan(
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.95),
                    height: 1.45,
                  ),
              children: [
                TextSpan(
                  text: 'Quiz every day',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                ),
                const TextSpan(text: '  ·  '),
                TextSpan(
                  text: 'Pay just ',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.95),
                      ),
                ),
                const TextSpan(
                  text: '₹9',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text:
                      ' per quiz when required; bundles may vary.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.95),
                      ),
                ),
              ],
            ),
            textAlign: align,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Why students use RankX',
          textAlign: align,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white.withOpacity(0.88),
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ..._heroBullets.map(
          (line) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: _HeroBulletLine(text: line, align: align),
          ),
        ),
      ],
    );
  }
}

const _heroBullets = <String>[
  'Real exam–level questions & mixed question types',
  'Instant results with clear performance feedback',
  'Live ranking & leaderboard to track your position',
  'Boost preparation with structured daily quiz practice',
];

class _HeroBulletLine extends StatelessWidget {
  final String text;
  final TextAlign align;

  const _HeroBulletLine({
    required this.text,
    required this.align,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: align == TextAlign.center
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: AppColors.secondaryLight,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            textAlign:
                align == TextAlign.center ? TextAlign.center : TextAlign.start,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.92),
                  height: 1.4,
                ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedQuizVisual extends StatefulWidget {
  const _AnimatedQuizVisual();

  @override
  State<_AnimatedQuizVisual> createState() => _AnimatedQuizVisualState();
}

class _AnimatedQuizVisualState extends State<_AnimatedQuizVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _verticalOffset;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..repeat(reverse: true);
    _verticalOffset = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _rotation = Tween<double>(begin: -0.03, end: 0.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardW = constraints.maxWidth.isFinite
            ? constraints.maxWidth.clamp(200.0, 280.0)
            : 260.0;
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _verticalOffset.value),
              child: Transform.rotate(
                angle: _rotation.value,
                child: child,
              ),
            );
          },
          child: Align(
            alignment: Alignment.topCenter,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: cardW,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Daily Quiz Challenge',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _optionLine(width: 1.0),
                      const SizedBox(height: AppSpacing.sm),
                      _optionLine(width: 0.86, highlight: true),
                      const SizedBox(height: AppSpacing.sm),
                      _optionLine(width: 0.92),
                      const SizedBox(height: AppSpacing.md),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: 0.72,
                          backgroundColor: AppColors.bgSecondary,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _optionLine({required double width, bool highlight = false}) {
    return FractionallySizedBox(
      widthFactor: width,
      child: Container(
        height: 14,
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.secondary.withOpacity(0.35)
              : AppColors.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final String route;

  const _NavItem({required this.label, required this.route});
}

class _InfoSectionCard extends StatelessWidget {
  final String currentRoute;

  const _InfoSectionCard({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final config = _pageMeta[currentRoute] ?? _pageMeta[AppRoutes.publicAbout]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: Colors.white.withOpacity(0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(config.icon, color: AppColors.secondaryLight, size: 30),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  config.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            config.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
        ],
      ),
    );
  }
}

class _PageMeta {
  final String title;
  final String description;
  final IconData icon;

  const _PageMeta({
    required this.title,
    required this.description,
    required this.icon,
  });
}

const Map<String, _PageMeta> _pageMeta = {
  AppRoutes.publicAbout: _PageMeta(
    title: 'About RankX',
    description:
        'RankX helps students learn faster with focused quizzes, practice tests, and real performance growth.',
    icon: Icons.info_outline_rounded,
  ),
  AppRoutes.publicTerms: _PageMeta(
    title: 'Terms & Conditions',
    description:
        'Read rules, responsibilities, and usage terms to understand how RankX services work.',
    icon: Icons.description_outlined,
  ),
  AppRoutes.publicPrivacy: _PageMeta(
    title: 'Privacy Policy',
    description:
        'See how your data is collected, stored, protected, and used across the platform.',
    icon: Icons.privacy_tip_outlined,
  ),
  AppRoutes.publicCheckout: _PageMeta(
    title: 'Checkout & payment',
    description:
        'Review pricing, your quiz selection, and secure payment options before you pay in ₹.',
    icon: Icons.shopping_bag_outlined,
  ),
  AppRoutes.publicRefund: _PageMeta(
    title: 'Refund / Cancellation',
    description:
        'Understand refund eligibility, cancellation policy, and expected processing timelines.',
    icon: Icons.assignment_return_outlined,
  ),
  AppRoutes.publicContact: _PageMeta(
    title: 'Contact Us',
    description:
        'Get help for account, payment, and technical issues through official RankX support channels.',
    icon: Icons.support_agent_outlined,
  ),
};
