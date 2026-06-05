import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';

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
      description: '관광지에 도착하면 위치로 스탬프를 받을 수 있어요.',
      helperText: '정확한 방문 인증을 위해 위치 정보 사용이 필요합니다.',
      actionLabel: '위치 권한 확인',
      accentColor: Color(0xFF38A36A),
      type: _OnboardingVisualType.location,
    ),
    _OnboardingStep(
      eyebrow: 'STEP 03',
      title: '알림을 허용해주세요',
      subtitle: '점순이 미션과 보상 알림',
      description: '미션, 쿠폰 지급, 이벤트 소식을 놓치지 않게 알려드려요.',
      helperText: '알림은 마이페이지에서 언제든 다시 설정할 수 있어요.',
      actionLabel: '시작하기',
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
      backgroundColor: AppColors.background,
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
                    left: 20,
                    right: 20,
                    top: 12,
                    child: _OnboardingHeader(
                      onSkip: _skipToLogin,
                    ),
                  ),
                if (_currentPage > 0)
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
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
                              backgroundColor: AppColors.primary,
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

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.onSkip,
  });

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '🥔',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onSkip,
            child: const Text('나중에 하기'),
          ),
        ],
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
            bottom: 28,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.88),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFE8E2D8)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.touch_app_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        step.actionLabel,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
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

class _PermissionOnboardingPage extends StatelessWidget {
  const _PermissionOnboardingPage({required this.step});

  final _OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 72, 20, 116),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: constraints.maxHeight - 188),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 30, 22, 26),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE8E2D8)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 26,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      step.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      step.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.6,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 34),
                    _OnboardingVisual(step: step),
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
                ),
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
      height: 178,
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
    return SizedBox(
      width: 210,
      height: 178,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            bottom: 4,
            child: CustomPaint(
              size: Size(188, 82),
              painter: _MapBasePainter(),
            ),
          ),
          Positioned(
            top: 0,
            child: Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.26),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on_rounded,
                size: 82,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationPermissionIllustration extends StatelessWidget {
  const _NotificationPermissionIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 142,
      height: 142,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D3),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFF0C35D), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF3B632).withOpacity(0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Icon(
        Icons.notifications_rounded,
        size: 82,
        color: AppColors.secondary,
      ),
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

    final dotPaint = Paint()..color = const Color(0xFFC58C43).withOpacity(0.65);
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

class _MapBasePainter extends CustomPainter {
  const _MapBasePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final basePath = Path()
      ..moveTo(size.width * 0.08, size.height * 0.28)
      ..quadraticBezierTo(size.width * 0.18, size.height * 0.04,
          size.width * 0.34, size.height * 0.08)
      ..lineTo(size.width * 0.92, size.height * 0.22)
      ..quadraticBezierTo(size.width * 1.02, size.height * 0.25,
          size.width * 0.95, size.height * 0.46)
      ..lineTo(size.width * 0.83, size.height * 0.84)
      ..quadraticBezierTo(size.width * 0.80, size.height * 0.96,
          size.width * 0.66, size.height * 0.92)
      ..lineTo(size.width * 0.10, size.height * 0.76)
      ..quadraticBezierTo(size.width * -0.02, size.height * 0.72,
          size.width * 0.04, size.height * 0.54)
      ..close();

    canvas.drawPath(basePath, Paint()..color = const Color(0xFFD8E97B));

    final waterPaint = Paint()
      ..color = const Color(0xFF8CCFD5)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12;
    final waterPath = Path()
      ..moveTo(size.width * 0.18, size.height * 0.63)
      ..cubicTo(size.width * 0.35, size.height * 0.36, size.width * 0.50,
          size.height * 0.78, size.width * 0.70, size.height * 0.43)
      ..quadraticBezierTo(size.width * 0.80, size.height * 0.28,
          size.width * 0.92, size.height * 0.34);
    canvas.drawPath(waterPath, waterPaint);

    final roadPaint = Paint()
      ..color = const Color(0xFFFFF3C8)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.38),
      Offset(size.width * 0.86, size.height * 0.78),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.78, size.height * 0.18),
      Offset(size.width * 0.26, size.height * 0.86),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MapBasePainter oldDelegate) => false;
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
