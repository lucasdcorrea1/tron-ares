import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/imperium_button.dart';

/// Onboarding page with 3 introduction screens
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (!mounted) return;
    context.go('/login');
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final pages = [
      _OnboardingPageData(
        icon: Icons.pie_chart_rounded,
        title: l10n.onboardingTitle1,
        description: l10n.onboardingDescription1,
      ),
      _OnboardingPageData(
        icon: Icons.touch_app_rounded,
        title: l10n.onboardingTitle2,
        description: l10n.onboardingDescription2,
      ),
      _OnboardingPageData(
        icon: Icons.flag_rounded,
        title: l10n.onboardingTitle3,
        description: l10n.onboardingDescription3,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    l10n.skip,
                    style: AppTypography.labelMedium(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _OnboardingContent(data: pages[index]);
                },
              ),
            ),

            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (index) => _PageIndicator(isActive: index == _currentPage),
                ),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ImperiumButton(
                label: _currentPage < 2 ? l10n.next : l10n.getStarted,
                onPressed: _nextPage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;

  _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _OnboardingContent extends StatelessWidget {
  final _OnboardingPageData data;

  const _OnboardingContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.imperiumGold.withOpacity(0.2),
                  AppColors.imperiumDarkGold.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(70),
            ),
            child: Icon(
              data.icon,
              size: 70,
              color: AppColors.imperiumGold,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Title
          Text(
            data.title,
            style: AppTypography.headlineMedium(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),

          // Description
          Text(
            data.description,
            style: AppTypography.bodyMedium(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final bool isActive;

  const _PageIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.imperiumGold : AppColors.textMuted,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
