enum PotatoRarity {
  common,
  rare,
  epic,
  legendary,
}

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
    );
  }
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
