import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_design_tokens.dart';
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
      title: '감자를 따라 강원으로',
      description: '지도 위 감자 스팟을 따라 숨은 명소를 찾아보세요',
      imageAsset: 'assets/onboarding/service_intro_01.png',
    ),
    _IntroStep(
      title: '여행 도장을 모아요',
      description: '명소에 도착하면 방문 인증으로 스탬프가 채워져요',
      imageAsset: 'assets/onboarding/service_intro_02.png',
    ),
    _IntroStep(
      title: '감자를 키워요',
      description: '걸음과 미션으로 나만의 감자 도감을 완성해보세요',
      imageAsset: 'assets/onboarding/service_intro_03.png',
    ),
    _IntroStep(
      title: '점순이가 골라둔 미션',
      description: '사진, 퀴즈, 산책 미션으로 여행 기록을 남겨보세요',
      imageAsset: 'assets/onboarding/service_intro_04.png',
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
                    buttonLabel: _isLastPage ? '카카오 로그인하러 가기' : '다음',
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
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          step.imageAsset,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.surface.withValues(alpha: 0),
                AppColors.surface.withValues(alpha: 0),
                AppColors.surface.withValues(alpha: 0.9),
              ],
              stops: const [0, 0.58, 1],
            ),
          ),
        ),
        Positioned(
          left: 26,
          right: 26,
          bottom: 116,
          child: _IntroCopy(step: step),
        ),
      ],
    );
  }
}

class _IntroCopy extends StatelessWidget {
  const _IntroCopy({required this.step});

  final _IntroStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        boxShadow: AppShadows.softCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            step.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              height: 1.2,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            step.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.38,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingControls extends StatelessWidget {
  const _OnboardingControls({
    required this.currentPage,
    required this.pageCount,
    required this.buttonLabel,
    required this.onPressed,
  });

  final int currentPage;
  final int pageCount;
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
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
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
            borderRadius: BorderRadius.circular(AppDimens.pillRadius),
          ),
        );
      }),
    );
  }
}

class _IntroStep {
  const _IntroStep({
    required this.title,
    required this.description,
    required this.imageAsset,
  });

  final String title;
  final String description;
  final String imageAsset;
}
