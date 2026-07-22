class SpotDetail {
  const SpotDetail({
    required this.id,
    required this.contentId,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.cityName,
    required this.imageUrl,
    required this.potatoTags,
    required this.congestionLevel,
    required this.verificationRadiusMeter,
    required this.stampEnabled,
  });

  factory SpotDetail.fromJson(Object? json) {
    final data = json as Map<String, dynamic>? ?? const <String, dynamic>{};
    final imageUrl = data['imageUrl'] as String?;
    final tagValue = data['potatoTags'] as String? ?? '';

    return SpotDetail(
      id: '${data['id'] ?? ''}',
      contentId: data['contentId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? '',
      latitude: _readDouble(data['latitude']),
      longitude: _readDouble(data['longitude']),
      address: data['address'] as String? ?? '',
      cityName: data['cityName'] as String? ?? '',
      imageUrl: imageUrl == null || imageUrl.trim().isEmpty ? null : imageUrl,
      potatoTags: tagValue
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList(growable: false),
      congestionLevel: data['congestionLevel'] as String? ?? 'NORMAL',
      verificationRadiusMeter: data['verificationRadiusMeter'] as int? ?? 0,
      stampEnabled: data['stampEnabled'] as bool? ?? false,
    );
  }

  final String id;
  final String contentId;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final String address;
  final String cityName;
  final String? imageUrl;
  final List<String> potatoTags;
  final String congestionLevel;
  final int verificationRadiusMeter;
  final bool stampEnabled;

  String get categoryLabel {
    return switch (category) {
      'POTATO_TOUR' => '관광',
      'POTATO_EXPERIENCE' => '체험',
      'POTATO_RESTAURANT' => '맛집',
      'POTATO_CAFE' => '카페',
      'POTATO_SNACK' => '간식',
      'POTATO_MARKET' => '시장',
      'POTATO_BREWERY' => '바 & 페어링',
      'POTATO_SHOP' => '쇼핑',
      _ => '관광지',
    };
  }

  String get congestionLabel {
    return switch (congestionLevel) {
      'LOW' => '여유',
      'HIGH' => '혼잡',
      _ => '보통',
    };
  }

  static double _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }
}
