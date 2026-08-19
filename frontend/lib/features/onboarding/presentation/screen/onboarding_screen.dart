import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/onboarding_status_store.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    this.onboardingStatusStore = const SharedPreferencesOnboardingStatusStore(),
    super.key,
  });

  final OnboardingStatusStore onboardingStatusStore;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _steps = [
    _IntroStep(
      imageAsset: 'assets/onboarding/service_intro_01.png',
      copyAsset: 'assets/onboarding/service_intro_copy_01.png',
    ),
    _IntroStep(
      imageAsset: 'assets/onboarding/service_intro_02.png',
      copyAsset: 'assets/onboarding/service_intro_copy_02.png',
    ),
    _IntroStep(
      imageAsset: 'assets/onboarding/service_intro_03.png',
      copyAsset: 'assets/onboarding/service_intro_copy_03.png',
    ),
    _IntroStep(
      imageAsset: 'assets/onboarding/service_intro_04.png',
      copyAsset: 'assets/onboarding/service_intro_copy_04.png',
    ),
  ];

  bool get _isLastPage => _currentPage == _steps.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handlePrimaryAction() async {
    if (!_isLastPage) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    try {
      await widget.onboardingStatusStore.markOnboardingCompleted();
    } catch (_) {
      // 설정 저장 실패가 사용자의 로그인 진행을 막지 않게 한다.
    }
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: _steps.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return _ServiceIntroPage(step: _steps[index]);
                  },
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 22,
                  child: _OnboardingControls(
                    currentPage: _currentPage,
                    pageCount: _steps.length,
                    isLastPage: _isLastPage,
                    buttonLabel: _isLastPage ? '카카오 로그인' : '다음',
                    onPressed: _handlePrimaryAction,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceIntroPage extends StatelessWidget {
  const _ServiceIntroPage({required this.step});

  final _IntroStep step;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: Stack(
        fit: StackFit.expand,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final contentHeight = constraints.maxHeight - 32 - 104 - 4;
              final copyHeight = contentHeight * 0.3;
              final constrainedCopyHeight =
                  copyHeight.clamp(128.0, 236.0).toDouble();
              final constrainedVisualHeight =
                  (contentHeight - constrainedCopyHeight)
                      .clamp(260.0, 500.0)
                      .toDouble();

              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 104),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: constrainedCopyHeight,
                      child: Align(
                        alignment: const Alignment(0.18, 0),
                        child: FractionallySizedBox(
                          widthFactor: 0.8,
                          heightFactor: 0.9,
                          child: Image.asset(
                            step.copyAsset,
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      height: constrainedVisualHeight,
                      child: _ShadowedIntroVisual(asset: step.imageAsset),
                    ),
                  ],
                ),
              );
            },
          ),
          const _BottomSurfaceFade(),
        ],
      ),
    );
  }
}

class _ShadowedIntroVisual extends StatelessWidget {
  const _ShadowedIntroVisual({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Positioned(
          bottom: 2,
          child: Container(
            width: 318,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.textPrimary.withValues(alpha: 0.14),
                  AppColors.textPrimary.withValues(alpha: 0.07),
                  AppColors.textPrimary.withValues(alpha: 0),
                ],
                stops: const [0, 0.42, 1],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.1),
                  blurRadius: 54,
                  spreadRadius: 14,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 28,
          child: Image.asset(
            asset,
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
          ),
        ),
      ],
    );
  }
}

class _BottomSurfaceFade extends StatelessWidget {
  const _BottomSurfaceFade();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 164,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x00FAFAF7),
                AppColors.surface,
              ],
              stops: [0, 0.72],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingControls extends StatelessWidget {
  const _OnboardingControls({
    required this.currentPage,
    required this.pageCount,
    required this.isLastPage,
    required this.buttonLabel,
    required this.onPressed,
  });

  final int currentPage;
  final int pageCount;
  final bool isLastPage;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PageIndicator(
          count: pageCount,
          currentIndex: currentPage,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor:
                  isLastPage ? const Color(0xFFFEE500) : AppColors.primary,
              foregroundColor:
                  isLastPage ? const Color(0xFF191919) : AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            child: Text(buttonLabel),
          ),
        ),
      ],
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: isActive ? 22 : 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary
                : AppColors.textSecondary.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _IntroStep {
  const _IntroStep({
    required this.imageAsset,
    required this.copyAsset,
  });

  final String imageAsset;
  final String copyAsset;
}
