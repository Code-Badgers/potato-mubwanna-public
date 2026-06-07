import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';

const _permissionButtonColor = Color(0xFF36D98F);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _steps = [
    _OnboardingStep(
      eyebrow: 'STEP 01',
      title: '감자무봤나?',
      subtitle: '강원도 감자여행',
      description: '스탬프를 모아보세요!',
      helperText: '지도에서 감자 스팟을 찾고 방문 인증으로 지역 감자를 수집해요.',
      actionLabel: '터치하여 시작하기',
      accentColor: Color(0xFF7DB84E),
      type: _OnboardingVisualType.potato,
    ),
    _OnboardingStep(
      eyebrow: 'STEP 02',
      title: '위치 권한이 필요해요',
      subtitle: 'GPS 기반 방문 인증',
      description: '관광지 방문 인증을 위해\n위치 정보 사용이 필요합니다.',
      helperText: '',
      actionLabel: '권한 허용하기',
      accentColor: Color(0xFF38A36A),
      type: _OnboardingVisualType.location,
    ),
    _OnboardingStep(
      eyebrow: 'STEP 03',
      title: '알림을 허용해주세요',
      subtitle: '점순이 미션과 보상 알림',
      description: '점순이 미션, 쿠폰 지급,\n이벤트 알림을 받을 수 있어요.',
      helperText: '',
      actionLabel: '권한 허용하기',
      accentColor: Color(0xFFF3B632),
      type: _OnboardingVisualType.notification,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handlePrimaryAction() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    context.go('/login');
  }

  void _skipToLogin() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentPage];

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
                    if (index == 0) {
                      return _OnboardingHeroPage(
                        step: _steps[index],
                        onTap: _handlePrimaryAction,
                      );
                    }

                    return _PermissionOnboardingPage(step: _steps[index]);
                  },
                ),
                if (_currentPage > 0)
                  Positioned(
                    left: 28,
                    right: 28,
                    bottom: 22,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PageIndicator(
                          count: _steps.length,
                          currentIndex: _currentPage,
                          activeColor: step.accentColor,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: _handlePrimaryAction,
                            style: FilledButton.styleFrom(
                              backgroundColor: _permissionButtonColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            child: Text(step.actionLabel),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextButton(
                          onPressed: _skipToLogin,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('나중에 하기'),
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

class _OnboardingHeroPage extends StatelessWidget {
  const _OnboardingHeroPage({
    required this.step,
    required this.onTap,
  });

  final _OnboardingStep step;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/onboading.png',
            fit: BoxFit.cover,
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 36,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _BlinkingStartText(
                  label: step.actionLabel,
                ),
              ],
            ),
          ),
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

class _PermissionOnboardingPage extends StatelessWidget {
  const _PermissionOnboardingPage({required this.step});

  final _OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(28, 50, 28, 156),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: constraints.maxHeight - 206),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    step.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    step.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.55,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 46),
                  _OnboardingVisual(step: step),
                  if (step.helperText.isNotEmpty) ...[
                    const SizedBox(height: 34),
                    Text(
                      step.helperText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingVisual extends StatelessWidget {
  const _OnboardingVisual({required this.step});

  final _OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 212,
      child: Center(child: _StepIcon(type: step.type)),
    );
  }
}

class _StepIcon extends StatelessWidget {
  const _StepIcon({required this.type});

  final _OnboardingVisualType type;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case _OnboardingVisualType.potato:
        return const _PotatoCharacter();
      case _OnboardingVisualType.location:
        return const _LocationPermissionIllustration();
      case _OnboardingVisualType.notification:
        return const _NotificationPermissionIllustration();
    }
  }
}

class _LocationPermissionIllustration extends StatelessWidget {
  const _LocationPermissionIllustration();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/onboading_02.png',
      width: 246,
      height: 220,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

class _NotificationPermissionIllustration extends StatelessWidget {
  const _NotificationPermissionIllustration();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/onboading_03.png',
      width: 220,
      height: 220,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

class _PotatoCharacter extends StatelessWidget {
  const _PotatoCharacter();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(150, 170),
      painter: _PotatoPainter(),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.count,
    required this.currentIndex,
    required this.activeColor,
  });

  final int count;
  final int currentIndex;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: isActive ? 26 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? activeColor : const Color(0xFFD8D1C4),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

class _PotatoPainter extends CustomPainter {
  const _PotatoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const scale = 1.0;
    final bodyPaint = Paint()..color = const Color(0xFFE1B15E);
    final shadowPaint = Paint()..color = const Color(0xFFB77A32);
    final cheekPaint = Paint()..color = const Color(0xFFFF9E81);
    final facePaint = Paint()
      ..color = const Color(0xFF3D2B1A)
      ..strokeWidth = 4 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final leafPaint = Paint()..color = const Color(0xFF69A843);

    final center = Offset(size.width / 2, size.height * 0.58);
    final bodyRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.72,
      height: size.height * 0.68,
    );

    canvas.drawOval(bodyRect.shift(const Offset(0, 5)), shadowPaint);
    canvas.drawOval(bodyRect, bodyPaint);

    final leafStem = Paint()
      ..color = const Color(0xFF4E7F2D)
      ..strokeWidth = 5 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.50, size.height * 0.23),
      Offset(size.width * 0.50, size.height * 0.12),
      leafStem,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.42, size.height * 0.13),
        width: size.width * 0.18,
        height: size.height * 0.10,
      ),
      leafPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.58, size.height * 0.13),
        width: size.width * 0.18,
        height: size.height * 0.10,
      ),
      leafPaint,
    );

    final eyeY = size.height * 0.54;
    canvas.drawCircle(Offset(size.width * 0.39, eyeY), 4 * scale,
        Paint()..color = const Color(0xFF2E2114));
    canvas.drawCircle(Offset(size.width * 0.61, eyeY), 4 * scale,
        Paint()..color = const Color(0xFF2E2114));
    canvas.drawCircle(
        Offset(size.width * 0.33, size.height * 0.62), 7 * scale, cheekPaint);
    canvas.drawCircle(
        Offset(size.width * 0.67, size.height * 0.62), 7 * scale, cheekPaint);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.50, size.height * 0.61),
        width: size.width * 0.18,
        height: size.height * 0.12,
      ),
      0.15,
      2.8,
      false,
      facePaint,
    );

    final dotPaint = Paint()
      ..color = const Color(0xFFC58C43).withValues(alpha: 0.65);
    canvas.drawCircle(
        Offset(size.width * 0.34, size.height * 0.42), 3 * scale, dotPaint);
    canvas.drawCircle(
        Offset(size.width * 0.69, size.height * 0.47), 2.5 * scale, dotPaint);
    canvas.drawCircle(
        Offset(size.width * 0.48, size.height * 0.76), 2.5 * scale, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _PotatoPainter oldDelegate) => false;
}

class _OnboardingStep {
  const _OnboardingStep({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.helperText,
    required this.actionLabel,
    required this.accentColor,
    required this.type,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String description;
  final String helperText;
  final String actionLabel;
  final Color accentColor;
  final _OnboardingVisualType type;
}

enum _OnboardingVisualType {
  potato,
  location,
  notification,
}
