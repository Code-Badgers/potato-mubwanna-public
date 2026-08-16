class TravelRecord {
  const TravelRecord({
    required this.visitId,
    required this.spotId,
    required this.spotName,
    required this.category,
    required this.cityName,
    required this.address,
    required this.imageUrl,
    required this.uploadedImageUrl,
    required this.visitedAt,
  });

  factory TravelRecord.fromJson(Map<String, dynamic> json) {
    return TravelRecord(
      visitId: (json['visitId'] as num?)?.toInt() ?? 0,
      spotId: (json['spotId'] as num?)?.toInt() ?? 0,
      spotName: json['spotName'] as String? ?? '',
      category: json['category'] as String? ?? '',
      cityName: json['cityName'] as String? ?? '',
      address: json['address'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      uploadedImageUrl: json['uploadedImageUrl'] as String?,
      visitedAt: _requiredDateTime(json['visitedAt']),
    );
  }

  final int visitId;
  final int spotId;
  final String spotName;
  final String category;
  final String cityName;
  final String address;
  final String? imageUrl;
  final String? uploadedImageUrl;
  final DateTime visitedAt;

  String get categoryLabel => switch (category) {
        'POTATO_TOUR' => '관광·쇼핑',
        'POTATO_EXPERIENCE' => '체험',
        'POTATO_RESTAURANT' => '식당',
        'POTATO_CAFE' => '카페·디저트',
        'POTATO_SNACK' => '카페·디저트',
        'POTATO_MARKET' => '시장·상권',
        'POTATO_BREWERY' => '식당',
        'POTATO_SHOP' => '관광·쇼핑',
        _ => '감자 스팟',
      };
}

DateTime _requiredDateTime(Object? value) {
  if (value is! String || value.isEmpty) {
    throw const FormatException('필수 방문 날짜 형식이 올바르지 않습니다.');
  }
  return DateTime.parse(value);
}
