import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../features/feature_tour/data/feature_tour_status_store.dart';
import '../../../features/feature_tour/presentation/feature_tour_overlay.dart';
import 'main_bottom_navigation.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    required this.child,
    this.featureTourStatusStore =
        const SharedPreferencesFeatureTourStatusStore(),
    super.key,
  });

  final Widget child;
  final FeatureTourStatusStore featureTourStatusStore;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int? _featureTourStepIndex;
  bool _openedFullMapForTour = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_maybeStartFeatureTour());
    });
  }

  Future<void> _maybeStartFeatureTour() async {
    bool hasCompleted;
    try {
      hasCompleted = await widget.featureTourStatusStore.hasCompleted(
        SharedPreferencesFeatureTourStatusStore.currentVersion,
      );
    } catch (_) {
      // 저장소를 사용할 수 없으면 기존 화면을 방해하지 않는다.
      return;
    }
    if (!mounted || hasCompleted) {
      return;
    }
    setState(() {
      _featureTourStepIndex = 0;
    });
  }

  Future<void> _completeFeatureTour() async {
    final stepIndex = _featureTourStepIndex;
    if (stepIndex == null) {
      return;
    }
    final shouldReturnToDiscovery = _openedFullMapForTour && stepIndex == 1;
    setState(() {
      _featureTourStepIndex = null;
    });

    if (shouldReturnToDiscovery && mounted) {
      context.go('/main/map');
    }

    try {
      await widget.featureTourStatusStore.markCompleted(
        SharedPreferencesFeatureTourStatusStore.currentVersion,
      );
    } catch (_) {
      // 투어 저장 실패가 앱 사용을 막지는 않도록 한다.
    }
  }

  void _advanceFeatureTour() {
    final stepIndex = _featureTourStepIndex;
    if (stepIndex == null) {
      return;
    }
    if (stepIndex >= FeatureTourOverlay.steps.length - 1) {
      unawaited(_completeFeatureTour());
      return;
    }

    setState(() {
      _featureTourStepIndex = stepIndex + 1;
    });

    switch (stepIndex) {
      case 0:
        _openedFullMapForTour = true;
        context.go('/main/map?featureTour=route');
      case 1:
        context.go('/main/stamps');
      case 2:
        context.go('/main/potatoes');
      case 3:
        context.go('/main/missions');
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepIndex = _featureTourStepIndex;
    return PopScope(
      canPop: stepIndex == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && stepIndex != null) {
          unawaited(_completeFeatureTour());
        }
      },
      child: Stack(
        children: [
          Scaffold(
            body: widget.child,
            bottomNavigationBar: const MainBottomNavigation(),
          ),
          if (stepIndex != null)
            FeatureTourOverlay(
              step: FeatureTourOverlay.steps[stepIndex],
              stepIndex: stepIndex,
              totalSteps: FeatureTourOverlay.steps.length,
              onNext: _advanceFeatureTour,
              onSkip: () => unawaited(_completeFeatureTour()),
            ),
        ],
      ),
    );
  }
}
