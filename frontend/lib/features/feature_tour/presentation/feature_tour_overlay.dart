import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import 'feature_tour_targets.dart';

class FeatureTourStep {
  const FeatureTourStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.fallbackTargetKey,
  });

  final GlobalKey targetKey;
  final GlobalKey? fallbackTargetKey;
  final String title;
  final String description;
}

class FeatureTourOverlay extends StatefulWidget {
  const FeatureTourOverlay({
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.onNext,
    required this.onSkip,
    super.key,
  });

  final FeatureTourStep step;
  final int stepIndex;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  static List<FeatureTourStep> get steps => [
        FeatureTourStep(
          targetKey: FeatureTourTargets.mapDiscovery,
          fallbackTargetKey: FeatureTourTargets.mapNavigation,
          title: '강원도에서 오늘 갈 곳을 찾아보세요',
          description: '추천 장소와 여행 코스를 한눈에 볼 수 있어요.',
        ),
        FeatureTourStep(
          targetKey: FeatureTourTargets.routeMode,
          fallbackTargetKey: FeatureTourTargets.mapNavigation,
          title: '가고 싶은 곳은 내 동선에 담아보세요',
          description: '담은 장소만 모아보고 여행 순서도 확인할 수 있어요.',
        ),
        FeatureTourStep(
          targetKey: FeatureTourTargets.stampNavigation,
          title: '직접 방문하고 스탬프를 모아요',
          description: '강원도 여행 패스포트를 하나씩 채워보세요.',
        ),
        FeatureTourStep(
          targetKey: FeatureTourTargets.potatoNavigation,
          title: '여행하며 나만의 감자를 키워보세요',
          description: '걷고 돌보며 성장시키면 감자 카드를 획득할 수 있어요.',
        ),
        FeatureTourStep(
          targetKey: FeatureTourTargets.missionNavigation,
          title: '점순이와 여행 미션도 즐겨보세요',
          description: '사진·QR·걷기 등 다양한 방식으로 여행을 기록할 수 있어요.',
        ),
      ];

  @override
  State<FeatureTourOverlay> createState() => _FeatureTourOverlayState();
}

class _FeatureTourOverlayState extends State<FeatureTourOverlay> {
  Rect? _targetRect;
  Timer? _targetRefreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTargetRect();
    _targetRefreshTimer = Timer.periodic(
      const Duration(milliseconds: 120),
      (_) => _refreshTargetRect(),
    );
  }

  @override
  void didUpdateWidget(covariant FeatureTourOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.targetKey != widget.step.targetKey ||
        oldWidget.step.fallbackTargetKey != widget.step.fallbackTargetKey) {
      _targetRect = null;
    }
    _refreshTargetRect();
  }

  @override
  void dispose() {
    _targetRefreshTimer?.cancel();
    super.dispose();
  }

  void _refreshTargetRect() {
    if (!mounted) {
      return;
    }
    final targetRect = _readRect(widget.step.targetKey) ??
        (widget.step.fallbackTargetKey == null
            ? null
            : _readRect(widget.step.fallbackTargetKey!));
    if (targetRect == _targetRect) {
      return;
    }
    setState(() {
      _targetRect = targetRect;
    });
  }

  Rect? _readRect(GlobalKey key) {
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.hasSize ||
        renderObject.size.isEmpty) {
      return null;
    }
    final origin = renderObject.localToGlobal(Offset.zero);
    return origin & renderObject.size;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: CustomPaint(
                    painter: _FeatureTourScrimPainter(targetRect: _targetRect),
                  ),
                ),
              ),
              _buildDescriptionCard(size),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDescriptionCard(Size size) {
    const horizontalInset = 16.0;
    final cardWidth = math.min(360.0, size.width - (horizontalInset * 2));
    final target = _targetRect ??
        Rect.fromLTWH(
          size.width / 2 - 26,
          size.height / 2 - 26,
          52,
          52,
        );
    final cardHeightEstimate = math.min(230.0, size.height - 32);
    final spaceBelow = size.height - target.bottom;
    final showAbove = spaceBelow < cardHeightEstimate + 24;
    final top = showAbove
        ? math.max(16.0, target.top - cardHeightEstimate - 22)
        : math.min(target.bottom + 22, size.height - cardHeightEstimate - 16);
    final left = math.max(
      horizontalInset,
      math.min(
        target.center.dx - (cardWidth / 2),
        size.width - cardWidth - horizontalInset,
      ),
    );

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      left: left,
      top: top,
      width: cardWidth,
      child: _FeatureTourCard(
        step: widget.step,
        stepIndex: widget.stepIndex,
        totalSteps: widget.totalSteps,
        maxHeight: math.min(250.0, size.height - 32),
        onNext: widget.onNext,
        onSkip: widget.onSkip,
      ),
    );
  }
}

class _FeatureTourCard extends StatelessWidget {
  const _FeatureTourCard({
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.maxHeight,
    required this.onNext,
    required this.onSkip,
  });

  final FeatureTourStep step;
  final int stepIndex;
  final int totalSteps;
  final double maxHeight;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final isLastStep = stepIndex == totalSteps - 1;
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        decoration: BoxDecoration(
          color: AppColors.textPrimary.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.66)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    '${stepIndex + 1} / $totalSteps',
                    style: TextStyle(
                      color: AppColors.primary.withValues(alpha: 0.98),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withValues(alpha: 0.74),
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    child: const Text('건너뛰기'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                step.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                step.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onNext,
                  icon: Icon(
                    isLastStep
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded,
                    size: 17,
                  ),
                  label: Text(isLastStep ? '시작하기' : '다음'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
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
}

class _FeatureTourScrimPainter extends CustomPainter {
  const _FeatureTourScrimPainter({required this.targetRect});

  final Rect? targetRect;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final hole = targetRect == null
        ? null
        : RRect.fromRectAndRadius(
            targetRect!.inflate(8),
            const Radius.circular(18),
          );

    canvas.saveLayer(bounds, Paint());
    canvas.drawRect(
      bounds,
      Paint()..color = Colors.black.withValues(alpha: 0.68),
    );
    if (hole != null) {
      canvas.drawRRect(
        hole,
        Paint()..blendMode = BlendMode.dstOut,
      );
    }
    canvas.restore();

    if (hole != null) {
      canvas.drawRRect(
        hole,
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FeatureTourScrimPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect;
  }
}
