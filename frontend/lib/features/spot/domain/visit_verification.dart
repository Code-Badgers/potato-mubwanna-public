class VisitVerificationRequest {
  const VisitVerificationRequest({
    required this.spotId,
    required this.latitude,
    required this.longitude,
  });

  final String spotId;
  final double latitude;
  final double longitude;

  Map<String, Object?> toJson() {
    return {
      'spotId': int.tryParse(spotId),
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class VisitVerificationResult {
  const VisitVerificationResult({
    required this.spotId,
    required this.verified,
    required this.distanceMeters,
    required this.verificationRadiusMeter,
    required this.stampIssued,
    required this.potatoAcquired,
    required this.acquiredPotato,
    required this.missionAvailable,
    this.unlockedMission,
  });

  final String spotId;
  final bool verified;
  final double distanceMeters;
  final int verificationRadiusMeter;
  final bool stampIssued;
  final bool potatoAcquired;
  final VisitAcquiredPotato? acquiredPotato;
  final bool missionAvailable;
  final VisitUnlockedMission? unlockedMission;

  factory VisitVerificationResult.fromJson(Object? json) {
    final data = json as Map<String, dynamic>? ?? const <String, dynamic>{};
    final unlockedMission = data['unlockedMission'] == null
        ? null
        : VisitUnlockedMission.fromJson(data['unlockedMission']);
    return VisitVerificationResult(
      spotId: data['spotId']?.toString() ?? '',
      verified: data['verified'] as bool? ?? false,
      distanceMeters: (data['distanceMeters'] as num?)?.toDouble() ?? 0,
      verificationRadiusMeter: data['verificationRadiusMeter'] as int? ?? 0,
      stampIssued: data['stampIssued'] as bool? ?? false,
      potatoAcquired: data['potatoAcquired'] as bool? ?? false,
      acquiredPotato: data['acquiredPotato'] == null
          ? null
          : VisitAcquiredPotato.fromJson(data['acquiredPotato']),
      missionAvailable:
          data['missionAvailable'] as bool? ?? unlockedMission != null,
      unlockedMission: unlockedMission,
    );
  }
}

class VisitUnlockedMission {
  const VisitUnlockedMission({
    required this.id,
    required this.title,
    required this.type,
    required this.spotName,
    required this.cityName,
    required this.rewardType,
    required this.rewardLabel,
  });

  final String id;
  final String title;
  final String type;
  final String spotName;
  final String cityName;
  final String rewardType;
  final String rewardLabel;

  factory VisitUnlockedMission.fromJson(Object? json) {
    final data = json as Map<String, dynamic>? ?? const <String, dynamic>{};
    return VisitUnlockedMission(
      id: data['missionId']?.toString() ?? data['id']?.toString() ?? '',
      title: data['title'] as String? ?? '',
      type: data['type'] as String? ?? '',
      spotName: data['spotName'] as String? ?? '',
      cityName: data['cityName'] as String? ?? '',
      rewardType: data['rewardType'] as String? ?? '',
      rewardLabel: data['rewardLabel'] as String? ?? '',
    );
  }
}

class VisitAcquiredPotato {
  const VisitAcquiredPotato({
    required this.id,
    required this.code,
    required this.name,
    required this.region,
    required this.rarity,
    required this.acquisitionType,
    required this.alreadyOwned,
  });

  final String id;
  final String code;
  final String name;
  final String region;
  final String rarity;
  final String acquisitionType;
  final bool alreadyOwned;

  String get acquisitionMessage {
    if (alreadyOwned) return '이미 보유한 감자예요';
    return switch (acquisitionType.toUpperCase()) {
      'GROWTH' => '새로운 감자를 수확했어요!',
      'MISSION' => '미션 보상으로 감자를 받았어요!',
      'VISIT' => '방문 보상으로 감자를 받았어요!',
      'STAMP' => '스탬프 보상으로 감자를 받았어요!',
      'EVENT' => '이벤트 보상으로 감자를 받았어요!',
      _ => '새로운 감자를 받았어요!',
    };
  }

  factory VisitAcquiredPotato.fromJson(Object? json) {
    final data = json as Map<String, dynamic>? ?? const <String, dynamic>{};
    return VisitAcquiredPotato(
      id: data['potatoId']?.toString() ?? '',
      code: data['code'] as String? ?? '',
      name: data['name'] as String? ?? '',
      region: data['region'] as String? ?? '',
      rarity: data['rarity'] as String? ?? 'COMMON',
      acquisitionType: data['acquisitionType'] as String? ?? 'VISIT',
      alreadyOwned: data['alreadyOwned'] as bool? ?? false,
    );
  }

  String get rarityLabel {
    return switch (rarity) {
      'RARE' => '희귀',
      'EPIC' => '영웅',
      'LEGENDARY' => '전설',
      _ => '일반',
    };
  }
}
