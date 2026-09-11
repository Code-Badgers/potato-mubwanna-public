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
    this.imageUrls = const [],
    this.phone,
    this.website,
    this.rating,
    this.businessOpeningHours,
    this.menuItems = const [],
    this.isRecommended = false,
  });

  factory MapSpot.fromJson(Map<String, dynamic> json) {
    final menuItems = (json['menuItems'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(MapSpotMenuItem.fromJson)
        .where((item) => item.name.trim().isNotEmpty)
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
      imageUrls: _readImageUrls(json),
      phone: _readNullableString(json['phone']),
      website: _readNullableString(json['website']),
      rating: _readNullableDouble(json['rating']),
      businessOpeningHours: MapSpotBusinessOpeningHours.fromJson(
        json['businessOpeningHours'],
      ),
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
  final List<String> imageUrls;
  final String? phone;
  final String? website;
  final double? rating;
  final MapSpotBusinessOpeningHours? businessOpeningHours;
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
      imageUrls: imageUrls,
      phone: phone,
      website: website,
      rating: rating,
      businessOpeningHours: businessOpeningHours,
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

  List<String> get effectiveImageUrls {
    final urls = <String>[
      ...imageUrls,
      if (imageUrl != null) imageUrl!,
    ];
    return urls
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  String? get todayOpeningText => businessOpeningHours?.todayText;

  bool get hasBusinessInfo {
    return (phone != null && phone!.trim().isNotEmpty) ||
        (website != null && website!.trim().isNotEmpty) ||
        rating != null ||
        (businessOpeningHours?.hasInfo ?? false);
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

  static double? _readNullableDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }

  static List<String> _readImageUrls(Map<String, dynamic> json) {
    final values = (json['imageUrls'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    final imageUrl = _readNullableString(json['imageUrl']);
    if (imageUrl == null || values.contains(imageUrl)) {
      return values;
    }
    return [imageUrl, ...values];
  }
}

class MapSpotBusinessOpeningHours {
  const MapSpotBusinessOpeningHours({
    required this.weekdayDescriptions,
    this.openNow,
    this.todayText,
  });

  factory MapSpotBusinessOpeningHours.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return nullOpeningHours;
    }
    final weekdayDescriptions =
        (json['weekdayDescriptions'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(growable: false);
    return MapSpotBusinessOpeningHours(
      openNow: json['openNow'] is bool ? json['openNow'] as bool : null,
      todayText: MapSpot._readNullableString(json['todayText']),
      weekdayDescriptions: weekdayDescriptions,
    );
  }

  static const nullOpeningHours = MapSpotBusinessOpeningHours(
    weekdayDescriptions: [],
  );

  final bool? openNow;
  final String? todayText;
  final List<String> weekdayDescriptions;

  bool get hasInfo {
    return openNow != null ||
        (todayText != null && todayText!.trim().isNotEmpty) ||
        weekdayDescriptions.isNotEmpty;
  }
}

class MapSpotMenuItem {
  const MapSpotMenuItem({
    required this.name,
    required this.priceWon,
    required this.priceNote,
    required this.verifiedOn,
    this.sourceUrl,
  });

  factory MapSpotMenuItem.fromJson(Map<String, dynamic> json) {
    return MapSpotMenuItem(
      name: json['name'] as String? ?? '',
      priceWon: (json['priceWon'] as num?)?.toInt(),
      priceNote: json['priceNote'] as String?,
      verifiedOn: json['verifiedOn'] as String? ?? '',
      sourceUrl: json['sourceUrl'] as String?,
    );
  }

  final String name;
  final int? priceWon;
  final String? priceNote;
  final String verifiedOn;
  final String? sourceUrl;

  bool get hasPrice => priceWon != null || (priceNote?.isNotEmpty ?? false);

  String get priceLabel {
    if (priceWon != null) {
      final formatted = priceWon!.toString().replaceAllMapped(
            RegExp(r'(?=(\d{3})+(?!\d))'),
            (_) => ',',
          );
      return '$formatted원';
    }
    return (priceNote?.trim().isNotEmpty ?? false)
        ? priceNote!.trim()
        : '가격 확인 필요';
  }

  String get verifiedOnLabel => verifiedOn.replaceAll('-', '.');
}
