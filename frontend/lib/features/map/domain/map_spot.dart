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
    this.isRecommended = false,
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
  final bool isRecommended;

  MapSpot asRecommended() {
    return MapSpot(
      id: id,
      name: name,
      category: category,
      latitude: latitude,
      longitude: longitude,
      address: address,
      cityName: cityName,
      congestionLevel: congestionLevel,
      stampEnabled: stampEnabled,
      isRecommended: true,
    );
  }

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
      'POTATO_MARKET' => '직판감자',
      'POTATO_BREWERY' => '페어링감자',
      'POTATO_SHOP' => '기념감자',
      'POTATO_EXPERIENCE' => '체험감자',
      _ => '여행감자',
    };
  }

  String get markerColorHex {
    if (isRecommended) {
      return '#7A5AF8';
    }
    return switch (category) {
      'POTATO_RESTAURANT' => '#FFB84D',
      'POTATO_CAFE' => '#D98CFF',
      'POTATO_SNACK' => '#F6C23E',
      'POTATO_MARKET' => '#36D98F',
      'POTATO_BREWERY' => '#7A9BFF',
      'POTATO_SHOP' => '#64C7D9',
      'POTATO_EXPERIENCE' => '#8BC34A',
      _ => '#36D98F',
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
