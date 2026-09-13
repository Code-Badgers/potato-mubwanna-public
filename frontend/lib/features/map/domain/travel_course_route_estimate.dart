import 'package:flutter/foundation.dart';

class TravelCourseRouteEstimate {
  const TravelCourseRouteEstimate({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.source,
  });

  factory TravelCourseRouteEstimate.fromJson(Map<String, dynamic> json) {
    final distanceMeters = json['distanceMeters'];
    final durationSeconds = json['durationSeconds'];
    final source = json['source'];
    if (distanceMeters is! num ||
        durationSeconds is! num ||
        source is! String ||
        distanceMeters < 0 ||
        durationSeconds < 0 ||
        source.isEmpty) {
      throw const FormatException('차량 경로 응답이 올바르지 않습니다.');
    }
    return TravelCourseRouteEstimate(
      distanceMeters: distanceMeters.toInt(),
      durationSeconds: durationSeconds.toInt(),
      source: source,
    );
  }

  final int distanceMeters;
  final int durationSeconds;
  final String source;

  String get durationLabel {
    final totalMinutes = (durationSeconds / 60).ceil();
    if (totalMinutes < 60) {
      return '차량 이동 $totalMinutes분';
    }
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes.remainder(60);
    return minutes == 0
        ? '차량 이동 $hours시간'
        : '차량 이동 $hours시간 $minutes분';
  }
}

class TravelCourseRouteKey {
  TravelCourseRouteKey(Iterable<String> spotIds)
      : spotIds = List.unmodifiable(spotIds);

  final List<String> spotIds;

  @override
  bool operator ==(Object other) {
    return other is TravelCourseRouteKey && listEquals(other.spotIds, spotIds);
  }

  @override
  int get hashCode => Object.hashAll(spotIds);
}
