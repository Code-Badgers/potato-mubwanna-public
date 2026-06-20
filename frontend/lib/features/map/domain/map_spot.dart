class MapSpot {
  const MapSpot({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.cityName,
    required this.congestionLevel,
    required this.stampEnabled,
  });

  factory MapSpot.fromJson(Map<String, dynamic> json) {
    return MapSpot(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '이름 없는 감자 스팟',
      category: json['category'] as String? ?? 'POTATO_TOUR',
      latitude: _readDouble(json['latitude']),
      longitude: _readDouble(json['longitude']),
      address: json['address'] as String? ?? '',
      cityName: json['cityName'] as String? ?? '',
      congestionLevel: json['congestionLevel'] as String? ?? 'NORMAL',
      stampEnabled: json['stampEnabled'] as bool? ?? true,
    );
  }

  final String id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final String address;
  final String cityName;
  final String congestionLevel;
  final bool stampEnabled;

  String get categoryLabel {
    return switch (category) {
      'POTATO_TOUR' => '관광',
      'POTATO_EXPERIENCE' => '체험',
      'POTATO_RESTAURANT' => '맛집',
      'POTATO_CAFE' => '카페',
      'POTATO_SNACK' => '간식',
      'POTATO_SHOP' => '쇼핑',
      _ => '감자',
    };
  }

  String get congestionLabel {
    return switch (congestionLevel) {
      'LOW' => '여유',
      'HIGH' => '혼잡',
      _ => '보통',
    };
  }

  String get potatoName {
    return switch (category) {
      'POTATO_RESTAURANT' => '맛감자',
      'POTATO_CAFE' => '디저트감자',
      'POTATO_SNACK' => '간식감자',
      'POTATO_SHOP' => '기념감자',
      'POTATO_EXPERIENCE' => '체험감자',
      _ => '여행감자',
    };
  }

  bool get isRare => congestionLevel == 'LOW' || category == 'POTATO_TOUR';

  bool matchesCategoryLabel(String label) {
    return label == '전체' || categoryLabel == label;
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }
}
