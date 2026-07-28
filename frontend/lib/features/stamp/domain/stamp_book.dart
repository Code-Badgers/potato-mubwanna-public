class StampBook {
  const StampBook({required this.progress, required this.nextReward});

  final StampProgress progress;
  final NextStampReward nextReward;
}

class StampProgress {
  const StampProgress({
    required this.totalCount,
    required this.acquiredCount,
    required this.stamps,
  });

  final int totalCount;
  final int acquiredCount;
  final List<RallybookStamp> stamps;

  static StampProgress fromJson(Object? json) {
    final data = json as Map<String, dynamic>? ?? const <String, dynamic>{};
    final stampValues = data['stamps'] as List<dynamic>? ?? const [];

    return StampProgress(
      totalCount: data['totalCount'] as int? ?? 0,
      acquiredCount: data['acquiredCount'] as int? ?? 0,
      stamps: stampValues
          .whereType<Map<String, dynamic>>()
          .map(RallybookStamp.fromJson)
          .toList(growable: false),
    );
  }
}

class RallybookStamp {
  const RallybookStamp({
    required this.stampId,
    required this.cityName,
    required this.stampName,
    required this.stampImage,
    required this.acquired,
    required this.acquiredAt,
  });

  final int stampId;
  final String cityName;
  final String stampName;
  final String? stampImage;
  final bool acquired;
  final DateTime? acquiredAt;

  static RallybookStamp fromJson(Map<String, dynamic> json) {
    final acquiredAtValue = json['acquiredAt'] as String?;

    return RallybookStamp(
      stampId: json['stampId'] as int? ?? 0,
      cityName: json['cityName'] as String? ?? '',
      stampName: json['stampName'] as String? ?? '',
      stampImage: json['stampImage'] as String?,
      acquired: json['acquired'] as bool? ?? false,
      acquiredAt: acquiredAtValue == null || acquiredAtValue.isEmpty
          ? null
          : DateTime.parse(acquiredAtValue),
    );
  }
}

class StampNextTarget {
  const StampNextTarget({
    required this.spotId,
    required this.spotName,
    required this.cityName,
    required this.category,
    required this.address,
    required this.imageUrl,
  });

  final int spotId;
  final String spotName;
  final String cityName;
  final String category;
  final String address;
  final String? imageUrl;

  String get categoryLabel => switch (category) {
    'POTATO_TOUR' => '관광',
    'POTATO_EXPERIENCE' => '체험',
    'POTATO_RESTAURANT' => '맛집',
    'POTATO_CAFE' => '카페',
    'POTATO_SNACK' => '간식',
    'POTATO_MARKET' => '시장',
    'POTATO_BREWERY' => '바 & 페어링',
    'POTATO_SHOP' => '쇼핑',
    _ => '감자 스팟',
  };

  static StampNextTarget fromJson(Map<String, dynamic> json) {
    return StampNextTarget(
      spotId: (json['spotId'] as num?)?.toInt() ?? 0,
      spotName: json['spotName'] as String? ?? '',
      cityName: json['cityName'] as String? ?? '',
      category: json['category'] as String? ?? '',
      address: json['address'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

class NextStampReward {
  const NextStampReward({
    required this.acquiredCount,
    required this.nextTargetCount,
    required this.remainingCount,
    required this.completed,
    required this.claimable,
    required this.claimableTargetCount,
  });

  final int acquiredCount;
  final int? nextTargetCount;
  final int remainingCount;
  final bool completed;
  final bool claimable;
  final int? claimableTargetCount;

  bool get canClaim => claimable && claimableTargetCount != null;

  static NextStampReward fromJson(Object? json) {
    final data = json as Map<String, dynamic>? ?? const <String, dynamic>{};

    return NextStampReward(
      acquiredCount: data['acquiredCount'] as int? ?? 0,
      nextTargetCount: data['nextTargetCount'] as int?,
      remainingCount: data['remainingCount'] as int? ?? 0,
      completed: data['completed'] as bool? ?? false,
      claimable: data['claimable'] as bool? ?? false,
      claimableTargetCount: data['claimableTargetCount'] as int?,
    );
  }
}
