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
  });

  final String spotId;
  final bool verified;
  final double distanceMeters;
  final int verificationRadiusMeter;
  final bool stampIssued;
  final bool potatoAcquired;
  final VisitAcquiredPotato? acquiredPotato;
  final bool missionAvailable;

  factory VisitVerificationResult.fromJson(Object? json) {
    final data = json as Map<String, dynamic>? ?? const <String, dynamic>{};
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
      missionAvailable: data['missionAvailable'] as bool? ?? false,
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
    required this.alreadyOwned,
  });

  final String id;
  final String code;
  final String name;
  final String region;
  final String rarity;
  final bool alreadyOwned;

  factory VisitAcquiredPotato.fromJson(Object? json) {
    final data = json as Map<String, dynamic>? ?? const <String, dynamic>{};
    return VisitAcquiredPotato(
      id: data['potatoId']?.toString() ?? '',
      code: data['code'] as String? ?? '',
      name: data['name'] as String? ?? '',
      region: data['region'] as String? ?? '',
      rarity: data['rarity'] as String? ?? 'COMMON',
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
