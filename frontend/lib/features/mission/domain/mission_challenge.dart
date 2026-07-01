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
  photoOcr('촬영 인증', Icons.document_scanner_rounded),
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

  MissionChallenge copyWith({
    MissionStatus? status,
    int? progress,
    bool? active,
    bool? isNew,
  }) {
    return MissionChallenge(
      id: id,
      group: group,
      type: type,
      status: status ?? this.status,
      title: title,
      spotName: spotName,
      cityName: cityName,
      description: description,
      dialogue: dialogue,
      conditionLabel: conditionLabel,
      rewardType: rewardType,
      rewardLabel: rewardLabel,
      progress: progress ?? this.progress,
      target: target,
      isNew: isNew ?? this.isNew,
      active: active ?? this.active,
    );
  }

  factory MissionChallenge.fromJson(Object? json) {
    final map = json as Map<String, dynamic>? ?? const <String, dynamic>{};
    final missionId = map['missionId'] ?? map['id'] ?? '';
    final completed = map['completed'] as bool? ?? false;
    return MissionChallenge(
      id: missionId.toString(),
      group: _missionGroupFromApi(map['group'] as String?),
      type: _missionTypeFromApi(map['type'] as String?),
      status: completed
          ? MissionStatus.completed
          : _missionStatusFromApi(map['status'] as String?),
      title: map['title'] as String? ?? '',
      spotName: map['spotName'] as String? ?? '',
      cityName: map['cityName'] as String? ?? '',
      description: map['description'] as String? ?? '',
      dialogue: map['dialogue'] as String? ?? '',
      conditionLabel: map['conditionLabel'] as String? ?? '',
      rewardType: _missionRewardTypeFromApi(map['rewardType'] as String?),
      rewardLabel: map['rewardLabel'] as String? ?? '',
      progress: _intFromJson(map['progress'], fallback: 0),
      target: _intFromJson(map['target'], fallback: 1),
      isNew: map['new'] as bool? ?? map['isNew'] as bool? ?? false,
      active: map['active'] as bool? ?? true,
    );
  }

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

MissionGroup _missionGroupFromApi(String? value) {
  return switch (value) {
    'DAILY' => MissionGroup.daily,
    'WEEKLY' => MissionGroup.weekly,
    'EVENT' => MissionGroup.event,
    _ => MissionGroup.jumsooni,
  };
}

MissionType _missionTypeFromApi(String? value) {
  return switch (value) {
    'VISIT_AND_STEP' => MissionType.visitAndStep,
    'PHOTO' => MissionType.photo,
    'PHOTO_OCR' => MissionType.photoOcr,
    'QR_SCAN' => MissionType.qrScan,
    'QUIZ' => MissionType.quiz,
    'STAMP' => MissionType.stamp,
    'COLLECTION' => MissionType.collection,
    _ => MissionType.visit,
  };
}

MissionStatus _missionStatusFromApi(String? value) {
  return switch (value) {
    'IN_PROGRESS' => MissionStatus.inProgress,
    'COMPLETED' => MissionStatus.completed,
    'LOCKED' => MissionStatus.locked,
    _ => MissionStatus.ready,
  };
}

MissionRewardType _missionRewardTypeFromApi(String? value) {
  return switch (value) {
    'COUPON' => MissionRewardType.coupon,
    'ITEM' => MissionRewardType.item,
    'COIN' => MissionRewardType.coin,
    _ => MissionRewardType.potato,
  };
}

int _intFromJson(Object? value, {required int fallback}) {
  return switch (value) {
    int number => number,
    num number => number.toInt(),
    String text => int.tryParse(text) ?? fallback,
    _ => fallback,
  };
}
