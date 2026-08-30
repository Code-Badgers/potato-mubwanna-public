import 'dart:async';

import 'package:flutter/material.dart';

import '../data/feature_tour_status_store.dart';
import 'feature_tour_overlay.dart';

class FeatureTourController extends ChangeNotifier {
  FeatureTourController({
    required this.tourId,
    required this.steps,
    required this.onCompleted,
  });

  final String tourId;
  final List<FeatureTourStep> steps;
  final Future<void> Function() onCompleted;

  int _stepIndex = 0;
  bool _isActive = false;
  bool _completionRequested = false;

  bool get isActive => _isActive;
  int get stepIndex => _stepIndex;
  FeatureTourStep get currentStep => steps[_stepIndex];

  void activate() {
    if (_isActive || steps.isEmpty || _completionRequested) {
      return;
    }
    _isActive = true;
    notifyListeners();
  }

  void next() {
    if (!_isActive ||
        currentStep.advanceType != CoachMarkAdvanceType.nextButton) {
      return;
    }
    _advance();
  }

  void completeTarget(GlobalKey targetKey) {
    if (!_isActive ||
        currentStep.advanceType != CoachMarkAdvanceType.targetTap) {
      return;
    }
    if (currentStep.targetKey != targetKey &&
        currentStep.fallbackTargetKey != targetKey) {
      return;
    }
    _advance();
  }

  void completeSwipe(GlobalKey targetKey) {
    if (!_isActive || currentStep.advanceType != CoachMarkAdvanceType.swipeUp) {
      return;
    }
    if (currentStep.targetKey != targetKey &&
        currentStep.fallbackTargetKey != targetKey) {
      return;
    }
    _advance();
  }

  void completeNavigation() {
    if (!_isActive ||
        currentStep.advanceType != CoachMarkAdvanceType.navigationResult) {
      return;
    }
    _advance();
  }

  void skipTour() {
    if (!_isActive) {
      return;
    }
    _finish();
  }

  void skipUnavailableStep() {
    if (!_isActive) {
      return;
    }
    _advance();
  }

  void _advance() {
    if (_stepIndex >= steps.length - 1) {
      _finish();
      return;
    }
    _stepIndex += 1;
    notifyListeners();
  }

  void _finish() {
    if (_completionRequested) {
      return;
    }
    _completionRequested = true;
    _isActive = false;
    notifyListeners();
    unawaited(onCompleted());
  }
}

class FeatureTourScope extends InheritedNotifier<FeatureTourController> {
  const FeatureTourScope({
    required FeatureTourController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static FeatureTourController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FeatureTourScope>()
        ?.notifier;
  }
}

class FeatureTourHost extends StatefulWidget {
  const FeatureTourHost({
    required this.tourId,
    required this.steps,
    required this.child,
    this.statusStore = const SharedPreferencesFeatureTourStatusStore(),
    super.key,
  });

  final String tourId;
  final List<FeatureTourStep> steps;
  final Widget child;
  final FeatureTourStatusStore statusStore;

  @override
  State<FeatureTourHost> createState() => _FeatureTourHostState();
}

class _FeatureTourHostState extends State<FeatureTourHost> {
  late FeatureTourController _controller = _createController();
  int _loadGeneration = 0;

  FeatureTourController _createController() {
    return FeatureTourController(
      tourId: widget.tourId,
      steps: widget.steps,
      onCompleted: _persistCompletion,
    );
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadCompletionState(_loadGeneration));
  }

  @override
  void dispose() {
    _loadGeneration += 1;
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FeatureTourHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Tour IDs version the step contract. Keeping the controller for the same
    // ID prevents route/data rebuilds from restarting an active tour.
    if (oldWidget.tourId == widget.tourId &&
        oldWidget.statusStore == widget.statusStore) {
      return;
    }
    final loadGeneration = ++_loadGeneration;
    _controller.dispose();
    _controller = _createController();
    setState(() {});
    unawaited(_loadCompletionState(loadGeneration));
  }

  Future<void> _loadCompletionState(int loadGeneration) async {
    bool seen;
    try {
      seen = await widget.statusStore.hasSeen(widget.tourId);
    } catch (_) {
      return;
    }
    if (!mounted || loadGeneration != _loadGeneration || seen) {
      return;
    }
    // Mark the page tour as seen before activation. If the user leaves a page
    // midway, returning to it should not restart the same tour endlessly.
    try {
      await widget.statusStore.markSeen(widget.tourId);
    } catch (_) {
      // A local preference failure must not block the page itself.
    }
    if (!mounted || loadGeneration != _loadGeneration) {
      return;
    }
    // The host child is already mounted when the status read completes. The
    // overlay schedules its own post-frame target measurement, so activating
    // here also works when a route swaps to another page tour without a new
    // frame being requested afterward.
    _controller.activate();
  }

  Future<void> _persistCompletion() async {
    try {
      await widget.statusStore.markCompleted(widget.tourId);
    } catch (_) {
      // Coach Mark 저장 실패가 앱 사용을 막지는 않는다.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeatureTourScope(
      controller: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          return Stack(
            children: [
              child!,
              if (_controller.isActive)
                FeatureTourOverlay(
                  step: _controller.currentStep,
                  stepIndex: _controller.stepIndex,
                  totalSteps: _controller.steps.length,
                  onNext: _controller.next,
                  onSkip: _controller.skipTour,
                  onTargetUnavailable: _controller.skipUnavailableStep,
                ),
            ],
          );
        },
      ),
    );
  }
}
