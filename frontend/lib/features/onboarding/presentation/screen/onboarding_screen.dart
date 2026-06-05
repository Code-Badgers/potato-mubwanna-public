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
      actionLabel: '다음',
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  _OnboardingHeader(
                    canSkip: _currentPage > 0,
                    onSkip: _skipToLogin,
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _steps.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return _OnboardingPage(step: _steps[index]);
                      },
                    ),
                  ),
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
          ),
        ),
      ),
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.canSkip,
    required this.onSkip,
  });

  final bool canSkip;
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
          if (canSkip)
            TextButton(
              onPressed: onSkip,
              child: const Text('나중에 하기'),
            ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.step});

  final _OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _OnboardingVisual(step: step),
                const SizedBox(height: 28),
                Text(
                  step.eyebrow,
                  style: TextStyle(
                    color: step.accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  step.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  step.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  step.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  step.helperText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                    letterSpacing: 0,
                  ),
                ),
              ],
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
    return AspectRatio(
      aspectRatio: 1.1,
      child: CustomPaint(
        painter: _LandscapePainter(accentColor: step.accentColor),
        child: Center(
          child: _StepIcon(type: step.type),
        ),
      ),
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
        return const Icon(
          Icons.location_on_rounded,
          size: 132,
          color: AppColors.primary,
        );
      case _OnboardingVisualType.notification:
        return const Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.notifications_rounded,
              size: 126,
              color: AppColors.secondary,
            ),
            Positioned(
              right: 44,
              top: 42,
              child: _SmallPotatoBadge(),
            ),
          ],
        );
    }
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

class _SmallPotatoBadge extends StatelessWidget {
  const _SmallPotatoBadge();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(46, 50),
      painter: _PotatoPainter(compact: true),
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

class _LandscapePainter extends CustomPainter {
  const _LandscapePainter({required this.accentColor});

  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE6F8FF),
          Color(0xFFFFF9EC),
        ],
      ).createShader(Offset.zero & size);

    final hillBack = Paint()..color = const Color(0xFFBFDDAE);
    final hillFront = Paint()..color = const Color(0xFF8DC56C);
    final field = Paint()..color = const Color(0xFFE6D986);
    final cloud = Paint()..color = Colors.white.withOpacity(0.9);
    final accent = Paint()..color = accentColor.withOpacity(0.22);

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(32),
    );
    canvas.drawRRect(rect, skyPaint);

    canvas.drawCircle(
        Offset(size.width * 0.82, size.height * 0.18), 26, accent);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.22, size.height * 0.22),
        width: 54,
        height: 22,
      ),
      cloud,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.30, size.height * 0.19),
        width: 38,
        height: 26,
      ),
      cloud,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.68, size.height * 0.29),
        width: 70,
        height: 24,
      ),
      cloud,
    );

    final backPath = Path()
      ..moveTo(0, size.height * 0.63)
      ..quadraticBezierTo(
        size.width * 0.26,
        size.height * 0.42,
        size.width * 0.50,
        size.height * 0.60,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.76,
        size.width,
        size.height * 0.50,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(backPath, hillBack);

    final frontPath = Path()
      ..moveTo(0, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.57,
        size.width * 0.68,
        size.height * 0.76,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.86,
        size.width,
        size.height * 0.70,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(frontPath, hillFront);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.22,
          size.height * 0.78,
          size.width * 0.56,
          size.height * 0.12,
        ),
        const Radius.circular(999),
      ),
      field,
    );
  }

  @override
  bool shouldRepaint(covariant _LandscapePainter oldDelegate) {
    return oldDelegate.accentColor != accentColor;
  }
}

class _PotatoPainter extends CustomPainter {
  const _PotatoPainter({this.compact = false});

  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = compact ? 0.95 : 1.0;
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
  bool shouldRepaint(covariant _PotatoPainter oldDelegate) {
    return oldDelegate.compact != compact;
  }
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
