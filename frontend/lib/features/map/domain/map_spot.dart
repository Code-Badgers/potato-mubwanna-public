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
    this.imageUrl,
    this.menuItems = const [],
    this.isRecommended = false,
  });

  factory MapSpot.fromJson(Map<String, dynamic> json) {
    final menuItems = (json['menuItems'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(MapSpotMenuItem.fromJson)
        .where((item) => item.name.isNotEmpty && item.hasPrice)
        .toList(growable: false);
    return MapSpot(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '이름 없는 감자 스팟',
      category: json['category'] as String? ?? 'POTATO_TOUR',
      latitude: _readDouble(json['latitude']),
      longitude: _readDouble(json['longitude']),
      address: json['address'] as String? ?? '',
      cityName: json['cityName'] as String? ?? '',
      imageUrl: _readNullableString(json['imageUrl']),
      congestionLevel: json['congestionLevel'] as String? ?? 'NORMAL',
      stampEnabled: json['stampEnabled'] as bool? ?? true,
      menuItems: menuItems,
    );
  }

  final String id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final String address;
  final String cityName;
  final String? imageUrl;
  final String congestionLevel;
  final bool stampEnabled;
  final List<MapSpotMenuItem> menuItems;
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
      imageUrl: imageUrl,
      congestionLevel: congestionLevel,
      stampEnabled: stampEnabled,
      menuItems: menuItems,
      isRecommended: true,
    );
  }

  String get categoryLabel {
    return switch (category) {
      'POTATO_TOUR' => '관광·쇼핑',
      'POTATO_EXPERIENCE' => '체험',
      'POTATO_RESTAURANT' => '식당',
      'POTATO_CAFE' => '카페·디저트',
      'POTATO_SNACK' => '카페·디저트',
      'POTATO_MARKET' => '시장·상권',
      'POTATO_BREWERY' => '식당',
      'POTATO_SHOP' => '관광·쇼핑',
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
      'POTATO_RESTAURANT' => '식당감자',
      'POTATO_CAFE' => '디저트감자',
      'POTATO_SNACK' => '디저트감자',
      'POTATO_MARKET' => '시장감자',
      'POTATO_BREWERY' => '식당감자',
      'POTATO_SHOP' => '여행감자',
      'POTATO_EXPERIENCE' => '체험감자',
      _ => '여행감자',
    };
  }

  String get markerColorHex {
    return '#56C787';
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

  static String? _readNullableString(dynamic value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class MapSpotMenuItem {
  const MapSpotMenuItem({
    required this.name,
    required this.priceWon,
    required this.priceNote,
    required this.verifiedOn,
  });

  factory MapSpotMenuItem.fromJson(Map<String, dynamic> json) {
    return MapSpotMenuItem(
      name: json['name'] as String? ?? '',
      priceWon: (json['priceWon'] as num?)?.toInt(),
      priceNote: json['priceNote'] as String?,
      verifiedOn: json['verifiedOn'] as String? ?? '',
    );
  }

  final String name;
  final int? priceWon;
  final String? priceNote;
  final String verifiedOn;

  bool get hasPrice => priceWon != null || (priceNote?.isNotEmpty ?? false);

  String get priceLabel {
    if (priceWon != null) {
      final formatted = priceWon!.toString().replaceAllMapped(
            RegExp(r'(?=(\d{3})+(?!\d))'),
            (_) => ',',
          );
      return '$formatted원';
    }
    return priceNote ?? '';
  }

  String get verifiedOnLabel => verifiedOn.replaceAll('-', '.');
}
