import 'package:flutter/material.dart';

enum MissionGroup {
  jumsooni('점순이'),
  daily('일일'),
  weekly('주간'),
  event('이벤트');

  const MissionGroup(this.label);

  final String label;
}

enum MissionType {
  visit('방문 인증', Icons.location_on_rounded),
  visitAndStep('걷기 인증', Icons.directions_walk_rounded),
  photo('사진 인증', Icons.camera_alt_rounded),
  qrScan('QR 스캔', Icons.qr_code_scanner_rounded),
  quiz('퀴즈', Icons.quiz_rounded),
  stamp('스탬프', Icons.emoji_events_rounded),
  collection('수집', Icons.eco_rounded);

  const MissionType(this.label, this.icon);

  final String label;
  final IconData icon;
}

enum MissionStatus {
  ready('도전 가능'),
  inProgress('진행 중'),
  completed('완료'),
  locked('준비 중');

  const MissionStatus(this.label);

  final String label;
}

enum MissionRewardType {
  potato('감자'),
  coupon('쿠폰'),
  item('아이템'),
  coin('코인');

  const MissionRewardType(this.label);

  final String label;
}

class MissionChallenge {
  const MissionChallenge({
    required this.id,
    required this.group,
    required this.type,
    required this.status,
    required this.title,
    required this.spotName,
    required this.cityName,
    required this.description,
    required this.dialogue,
    required this.conditionLabel,
    required this.rewardType,
    required this.rewardLabel,
    required this.progress,
    required this.target,
    this.isNew = false,
    this.active = true,
  });

  final String id;
  final MissionGroup group;
  final MissionType type;
  final MissionStatus status;
  final String title;
  final String spotName;
  final String cityName;
  final String description;
  final String dialogue;
  final String conditionLabel;
  final MissionRewardType rewardType;
  final String rewardLabel;
  final int progress;
  final int target;
  final bool isNew;
  final bool active;

  double get progressRatio {
    if (target <= 0) {
      return 0;
    }
    return (progress / target).clamp(0, 1).toDouble();
  }

  String get progressLabel {
    if (target <= 1) {
      return status == MissionStatus.completed ? '1/1' : '0/1';
    }
    return '$progress/$target';
  }
}
