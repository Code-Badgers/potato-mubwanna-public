import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../auth/application/auth_controller.dart';
import '../../data/onboarding_status_store.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({
    this.onboardingStatusStore = const SharedPreferencesOnboardingStatusStore(),
    this.initialPage = 0,
    super.key,
  });

  final OnboardingStatusStore onboardingStatusStore;
  final int initialPage;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  late int _currentPage;
  bool _isSubmitting = false;

  static const _steps = [
    _IntroStep(
      imageAsset: 'assets/onboarding/service_intro_01.png',
      copyAsset: 'assets/onboarding/service_intro_copy_01.png',
      description: '강원도 여행을 더 특별하게. 지도에서 여행지를 찾고 감자 친구와 함께 여행을 시작해보세요.',
    ),
    _IntroStep(
      imageAsset: 'assets/onboarding/service_intro_02.png',
      copyAsset: 'assets/onboarding/service_intro_copy_02.png',
      description: '방문하고 스탬프를 차곡차곡 모아요. 강원도 곳곳을 방문하고 나만의 여행 패스포트를 채워보세요.',
    ),
    _IntroStep(
      imageAsset: 'assets/onboarding/service_intro_03.png',
      copyAsset: 'assets/onboarding/service_intro_copy_03.png',
      description: '여행할수록 감자가 쑥쑥 자라요. 함께 걷고 돌보며 새로운 감자 친구들을 만나보세요.',
    ),
    _IntroStep(
      imageAsset: 'assets/onboarding/service_intro_04.png',
      copyAsset: 'assets/onboarding/service_intro_copy_04.png',
      description: '점순이와 미션을 하고 추억을 남겨요. 사진 인증과 여행 기록으로 오늘의 강원도 여행을 오래 기억해보세요.',
    ),
  ];

  bool get _isLastPage => _currentPage == _steps.length - 1;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handlePrimaryAction() async {
    if (_isSubmitting) {
      return;
    }
    if (!_isLastPage) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onboardingStatusStore.markOnboardingCompleted();
    } catch (_) {
      // 설정 저장 실패가 사용자의 로그인 진행을 막지 않게 한다.
    }
    if (!mounted) {
      return;
    }
    final loggedIn =
        await ref.read(authControllerProvider.notifier).loginWithKakao();
    if (loggedIn && mounted) {
      context.go('/permissions');
    }
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = _isSubmitting || authState.status == AuthStatus.loading;

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
                    isLoading: _isLastPage && isLoading,
                    errorMessage:
                        _isLastPage && authState.status == AuthStatus.failure
                            ? authState.message
                            : null,
                    onPressed: isLoading ? null : _handlePrimaryAction,
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
                          child: Semantics(
                            label: step.description,
                            child: Image.asset(
                              step.copyAsset,
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                              excludeFromSemantics: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      height: constrainedVisualHeight,
                      child: _IntroVisual(asset: step.imageAsset),
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

class _IntroVisual extends StatelessWidget {
  const _IntroVisual({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        excludeFromSemantics: true,
      ),
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
    required this.isLoading,
    required this.errorMessage,
    required this.onPressed,
  });

  final int currentPage;
  final int pageCount;
  final bool isLastPage;
  final String buttonLabel;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PageIndicator(
          count: pageCount,
          currentIndex: currentPage,
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error, fontSize: 14),
            ),
          ),
        ],
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints:
              const BoxConstraints(minWidth: double.infinity, minHeight: 56),
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor:
                  isLastPage ? const Color(0xFFFEE500) : AppColors.primary,
              foregroundColor:
                  isLastPage ? const Color(0xFF191919) : AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            child: isLoading
                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const ExcludeSemantics(
                        child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Color(0xFF191919)),
                    )),
                    const SizedBox(width: 10),
                    Flexible(
                        child: Semantics(
                            liveRegion: true,
                            child: const Text('로그인 중',
                                textAlign: TextAlign.center))),
                  ])
                : Text(buttonLabel),
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
    return Semantics(
      label: '${currentIndex + 1}/$count 페이지',
      child: Row(
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
      ),
    );
  }
}

class _IntroStep {
  const _IntroStep({
    required this.imageAsset,
    required this.copyAsset,
    required this.description,
  });

  final String imageAsset;
  final String copyAsset;
  final String description;
}
