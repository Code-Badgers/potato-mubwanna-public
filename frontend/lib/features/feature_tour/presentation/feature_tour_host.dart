import 'dart:async';

import 'package:flutter/material.dart';

import '../data/feature_tour_status_store.dart';
import 'feature_tour_overlay.dart';

class FeatureTourController extends ChangeNotifier {
  FeatureTourController({
    required this.tourId,
    required this.steps,
    required this.onCompleted,
    required this.onStepChanged,
  });

  final String tourId;
  final List<FeatureTourStep> steps;
  final Future<void> Function() onCompleted;
  final Future<void> Function(int stepIndex) onStepChanged;

  int _stepIndex = 0;
  bool _isActive = false;
  bool _completionRequested = false;
  bool _hasPresentedStep = false;

  bool get isActive => _isActive;
  int get stepIndex => _stepIndex;
  FeatureTourStep get currentStep => steps[_stepIndex];

  void activate({int stepIndex = 0}) {
    if (_isActive || steps.isEmpty || _completionRequested) {
      return;
    }
    _stepIndex = stepIndex.clamp(0, steps.length - 1).toInt();
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
    if (_stepIndex >= steps.length - 1 && !_hasPresentedStep) {
      _isActive = false;
      notifyListeners();
      return;
    }
    _advance();
  }

  void markStepPresented() {
    if (!_isActive) {
      return;
    }
    _hasPresentedStep = true;
  }

  void _advance() {
    if (_stepIndex >= steps.length - 1) {
      _finish();
      return;
    }
    _stepIndex += 1;
    _hasPresentedStep = false;
    unawaited(onStepChanged(_stepIndex));
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
  bool _seenPersistRequested = false;

  FeatureTourController _createController() {
    return FeatureTourController(
      tourId: widget.tourId,
      steps: widget.steps,
      onCompleted: _persistCompletion,
      onStepChanged: _persistProgress,
    );
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadExposureState(_loadGeneration));
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
    _seenPersistRequested = false;
    setState(() {});
    unawaited(_loadExposureState(loadGeneration));
  }

  Future<void> _loadExposureState(int loadGeneration) async {
    final seenInCurrentProcess =
        widget.statusStore.wasSeenInCurrentProcess(widget.tourId);
    if (seenInCurrentProcess) {
      try {
        final completed = await widget.statusStore.hasCompleted(widget.tourId);
        if (!mounted || loadGeneration != _loadGeneration || completed) {
          return;
        }
      } catch (_) {
        return;
      }
    } else {
      try {
        final hasBeenSeen = await widget.statusStore.hasSeen(widget.tourId);
        if (!mounted || loadGeneration != _loadGeneration || hasBeenSeen) {
          return;
        }
      } catch (_) {
        return;
      }
    }
    int stepIndex;
    try {
      stepIndex = await widget.statusStore.readStepIndex(widget.tourId);
    } catch (_) {
      return;
    }
    if (!mounted || loadGeneration != _loadGeneration) {
      return;
    }
    // The host child is already mounted when the status read completes. The
    // overlay schedules its own post-frame target measurement, so activating
    // here also works when a route swaps to another page tour without a new
    // frame being requested afterward.
    _controller.activate(stepIndex: stepIndex);
  }

  void _handleStepPresented() {
    _controller.markStepPresented();
    unawaited(_persistProgress(_controller.stepIndex));
    if (_seenPersistRequested) {
      return;
    }
    _seenPersistRequested = true;
    unawaited(_persistSeen());
  }

  Future<void> _persistSeen() async {
    try {
      await widget.statusStore.markSeen(widget.tourId);
    } catch (_) {
      // 저장 실패 시 다음 표시 프레임에서 한 번 더 시도할 수 있게 한다.
      _seenPersistRequested = false;
    }
  }

  Future<void> _persistCompletion() async {
    try {
      await widget.statusStore.markCompleted(widget.tourId);
    } catch (_) {
      // Coach Mark 저장 실패가 앱 사용을 막지는 않는다.
    }
  }

  Future<void> _persistProgress(int stepIndex) async {
    try {
      await widget.statusStore.markStepIndex(widget.tourId, stepIndex);
    } catch (_) {
      // 진행 저장 실패가 현재 안내의 사용을 막지는 않는다.
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
                  onPresented: _handleStepPresented,
                  onTargetUnavailable: _controller.skipUnavailableStep,
                ),
            ],
          );
        },
      ),
    );
  }
}
