enum PotatoRarity { common, rare, epic, legendary }

class PotatoCollection {
  const PotatoCollection({
    required this.totalCount,
    required this.acquiredCount,
    required this.items,
  });

  final int totalCount;
  final int acquiredCount;
  final List<PotatoCollectionItem> items;

  PotatoCollectionItem? get representativePotato {
    for (final item in items) {
      if (item.representative) {
        return item;
      }
    }
    for (final item in items) {
      if (item.acquired) {
        return item;
      }
    }
    return null;
  }

  static PotatoCollection fromJson(Object? json) {
    final data = json as Map<String, dynamic>? ?? const <String, dynamic>{};
    final itemValues = data['items'] as List<dynamic>? ?? const [];

    return PotatoCollection(
      totalCount: data['totalCount'] as int? ?? 0,
      acquiredCount: data['acquiredCount'] as int? ?? 0,
      items: itemValues
          .whereType<Map<String, dynamic>>()
          .map(PotatoCollectionItem.fromJson)
          .toList(growable: false),
    );
  }
}

class PotatoCollectionItem {
  const PotatoCollectionItem({
    required this.id,
    required this.code,
    required this.name,
    required this.region,
    required this.rarity,
    required this.description,
    required this.acquisitionHint,
    required this.imageUrl,
    required this.acquired,
    required this.acquiredAt,
    required this.level,
    required this.growthDistance,
    required this.growthGoalDistance,
    required this.representative,
    this.careStatus,
  });

  final String id;
  final String code;
  final String name;
  final String region;
  final PotatoRarity rarity;
  final String description;
  final String acquisitionHint;
  final String? imageUrl;
  final bool acquired;
  final DateTime? acquiredAt;
  final int level;
  final double growthDistance;
  final double growthGoalDistance;
  final bool representative;
  final PotatoCareStatus? careStatus;

  double get growthRatio {
    if (growthGoalDistance <= 0) {
      return 0;
    }
    return (growthDistance / growthGoalDistance).clamp(0, 1);
  }

  static PotatoCollectionItem fromJson(Map<String, dynamic> json) {
    final acquiredAtValue = json['acquiredAt'] as String?;

    return PotatoCollectionItem(
      id: json['potatoId']?.toString() ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      region: json['region'] as String? ?? '',
      rarity: potatoRarityFromApi(json['rarity'] as String?),
      description: json['description'] as String? ?? '',
      acquisitionHint: json['acquisitionHint'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      acquired: json['acquired'] as bool? ?? false,
      acquiredAt: acquiredAtValue == null || acquiredAtValue.isEmpty
          ? null
          : DateTime.parse(acquiredAtValue),
      level: json['level'] as int? ?? 0,
      growthDistance: (json['growthDistance'] as num?)?.toDouble() ?? 0,
      growthGoalDistance: (json['growthGoalDistance'] as num?)?.toDouble() ?? 0,
      representative: json['representative'] as bool? ?? false,
      careStatus: json['careStatus'] is Map<String, dynamic>
          ? PotatoCareStatus.fromJson(
              json['careStatus'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class PotatoCareStatus {
  const PotatoCareStatus({
    required this.satiety,
    required this.moisture,
    required this.mood,
    required this.calculatedAt,
  });

  final int satiety;
  final int moisture;
  final int mood;
  final DateTime calculatedAt;

  static PotatoCareStatus fromJson(Map<String, dynamic> json) =>
      PotatoCareStatus(
        satiety: (json['satiety'] as num?)?.toInt() ?? 0,
        moisture: (json['moisture'] as num?)?.toInt() ?? 0,
        mood: (json['mood'] as num?)?.toInt() ?? 0,
        calculatedAt: DateTime.parse(json['calculatedAt'] as String),
      );
}

class PotatoRepresentativeResult {
  const PotatoRepresentativeResult({
    required this.potatoId,
    required this.representative,
  });

  final String potatoId;
  final bool representative;

  static PotatoRepresentativeResult fromJson(Object? json) {
    final data = json as Map<String, dynamic>? ?? const <String, dynamic>{};
    return PotatoRepresentativeResult(
      potatoId: data['potatoId']?.toString() ?? '',
      representative: data['representative'] as bool? ?? false,
    );
  }
}

enum PotatoInteractionAction {
  pat('PAT'),
  water('WATER'),
  snack('SNACK'),
  walk('WALK');

  const PotatoInteractionAction(this.apiValue);

  final String apiValue;
}

class PotatoInteractionResult {
  const PotatoInteractionResult({
    required this.potatoId,
    required this.potatoName,
    required this.action,
    required this.growthDistanceAdded,
    required this.cooldownSeconds,
    required this.nextAvailableAt,
    required this.growthResult,
    this.careStatus,
  });

  final String potatoId;
  final String potatoName;
  final PotatoInteractionAction action;
  final double growthDistanceAdded;
  final int cooldownSeconds;
  final DateTime nextAvailableAt;
  final PotatoGrowthResult? growthResult;
  final PotatoCareStatus? careStatus;

  static PotatoInteractionResult fromJson(Object? json) {
    final data = json as Map<String, dynamic>? ?? const <String, dynamic>{};
    final actionValue = data['action'] as String?;
    final growthResultJson = data['growthResult'];
    return PotatoInteractionResult(
      potatoId: data['potatoId']?.toString() ?? '',
      potatoName: data['potatoName'] as String? ?? '',
      action: PotatoInteractionAction.values.firstWhere(
        (action) => action.apiValue == actionValue,
        orElse: () => PotatoInteractionAction.pat,
      ),
      growthDistanceAdded:
          (data['growthDistanceAdded'] as num?)?.toDouble() ?? 0,
      cooldownSeconds: (data['cooldownSeconds'] as num?)?.toInt() ?? 0,
      nextAvailableAt: DateTime.parse(data['nextAvailableAt'] as String),
      careStatus: data['careStatus'] is Map<String, dynamic>
          ? PotatoCareStatus.fromJson(
              data['careStatus'] as Map<String, dynamic>,
            )
          : null,
      growthResult: growthResultJson is Map<String, dynamic>
          ? PotatoGrowthResult.fromJson(growthResultJson)
          : null,
    );
  }
}

class PotatoActivitySyncResult {
  const PotatoActivitySyncResult({required this.growthResult});

  final PotatoGrowthResult? growthResult;

  static PotatoActivitySyncResult fromJson(Object? json) {
    final data = json as Map<String, dynamic>? ?? const <String, dynamic>{};
    final growthResultJson = data['growthResult'];
    return PotatoActivitySyncResult(
      growthResult: growthResultJson is Map<String, dynamic>
          ? PotatoGrowthResult.fromJson(growthResultJson)
          : null,
    );
  }
}

class PotatoGrowthResult {
  const PotatoGrowthResult({
    required this.potatoId,
    required this.potatoName,
    required this.previousLevel,
    required this.currentLevel,
    required this.leveledUp,
    required this.fullyGrown,
  });

  final String potatoId;
  final String potatoName;
  final int previousLevel;
  final int currentLevel;
  final bool leveledUp;
  final bool fullyGrown;

  static PotatoGrowthResult fromJson(Map<String, dynamic> json) {
    return PotatoGrowthResult(
      potatoId: json['potatoId']?.toString() ?? '',
      potatoName: json['potatoName'] as String? ?? '',
      previousLevel: json['previousLevel'] as int? ?? 0,
      currentLevel: json['currentLevel'] as int? ?? 0,
      leveledUp: json['leveledUp'] as bool? ?? false,
      fullyGrown: json['fullyGrown'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'potatoId': potatoId,
      'potatoName': potatoName,
      'previousLevel': previousLevel,
      'currentLevel': currentLevel,
      'leveledUp': leveledUp,
      'fullyGrown': fullyGrown,
    };
  }
}

class PotatoGrowthSummary {
  const PotatoGrowthSummary({
    required this.todaySteps,
    required this.dailyStepGoal,
    required this.weeklyDistanceKm,
    required this.monthlyDistanceKm,
    required this.remainingDistanceKmForRepresentative,
  });

  final int todaySteps;
  final int dailyStepGoal;
  final double weeklyDistanceKm;
  final double monthlyDistanceKm;
  final double remainingDistanceKmForRepresentative;

  double get stepRatio {
    if (dailyStepGoal <= 0) {
      return 0;
    }
    return (todaySteps / dailyStepGoal).clamp(0, 1);
  }

  PotatoGrowthSummary copyWith({
    int? todaySteps,
    int? dailyStepGoal,
    double? weeklyDistanceKm,
    double? monthlyDistanceKm,
    double? remainingDistanceKmForRepresentative,
  }) {
    return PotatoGrowthSummary(
      todaySteps: todaySteps ?? this.todaySteps,
      dailyStepGoal: dailyStepGoal ?? this.dailyStepGoal,
      weeklyDistanceKm: weeklyDistanceKm ?? this.weeklyDistanceKm,
      monthlyDistanceKm: monthlyDistanceKm ?? this.monthlyDistanceKm,
      remainingDistanceKmForRepresentative:
          remainingDistanceKmForRepresentative ??
          this.remainingDistanceKmForRepresentative,
    );
  }

  static PotatoGrowthSummary fromJson(Object? json) {
    final data = json as Map<String, dynamic>? ?? const <String, dynamic>{};
    return PotatoGrowthSummary(
      todaySteps: data['todaySteps'] as int? ?? 0,
      dailyStepGoal: data['dailyStepGoal'] as int? ?? 0,
      weeklyDistanceKm: (data['weeklyDistanceKm'] as num?)?.toDouble() ?? 0,
      monthlyDistanceKm: (data['monthlyDistanceKm'] as num?)?.toDouble() ?? 0,
      remainingDistanceKmForRepresentative:
          (data['remainingDistanceKmForRepresentative'] as num?)?.toDouble() ??
          0,
    );
  }
}

PotatoRarity potatoRarityFromApi(String? value) {
  return switch (value) {
    'RARE' => PotatoRarity.rare,
    'EPIC' => PotatoRarity.epic,
    'LEGENDARY' => PotatoRarity.legendary,
    _ => PotatoRarity.common,
  };
}

String potatoRarityLabel(PotatoRarity rarity) {
  return switch (rarity) {
    PotatoRarity.common => '일반',
    PotatoRarity.rare => '희귀',
    PotatoRarity.epic => '영웅',
    PotatoRarity.legendary => '전설',
  };
}
