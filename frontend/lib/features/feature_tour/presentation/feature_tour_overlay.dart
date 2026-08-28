import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

enum CoachMarkAdvanceType {
  nextButton,
  targetTap,
  swipeUp,
  navigationResult,
}

class FeatureTourStep {
  const FeatureTourStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.fallbackTargetKey,
    this.spotlightTargetKey,
    this.interactionTargetKey,
    this.advanceType = CoachMarkAdvanceType.nextButton,
    this.interactionHint,
  });

  final GlobalKey targetKey;
  final GlobalKey? fallbackTargetKey;
  final GlobalKey? spotlightTargetKey;
  final GlobalKey? interactionTargetKey;
  final String title;
  final String description;
  final CoachMarkAdvanceType advanceType;
  final String? interactionHint;
}

class FeatureTourOverlay extends StatefulWidget {
  const FeatureTourOverlay({
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.onNext,
    required this.onSkip,
    required this.onTargetUnavailable,
    super.key,
  });

  final FeatureTourStep step;
  final int stepIndex;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onTargetUnavailable;

  @override
  State<FeatureTourOverlay> createState() => _FeatureTourOverlayState();
}

class _FeatureTourOverlayState extends State<FeatureTourOverlay> {
  static const _maxTargetRetries = 10;

  Rect? _targetRect;
  Timer? _targetRefreshTimer;
  int _targetRetryCount = 0;
  bool _isPreparingTarget = false;
  bool _unavailableReported = false;

  @override
  void initState() {
    super.initState();
    _scheduleTargetRefresh();
    _targetRefreshTimer = Timer.periodic(
      const Duration(milliseconds: 120),
      (_) => _refreshTargetRect(),
    );
  }

  @override
  void didUpdateWidget(covariant FeatureTourOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.targetKey != widget.step.targetKey ||
        oldWidget.step.fallbackTargetKey != widget.step.fallbackTargetKey ||
        oldWidget.step.spotlightTargetKey != widget.step.spotlightTargetKey ||
        oldWidget.step.interactionTargetKey !=
            widget.step.interactionTargetKey) {
      _targetRect = null;
      _targetRetryCount = 0;
      _isPreparingTarget = false;
      _unavailableReported = false;
      _scheduleTargetRefresh();
    }
  }

  @override
  void dispose() {
    _targetRefreshTimer?.cancel();
    super.dispose();
  }

  void _scheduleTargetRefresh() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshTargetRect();
      }
    });
  }

  void _refreshTargetRect() {
    if (!mounted || _isPreparingTarget) {
      return;
    }

    final resolved = _resolveTarget();
    if (resolved == null) {
      _targetRect = null;
      _targetRetryCount += 1;
      if (_targetRetryCount >= _maxTargetRetries && !_unavailableReported) {
        _unavailableReported = true;
        widget.onTargetUnavailable();
      }
      setState(() {});
      return;
    }

    _targetRetryCount = 0;
    final rect = _toOverlayRect(resolved.rect);
    if (_shouldScrollToTarget(rect)) {
      unawaited(_prepareTarget(resolved.key));
      return;
    }
    if (rect == _targetRect) {
      return;
    }
    setState(() {
      _targetRect = rect;
    });
  }

  _ResolvedTarget? _resolveTarget() {
    final keys = <GlobalKey>[
      if (widget.step.spotlightTargetKey != null)
        widget.step.spotlightTargetKey!,
      widget.step.targetKey,
      if (widget.step.fallbackTargetKey != null) widget.step.fallbackTargetKey!,
    ];
    for (final key in keys) {
      final rect = _readGlobalRect(key);
      if (rect != null) {
        return _ResolvedTarget(key: key, rect: rect);
      }
    }
    return null;
  }

  Rect? _readGlobalRect(GlobalKey key) {
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.hasSize ||
        renderObject.size.isEmpty) {
      return null;
    }
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  Rect _toOverlayRect(Rect globalRect) {
    final overlayRenderObject = context.findRenderObject();
    if (overlayRenderObject is RenderBox) {
      final origin = overlayRenderObject.localToGlobal(Offset.zero);
      return globalRect.shift(-origin);
    }
    return globalRect;
  }

  bool _shouldScrollToTarget(Rect rect) {
    final size = MediaQuery.sizeOf(context);
    const edgeTolerance = 2.0;
    final safeViewport = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    );
    return rect.left < safeViewport.left - edgeTolerance ||
        rect.top < safeViewport.top - edgeTolerance ||
        rect.right > safeViewport.right + edgeTolerance ||
        rect.bottom > safeViewport.bottom + edgeTolerance;
  }

  Future<void> _prepareTarget(GlobalKey key) async {
    if (_isPreparingTarget || !mounted) {
      return;
    }
    final targetContext = key.currentContext;
    if (targetContext == null) {
      return;
    }
    setState(() {
      _isPreparingTarget = true;
      _targetRect = null;
    });
    try {
      await Scrollable.ensureVisible(
        targetContext,
        alignment: 0.34,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
      await Future<void>.delayed(const Duration(milliseconds: 160));
    } finally {
      if (mounted) {
        setState(() {
          _isPreparingTarget = false;
        });
        _scheduleTargetRefresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final target = _isPreparingTarget ? null : _targetRect;
          return Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _FeatureTourScrimPainter(targetRect: target),
                  ),
                ),
              ),
              ..._buildInteractionGuards(size, target),
              if (!_isPreparingTarget) _buildDescriptionCard(size, target),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildInteractionGuards(Size size, Rect? target) {
    if (widget.step.advanceType == CoachMarkAdvanceType.nextButton ||
        target == null) {
      return [
        const Positioned.fill(
          child: AbsorbPointer(),
        ),
      ];
    }

    final interactionRect = _readGlobalRect(
      widget.step.interactionTargetKey ?? widget.step.targetKey,
    );
    final interactionTarget =
        interactionRect == null ? target : _toOverlayRect(interactionRect);
    final hole = interactionTarget.inflate(10);
    return [
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        height: math.max(0, hole.top),
        child: const AbsorbPointer(),
      ),
      Positioned(
        left: 0,
        right: 0,
        top: hole.bottom,
        bottom: 0,
        child: const AbsorbPointer(),
      ),
      Positioned(
        left: 0,
        width: math.max(0, hole.left),
        top: hole.top,
        height: math.max(0, math.min(size.height, hole.bottom) - hole.top),
        child: const AbsorbPointer(),
      ),
      Positioned(
        left: hole.right,
        right: 0,
        top: hole.top,
        height: math.max(0, math.min(size.height, hole.bottom) - hole.top),
        child: const AbsorbPointer(),
      ),
    ];
  }

  Widget _buildDescriptionCard(Size size, Rect? target) {
    const horizontalInset = 16.0;
    final cardWidth = math.min(360.0, size.width - (horizontalInset * 2));
    final targetRect = target ??
        Rect.fromLTWH(size.width / 2 - 26, size.height / 2 - 26, 52, 52);
    final maxHeight = math.min(188.0, size.height - 28);
    final spaceBelow = size.height - targetRect.bottom;
    final showAbove = spaceBelow < maxHeight + 24;
    final top = showAbove
        ? math.max(16.0, targetRect.top - maxHeight - 22)
        : math.min(targetRect.bottom + 22, size.height - maxHeight - 16);
    final left = math.max(
      horizontalInset,
      math.min(
        targetRect.center.dx - (cardWidth / 2),
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
        maxHeight: maxHeight,
        onNext: widget.onNext,
        onSkip: widget.onSkip,
      ),
    );
  }
}

class _ResolvedTarget {
  const _ResolvedTarget({required this.key, required this.rect});

  final GlobalKey key;
  final Rect rect;
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
    final isInteractionStep =
        step.advanceType != CoachMarkAdvanceType.nextButton;
    final isLastStep = stepIndex == totalSteps - 1;
    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.34),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
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
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: onSkip,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          minimumSize: const Size(0, 28),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                        child: const Text('건너뛰기'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                      letterSpacing: 0,
                    ),
                  ),
                  if (isInteractionStep && step.interactionHint != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      step.interactionHint!,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                  if (!isInteractionStep) ...[
                    const SizedBox(height: 7),
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
                        label: Text(isLastStep ? '확인' : '다음'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
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
            targetRect!.inflate(10),
            const Radius.circular(18),
          );

    canvas.saveLayer(bounds, Paint());
    canvas.drawRect(
      bounds,
      Paint()..color = Colors.black.withValues(alpha: 0.62),
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
          ..color = AppColors.primary.withValues(alpha: 0.92)
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
