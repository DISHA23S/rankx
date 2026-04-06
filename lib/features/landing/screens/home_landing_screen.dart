import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/quiz_result_service.dart';

/// Landing visuals aligned with [AppColors] (RankX blue + orange). Layout & motion unchanged.
class _LandingTheme {
  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment(-0.85, -0.85),
    end: Alignment(0.85, 0.85),
    colors: [
      AppColors.bgPrimaryDark,
      AppColors.primaryDark,
      AppColors.bgSecondaryDark,
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient heroTitleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), AppColors.secondaryLight],
  );
}

class HomeLandingScreen extends StatefulWidget {
  final String currentRoute;

  const HomeLandingScreen({super.key, this.currentRoute = AppRoutes.root});

  @override
  State<HomeLandingScreen> createState() => _HomeLandingScreenState();
}

class _HomeLandingScreenState extends State<HomeLandingScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _particleController;

  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _howKey = GlobalKey();
  final GlobalKey _pricingKey = GlobalKey();
  final GlobalKey _leaderboardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _particleController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      alignment: 0.12,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 980;
    final isRoot = widget.currentRoute == AppRoutes.root;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(decoration: const BoxDecoration(gradient: _LandingTheme.pageGradient)),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ParticlesPainter(progress: _particleController.value),
                );
              },
            ),
          ),
          SafeArea(
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
                    landingStyle: isRoot,
                    onScrollToFeatures: () => _scrollTo(_featuresKey),
                    onScrollToHow: () => _scrollTo(_howKey),
                    onScrollToPricing: () => _scrollTo(_pricingKey),
                    onScrollToLeaderboard: () => _scrollTo(_leaderboardKey),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenHorizontal,
                      0,
                      AppSpacing.screenHorizontal,
                      AppSpacing.screenVertical,
                    ),
                    child: _PageContent(
                      isMobile: isMobile,
                      currentRoute: widget.currentRoute,
                      featuresKey: _featuresKey,
                      howKey: _howKey,
                      pricingKey: _pricingKey,
                      leaderboardKey: _leaderboardKey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  _ParticlesPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const tileW = 200.0;
    const tileH = 100.0;
    final offsetY = progress * tileH;

    final paints = [
      (const Offset(20, 30), AppColors.secondary, 2.0),
      (const Offset(40, 70), AppColors.primaryLight, 2.0),
      (const Offset(90, 40), AppColors.warning, 1.0),
      (const Offset(130, 80), AppColors.secondaryLight, 1.0),
    ];

    for (var y = -tileH; y < size.height + tileH; y += tileH) {
      for (var x = -tileW; x < size.width + tileW; x += tileW) {
        for (final p in paints) {
          canvas.drawCircle(
            Offset(x + p.$1.dx, y + p.$1.dy - offsetY),
            p.$3,
            Paint()..color = p.$2.withOpacity(0.35),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class PublicTopNavBar extends StatelessWidget {
  final bool isMobile;
  final bool landingStyle;
  final VoidCallback? onScrollToFeatures;
  final VoidCallback? onScrollToHow;
  final VoidCallback? onScrollToPricing;
  final VoidCallback? onScrollToLeaderboard;

  const PublicTopNavBar({
    super.key,
    required this.isMobile,
    this.landingStyle = false,
    this.onScrollToFeatures,
    this.onScrollToHow,
    this.onScrollToPricing,
    this.onScrollToLeaderboard,
  });

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

    if (landingStyle) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bgPrimaryDark.withOpacity(0.35),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.secondary.withOpacity(0.22)),
            ),
            child: Row(
              children: [
                _LandingLogo(onTap: () => context.go(AppRoutes.root)),
                if (!isMobile) ...[
                  const Spacer(),
                  _landingLink(context, 'Features', onScrollToFeatures),
                  _landingLink(context, 'How it Works', onScrollToHow),
                  _landingLink(context, 'Pricing', onScrollToPricing),
                  _landingLink(context, 'Leaderboard', onScrollToLeaderboard),
                ],
                const Spacer(),
                if (isMobile)
                  PopupMenuButton<String>(
                    color: AppColors.bgCardDark,
                    onSelected: (value) => _handleLandingMenu(context, value),
                    itemBuilder: (_) => [
                      _menuScroll('scroll:features', 'Features'),
                      _menuScroll('scroll:how', 'How it Works'),
                      _menuScroll('scroll:pricing', 'Pricing'),
                      _menuScroll('scroll:leaderboard', 'Leaderboard'),
                      const PopupMenuDivider(),
                      ...navItems.map(
                        (item) => PopupMenuItem<String>(
                          value: item.route,
                          child: Text(
                            item.label,
                            style: TextStyle(
                              color: currentPath == item.route
                                  ? AppColors.secondary
                                  : Colors.white,
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
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Icon(Icons.menu_rounded, color: Colors.white),
                    ),
                  )
                else
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.go(AppRoutes.authStart),
                      borderRadius: BorderRadius.circular(999),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryLight.withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

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
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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

  void _handleLandingMenu(BuildContext context, String value) {
    switch (value) {
      case 'scroll:features':
        onScrollToFeatures?.call();
        break;
      case 'scroll:how':
        onScrollToHow?.call();
        break;
      case 'scroll:pricing':
        onScrollToPricing?.call();
        break;
      case 'scroll:leaderboard':
        onScrollToLeaderboard?.call();
        break;
      default:
        context.go(value);
    }
  }

  PopupMenuItem<String> _menuScroll(String value, String label) {
    return PopupMenuItem<String>(
      value: value,
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _landingLink(BuildContext context, String label, VoidCallback? onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(foregroundColor: Colors.white.withOpacity(0.92)),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
    );
  }
}

class _LandingLogo extends StatelessWidget {
  final VoidCallback onTap;

  const _LandingLogo({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 36,
            height: 36,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => AppColors.secondaryGradient
                .createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            child: const Text(
              'RankX',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            ' ↑',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w300,
              color: AppColors.secondary.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final bool isMobile;
  final String currentRoute;
  final GlobalKey featuresKey;
  final GlobalKey howKey;
  final GlobalKey pricingKey;
  final GlobalKey leaderboardKey;

  const _PageContent({
    required this.isMobile,
    required this.currentRoute,
    required this.featuresKey,
    required this.howKey,
    required this.pricingKey,
    required this.leaderboardKey,
  });

  @override
  Widget build(BuildContext context) {
    if (currentRoute == AppRoutes.root) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LandingHeroSection(isMobile: isMobile),
          SizedBox(height: isMobile ? AppSpacing.xxl : 72),
          _SectionTitle(
            sectionKey: featuresKey,
            title: 'Why Choose RankX?',
          ),
          const SizedBox(height: AppSpacing.xl),
          _FeaturesGrid(isMobile: isMobile),
          SizedBox(height: isMobile ? AppSpacing.xxl : 72),
          _SectionTitle(
            sectionKey: howKey,
            title: 'How It Works',
          ),
          const SizedBox(height: AppSpacing.xl),
          _HowItWorksRow(isMobile: isMobile),
          SizedBox(height: isMobile ? AppSpacing.xxl : 72),
          _PricingSection(key: pricingKey),
          SizedBox(height: isMobile ? AppSpacing.xxl : 72),
          _LiveLeaderboardSection(key: leaderboardKey),
          SizedBox(height: isMobile ? AppSpacing.xxl : 72),
          const _CtaBanner(),
          const SizedBox(height: AppSpacing.xxl),
          const _LandingFooter(),
        ],
      );
    }

    return _InfoSectionCard(currentRoute: currentRoute);
  }
}

class _LandingHeroSection extends StatelessWidget {
  final bool isMobile;

  const _LandingHeroSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w800,
          height: 1.08,
          fontSize: isMobile ? 36 : 52,
        );

    final content = Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        _gradientHeadline(
          'Practice Daily.\nRank Nationally.',
          titleStyle ?? const TextStyle(fontSize: 40, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Daily DDCET Quiz Platform with Real Exam-Level Questions',
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white.withOpacity(0.88),
                height: 1.4,
                fontSize: isMobile ? 16 : 18,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: isMobile ? Alignment.center : Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppColors.secondaryGradient,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Text(
              '👉 Only ₹9 per Quiz',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.bgPrimaryDark,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            _PrimaryCtaButton(
              label: 'Start Quiz',
              onPressed: () => _navigateToQuiz(context),
            ),
            _SecondaryCtaButton(
              label: 'View Leaderboard',
              onPressed: () => _navigateToLeaderboard(context),
            ),
          ],
        ),
      ],
    );

    if (isMobile) {
      return Column(
        children: [
          content,
          const SizedBox(height: AppSpacing.xl),
          const _HeroMockupCard(),
        ],
      );
    }

    // Fixed height: `Row` sits in a vertical `SingleChildScrollView` (unbounded height).
    return SizedBox(
      height: 560,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 55, child: content),
          const SizedBox(width: AppSpacing.xl),
          const Expanded(flex: 45, child: _HeroMockupCard()),
        ],
      ),
    );
  }

  Widget _gradientHeadline(String text, TextStyle base) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => _LandingTheme.heroTitleGradient
          .createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(
        text,
        textAlign: isMobile ? TextAlign.center : TextAlign.start,
        style: base.copyWith(color: Colors.white),
      ),
    );
  }
}

void _navigateToQuiz(BuildContext context) {
  try {
    final auth = Get.find<AuthService>();
    if (auth.isAuthenticated.value) {
      context.go(AppRoutes.quizList);
    } else {
      context.go(AppRoutes.authStart);
    }
  } catch (_) {
    context.go(AppRoutes.authStart);
  }
}

void _navigateToLeaderboard(BuildContext context) {
  try {
    final auth = Get.find<AuthService>();
    if (auth.isAuthenticated.value) {
      context.go(AppRoutes.userProgress);
    } else {
      context.go(AppRoutes.authStart);
    }
  } catch (_) {
    context.go(AppRoutes.authStart);
  }
}

class _PrimaryCtaButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PrimaryCtaButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryLight.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryCtaButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _SecondaryCtaButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: AppColors.secondary.withOpacity(0.9), width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
    );
  }
}

class _HeroMockupCard extends StatefulWidget {
  const _HeroMockupCard();

  @override
  State<_HeroMockupCard> createState() => _HeroMockupCardState();
}

class _HeroMockupCardState extends State<_HeroMockupCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;
  late final Animation<double> _glowT;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowT = CurvedAnimation(parent: _glow, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowT,
      builder: (context, child) {
        final t = _glowT.value;
        final blueGlow = Color.lerp(
          AppColors.primaryLight.withOpacity(0.35),
          AppColors.secondary.withOpacity(0.45),
          t,
        )!;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
                boxShadow: [
                  BoxShadow(
                    color: blueGlow,
                    blurRadius: 40,
                    spreadRadius: 2,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.bgCardDark, AppColors.primaryDark],
                    ),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.secondary, AppColors.primaryLight],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, c) {
                            return Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                Center(
                                  child: _MockupPulse(
                                    width: c.maxWidth * 0.72,
                                    height: c.maxHeight * 0.55,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Gentle gradient pulse inside the hero mockup (HTML reference).
class _MockupPulse extends StatefulWidget {
  final double width;
  final double height;

  const _MockupPulse({required this.width, required this.height});

  @override
  State<_MockupPulse> createState() => _MockupPulseState();
}

class _MockupPulseState extends State<_MockupPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.06).animate(
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
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(scale: _scale.value, child: child);
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.secondary.withOpacity(0.95),
              AppColors.primaryLight.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final Key? sectionKey;
  final String title;

  const _SectionTitle({this.sectionKey, required this.title});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => AppColors.secondaryGradient
          .createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(
        title,
        key: sectionKey,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 32,
              color: Colors.white,
            ),
      ),
    );
  }
}

class _FeaturesGrid extends StatelessWidget {
  final bool isMobile;

  const _FeaturesGrid({required this.isMobile});

  static const _items = <({String emoji, String title, String body})>[
    (
      emoji: '📘',
      title: 'Daily Practice Quiz',
      body: 'Fresh DDCET questions every day to keep your preparation sharp.',
    ),
    (
      emoji: '🎯',
      title: 'Real Exam-Level Questions',
      body: 'Questions curated exactly like the actual DDCET exam.',
    ),
    (
      emoji: '⚡',
      title: 'Instant Results & Ranking',
      body: 'Get your score and national rank immediately after completion.',
    ),
    (
      emoji: '🚀',
      title: 'Boost Your Preparation',
      body: 'Track progress and climb the ranks with consistent practice.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cross = isMobile || c.maxWidth < 640
            ? 1
            : (c.maxWidth < 1000 ? 2 : 4);
        return GridView.count(
          crossAxisCount: cross,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: isMobile ? 1.15 : 1.05,
          children: _items
              .map(
                (e) => _FeatureCard(emoji: e.emoji, title: e.title, body: e.body),
              )
              .toList(),
        );
      },
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final String emoji;
  final String title;
  final String body;

  const _FeatureCard({
    required this.emoji,
    required this.title,
    required this.body,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover ? -6 : 0, 0),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hover ? AppColors.secondary : AppColors.secondary.withOpacity(0.25),
            width: _hover ? 1.5 : 1,
          ),
          boxShadow: _hover
              ? [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.22),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.82),
                    height: 1.45,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksRow extends StatelessWidget {
  final bool isMobile;

  const _HowItWorksRow({required this.isMobile});

  static const _steps = <({String n, String title, String sub})>[
    (n: '1', title: 'Sign Up / Login', sub: 'Create your account in seconds'),
    (n: '2', title: 'Attempt Daily Quiz', sub: 'Complete 30 high-quality questions'),
    (n: '3', title: 'Get Instant Rank', sub: 'Receive your score and position'),
    (n: '4', title: 'Improve Daily', sub: 'Track progress and climb ranks'),
  ];

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: _steps
            .map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: _StepTile(step: s.n, title: s.title, subtitle: s.sub),
              ),
            )
            .toList(),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _steps
          .map(
            (s) => Expanded(
              child: _StepTile(step: s.n, title: s.title, subtitle: s.sub),
            ),
          )
          .toList(),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String step;
  final String title;
  final String subtitle;

  const _StepTile({
    required this.step,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.secondaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              step,
              style: TextStyle(
                color: AppColors.bgPrimaryDark,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.78),
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

class _PricingSection extends StatelessWidget {
  const _PricingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withOpacity(0.12),
            AppColors.secondaryDark.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.secondary.withOpacity(0.65), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.2),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Affordable Excellence',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => AppColors.secondaryGradient
                .createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            child: const Text(
              '₹9',
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
          Text(
            'per Quiz',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withOpacity(0.85),
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _PrimaryCtaButton(
            label: 'Start for ₹9',
            onPressed: () => _navigateToQuiz(context),
          ),
        ],
      ),
    );
  }
}

class _LiveLeaderboardSection extends StatefulWidget {
  const _LiveLeaderboardSection({super.key});

  @override
  State<_LiveLeaderboardSection> createState() => _LiveLeaderboardSectionState();
}

class _LiveLeaderboardSectionState extends State<_LiveLeaderboardSection> {
  final QuizResultService _quizResultService = Get.find<QuizResultService>();
  List<LeaderboardEntry> _entries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _quizResultService.getLeaderboardByMarks(limit: 50);
      if (!mounted) return;
      final withMarks = list.where((e) => e.totalMarks > 0).take(5).toList();
      setState(() {
        _entries = withMarks;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  static Color? _rankColor(int rank) {
    switch (rank) {
      case 1:
        return AppColors.secondary;
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return null;
    }
  }

  static String _rankLabel(int rank) {
    switch (rank) {
      case 1:
        return '🥇 1';
      case 2:
        return '🥈 2';
      case 3:
        return '🥉 3';
      default:
        return '$rank';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: widget.key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => AppColors.secondaryGradient
              .createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          child: Text(
            'Live Rankings',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.secondary.withOpacity(0.22)),
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildBody(context),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.secondary,
            strokeWidth: 2.5,
          ),
        ),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Text(
              'Could not load rankings.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.88)),
            ),
            TextButton(
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'No rankings yet. Take a quiz to appear here!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.85)),
        ),
      );
    }

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.1),
        1: FlexColumnWidth(1.4),
        2: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.18),
          ),
          children: ['Rank', 'Name', 'Points']
              .map(
                (h) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    h,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        ..._entries.map(
          (e) {
            final rc = _rankColor(e.rank);
            return TableRow(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _rankLabel(e.rank),
                    style: TextStyle(
                      color: rc ?? Colors.white.withOpacity(0.92),
                      fontWeight: rc != null ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    e.userName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '${e.totalMarks}',
                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CtaBanner extends StatelessWidget {
  const _CtaBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.secondary.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          Text(
            'Join Today\'s Quiz at 9:00 PM',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Don\'t miss your chance to practice and rank higher!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.85),
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              _PrimaryCtaButton(
                label: 'Start Quiz',
                onPressed: () => _navigateToQuiz(context),
              ),
              _SecondaryCtaButton(
                label: 'Join Now',
                onPressed: () => _navigateToQuiz(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LandingFooter extends StatelessWidget {
  const _LandingFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: [
            Text(
              'rankx.online',
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w600),
            ),
            _footerLink(context, 'Privacy', AppRoutes.publicPrivacy),
            _footerLink(context, 'Terms', AppRoutes.publicTerms),
            _footerLink(context, 'Contact', AppRoutes.publicContact),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '© 2026 RankX. All rights reserved.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.55),
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.smartphone_rounded, color: AppColors.secondary.withOpacity(0.85)),
            const SizedBox(width: 16),
            Icon(Icons.email_outlined, color: AppColors.secondary.withOpacity(0.85)),
            const SizedBox(width: 16),
            Icon(Icons.tag_rounded, color: AppColors.secondary.withOpacity(0.85)),
          ],
        ),
      ],
    );
  }

  Widget _footerLink(BuildContext context, String label, String route) {
    return InkWell(
      onTap: () => context.go(route),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.88),
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.secondary.withOpacity(0.5),
        ),
      ),
    );
  }
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

class _NavItem {
  final String label;
  final String route;

  const _NavItem({required this.label, required this.route});
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
