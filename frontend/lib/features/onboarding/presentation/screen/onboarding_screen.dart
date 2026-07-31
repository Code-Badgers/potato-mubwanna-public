import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/onboarding_status_store.dart';

const _primaryButtonColor = Color(0xFF56C787);

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
      title: '감자무봤나?',
      description: '강원도 감자여행\n스탬프를 모아보세요!',
      imageAsset: 'assets/onboading.png',
    ),
    _IntroStep(
      title: '지도로 감자 스팟 찾기',
      description: '가까운 관광지, 카페, 체험 장소를\n감자 핀으로 빠르게 확인해요.',
      icon: Icons.map_outlined,
    ),
    _IntroStep(
      title: '수집하고 보상받기',
      description: '스탬프, 감자 캐릭터, 점순이 미션을\n짧은 루프로 즐겨요.',
      icon: Icons.emoji_events_outlined,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handlePrimaryAction() async {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
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
                    final item = _steps[index];
                    if (item.imageAsset != null) {
                      return _ImageIntroPage(
                        step: item,
                        onTap: _handlePrimaryAction,
                      );
                    }

                    return _TextIntroPage(step: item);
                  },
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 22,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PageIndicator(
                        count: _steps.length,
                        currentIndex: _currentPage,
                      ),
                      const SizedBox(height: 18),
                      if (_currentPage == 0)
                        const _BlinkingStartText(label: '터치하여 시작하기')
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: FilledButton(
                            onPressed: _handlePrimaryAction,
                            style: FilledButton.styleFrom(
                              backgroundColor: _primaryButtonColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                            child: Text(
                              _currentPage == _steps.length - 1
                                  ? '카카오 로그인하러 가기'
                                  : '다음',
                            ),
                          ),
                        ),
                    ],
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

class _ImageIntroPage extends StatelessWidget {
  const _ImageIntroPage({
    required this.step,
    required this.onTap,
  });

  final _IntroStep step;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Image.asset(
        step.imageAsset!,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _TextIntroPage extends StatelessWidget {
  const _TextIntroPage({required this.step});

  final _IntroStep step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 72, 28, 126),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: _primaryButtonColor.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(
              step.icon,
              color: _primaryButtonColor,
              size: 44,
            ),
          ),
          const Spacer(),
          Text(
            step.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 31,
              fontWeight: FontWeight.w900,
              height: 1.22,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            step.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.45,
              letterSpacing: 0,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _BlinkingStartText extends StatefulWidget {
  const _BlinkingStartText({required this.label});

  final String label;

  @override
  State<_BlinkingStartText> createState() => _BlinkingStartTextState();
}

class _BlinkingStartTextState extends State<_BlinkingStartText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 820),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.34,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Text(
        widget.label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          shadows: [
            Shadow(
              color: Colors.white,
              blurRadius: 8,
            ),
          ],
        ),
      ),
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
                ? _primaryButtonColor
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
    required this.title,
    required this.description,
    this.imageAsset,
    this.icon,
  });

  final String title;
  final String description;
  final String? imageAsset;
  final IconData? icon;
}
