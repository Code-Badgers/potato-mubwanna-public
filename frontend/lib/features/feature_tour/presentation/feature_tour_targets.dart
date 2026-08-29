import 'package:flutter/material.dart';

/// Coach Mark가 실제 화면의 위치를 따라가도록 공유하는 target registry다.
class FeatureTourTargets {
  const FeatureTourTargets._();

  static final mapDiscovery = GlobalKey(debugLabel: 'feature-tour-map');
  static final mapCourseCard =
      GlobalKey(debugLabel: 'feature-tour-map-course-card');
  static final mapGoodNowCard =
      GlobalKey(debugLabel: 'feature-tour-map-good-now-card');
  static final mapFullView =
      GlobalKey(debugLabel: 'feature-tour-map-full-view');
  static final mapMarker = GlobalKey(debugLabel: 'feature-tour-map-marker');
  static final mapSelectedSpotCard =
      GlobalKey(debugLabel: 'feature-tour-map-selected-spot-card');
  static final spotSheetHandle =
      GlobalKey(debugLabel: 'feature-tour-spot-sheet-handle');
  static final routeMode = GlobalKey(debugLabel: 'feature-tour-route');
  static final mapNavigation = GlobalKey(debugLabel: 'feature-tour-map-nav');
  static final stampMap = GlobalKey(debugLabel: 'feature-tour-stamp-map');
  static final stampMarker = GlobalKey(debugLabel: 'feature-tour-stamp-marker');
  static final stampVisit = GlobalKey(debugLabel: 'feature-tour-stamp-visit');
  static final passportButton =
      GlobalKey(debugLabel: 'feature-tour-passport-button');
  static final passportBook =
      GlobalKey(debugLabel: 'feature-tour-passport-book');
  static final stampNavigation =
      GlobalKey(debugLabel: 'feature-tour-stamp-nav');
  static final potatoGrowth =
      GlobalKey(debugLabel: 'feature-tour-potato-growth');
  static final potatoCareActions =
      GlobalKey(debugLabel: 'feature-tour-potato-care-actions');
  static final potatoSteps = GlobalKey(debugLabel: 'feature-tour-potato-steps');
  static final representativePotato =
      GlobalKey(debugLabel: 'feature-tour-representative-potato');
  static final potatoInfo = GlobalKey(debugLabel: 'feature-tour-potato-info');
  static final potatoNavigation =
      GlobalKey(debugLabel: 'feature-tour-potato-nav');
  static final missionFeatured =
      GlobalKey(debugLabel: 'feature-tour-mission-featured');
  static final missionDetailAction =
      GlobalKey(debugLabel: 'feature-tour-mission-detail-action');
  static final missionDaily =
      GlobalKey(debugLabel: 'feature-tour-mission-daily');
  static final missionNavigation =
      GlobalKey(debugLabel: 'feature-tour-mission-nav');
  static final audioPlay = GlobalKey(debugLabel: 'feature-tour-audio-play');
  static final visitVerify = GlobalKey(debugLabel: 'feature-tour-visit-verify');
  static final myPageTravelRecord =
      GlobalKey(debugLabel: 'feature-tour-my-page-travel-record');
  static final travelRecordGallery =
      GlobalKey(debugLabel: 'feature-tour-travel-record-gallery');
}
