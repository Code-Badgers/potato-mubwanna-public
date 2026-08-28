import 'package:flutter/material.dart';

/// Coach Mark가 실제 화면의 위치를 따라가도록 공유하는 target registry다.
class FeatureTourTargets {
  const FeatureTourTargets._();

  static final mapDiscovery = GlobalKey(debugLabel: 'feature-tour-map');
  static final routeMode = GlobalKey(debugLabel: 'feature-tour-route');
  static final mapNavigation = GlobalKey(debugLabel: 'feature-tour-map-nav');
  static final stampNavigation =
      GlobalKey(debugLabel: 'feature-tour-stamp-nav');
  static final potatoNavigation =
      GlobalKey(debugLabel: 'feature-tour-potato-nav');
  static final missionNavigation =
      GlobalKey(debugLabel: 'feature-tour-mission-nav');
}
