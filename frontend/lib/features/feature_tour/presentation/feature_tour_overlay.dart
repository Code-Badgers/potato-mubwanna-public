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

enum FeatureTourCardPlacement {
  target,
  aboveFooter,
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
    this.cardPlacement = FeatureTourCardPlacement.target,
  });

  final GlobalKey targetKey;
  final GlobalKey? fallbackTargetKey;
  final GlobalKey? spotlightTargetKey;
  final GlobalKey? interactionTargetKey;
  final String title;
  final String description;
  final CoachMarkAdvanceType advanceType;
  final String? interactionHint;
  final FeatureTourCardPlacement cardPlacement;
}

class FeatureTourOverlay extends StatefulWidget {
  const FeatureTourOverlay({
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.onNext,
    required this.onSkip,
    required this.onPresented,
    required this.onTargetUnavailable,
    super.key,
  });

  final FeatureTourStep step;
  final int stepIndex;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onPresented;
  final VoidCallback onTargetUnavailable;

  @override
  State<FeatureTourOverlay> createState() => _FeatureTourOverlayState();
}

class _FeatureTourOverlayState extends State<FeatureTourOverlay> {
  // Auth and API-backed screens can mount their targets after the first frame.
  // Keep waiting bounded, but give those screens enough time to settle.
  static const _maxTargetRetries = 120;
  static const _targetRetryDelay = Duration(milliseconds: 120);
  static const _targetStabilizationFrames = 2;

  Rect? _targetRect;
  Rect? _pendingTargetRect;
  Timer? _targetRefreshTimer;
  int _targetRetryCount = 0;
  int _stableFrameCount = 0;
  int _measurementGeneration = 0;
  bool _refreshScheduled = false;
  bool _isPreparingTarget = false;
  bool _unavailableReported = false;
  bool _presentationReported = false;
  final _preparedTargets = <GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _scheduleTargetRefresh();
  }

  @override
  void didUpdateWidget(covariant FeatureTourOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stepIndex != widget.stepIndex ||
        oldWidget.totalSteps != widget.totalSteps ||
        oldWidget.step.targetKey != widget.step.targetKey ||
        oldWidget.step.fallbackTargetKey != widget.step.fallbackTargetKey ||
        oldWidget.step.spotlightTargetKey != widget.step.spotlightTargetKey ||
        oldWidget.step.interactionTargetKey !=
            widget.step.interactionTargetKey ||
        oldWidget.step.cardPlacement != widget.step.cardPlacement) {
      _measurementGeneration += 1;
      _targetRefreshTimer?.cancel();
      _refreshScheduled = false;
      _targetRect = null;
      _pendingTargetRect = null;
      _targetRetryCount = 0;
      _stableFrameCount = 0;
      _isPreparingTarget = false;
      _unavailableReported = false;
      _presentationReported = false;
      _preparedTargets.clear();
      _scheduleTargetRefresh();
    }
  }

  @override
  void dispose() {
    _targetRefreshTimer?.cancel();
    super.dispose();
  }

  void _scheduleTargetRefresh() {
    if (_refreshScheduled || _isPreparingTarget) {
      return;
    }
    _refreshScheduled = true;
    final generation = _measurementGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _measurementGeneration) {
        return;
      }
      _refreshScheduled = false;
      if (mounted) {
        _refreshTargetRect();
      }
    });
  }

  void _scheduleRetry() {
    if (_refreshScheduled || _isPreparingTarget || !mounted) {
      return;
    }
    _refreshScheduled = true;
    _targetRefreshTimer?.cancel();
    _targetRefreshTimer = Timer(_targetRetryDelay, () {
      _refreshScheduled = false;
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
      _targetRetryCount += 1;
      if (_targetRetryCount >= _maxTargetRetries && !_unavailableReported) {
        _unavailableReported = true;
        widget.onTargetUnavailable();
        return;
      }
      _scheduleRetry();
      return;
    }

    _targetRetryCount = 0;
    final rect = _toOverlayRect(resolved.rect);
    if (!_preparedTargets.contains(resolved.key) &&
        _shouldScrollToTarget(rect, resolved.key)) {
      // Oversized targets cannot fit completely, even at the scroll limit.
      _preparedTargets.add(resolved.key);
      unawaited(_prepareTarget(resolved.key, _measurementGeneration));
      return;
    }

    if (rect != _pendingTargetRect) {
      setState(() {
        _pendingTargetRect = rect;
        _stableFrameCount = 1;
      });
      _scheduleTargetRefresh();
      return;
    }

    _stableFrameCount += 1;
    if (_stableFrameCount < _targetStabilizationFrames || rect == _targetRect) {
      _scheduleTargetRefresh();
      return;
    }

    setState(() {
      _targetRect = rect;
    });
    if (!_presentationReported) {
      _presentationReported = true;
      widget.onPresented();
    }
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
    if (!renderObject.attached) {
      return null;
    }
    final rect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    return rect.isFinite ? rect : null;
  }

  Rect _toOverlayRect(Rect globalRect) {
    final overlayRenderObject = context.findRenderObject();
    if (overlayRenderObject is RenderBox) {
      final origin = overlayRenderObject.localToGlobal(Offset.zero);
      return globalRect.shift(-origin);
    }
    return globalRect;
  }

  bool _shouldScrollToTarget(Rect rect, GlobalKey key) {
    final overlayRenderObject = context.findRenderObject();
    final size = overlayRenderObject is RenderBox && overlayRenderObject.hasSize
        ? overlayRenderObject.size
        : MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    const edgeTolerance = 8.0;
    final safeViewport = Rect.fromLTWH(
      0,
      padding.top + edgeTolerance,
      size.width,
      math.max(
        0,
        size.height - padding.top - padding.bottom - (edgeTolerance * 2),
      ),
    );
    final targetContext = key.currentContext;
    final scrollable =
        targetContext == null ? null : Scrollable.maybeOf(targetContext);
    final coversMostOfViewport = rect.width >= safeViewport.width * 0.78 &&
        rect.height >= safeViewport.height * 0.68;
    // 전체 지도처럼 화면을 채우는 비스크롤 타깃은 ensureVisible로
    // 이동할 수 없으므로, 현재 위치에서 바로 안내해야 한다.
    if (scrollable == null || coversMostOfViewport) {
      return false;
    }
    return rect.left < safeViewport.left - edgeTolerance ||
        rect.top < safeViewport.top - edgeTolerance ||
        rect.right > safeViewport.right + edgeTolerance ||
        rect.bottom > safeViewport.bottom + edgeTolerance;
  }

  Future<void> _prepareTarget(GlobalKey key, int generation) async {
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
      _pendingTargetRect = null;
      _stableFrameCount = 0;
    });
    try {
      await Scrollable.ensureVisible(
        targetContext,
        alignment: 0.34,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
      await Future<void>.delayed(const Duration(milliseconds: 120));
    } finally {
      if (mounted && generation == _measurementGeneration) {
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
          final target = _isPreparingTarget
              ? null
              : _targetRect?.intersect(Offset.zero & size);
          // API-backed pages can mount their target after this overlay. Keep
          // the page usable and visually unchanged until the target is ready,
          // then present the scrim and card together.
          if (target == null || target.isEmpty) {
            return const SizedBox.expand();
          }
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
              _buildDescriptionCard(size, target),
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
    final hole = interactionTarget.inflate(10).intersect(Offset.zero & size);
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
    final padding = MediaQuery.paddingOf(context);
    const safeInset = 8.0;
    final safeTop = padding.top + safeInset;
    final safeBottom = padding.bottom + safeInset;
    final availableHeight = math.max(0.0, size.height - safeTop - safeBottom);
    final maxHeight = math.min(188.0, availableHeight);
    if (widget.step.cardPlacement == FeatureTourCardPlacement.aboveFooter) {
      return Positioned(
        left: horizontalInset,
        width: cardWidth,
        bottom: safeBottom + 12,
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

    final targetRect = target ??
        Rect.fromLTWH(size.width / 2 - 26, size.height / 2 - 26, 52, 52);
    final spaceBelow = size.height - safeBottom - targetRect.bottom;
    final showAbove = spaceBelow < maxHeight + 24;
    final top = showAbove
        ? math.max(safeTop, targetRect.top - maxHeight - 22)
        : math.min(
            targetRect.bottom + 22,
            math.max(safeTop, size.height - safeBottom - maxHeight),
          );
    final left = math.max(
      horizontalInset,
      math.min(
        targetRect.center.dx - (cardWidth / 2),
        size.width - cardWidth - horizontalInset,
      ),
    );

    return Positioned(
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
