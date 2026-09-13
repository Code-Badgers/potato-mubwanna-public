import '../../../shared/models/congestion_prediction.dart' as congestion;

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
    required String congestionLevel,
    this.congestionPredictionDate,
    this.congestionSource,
    required this.verificationRadiusMeter,
    required this.stampEnabled,
    this.description,
    this.openingHours,
    this.closedDays,
    this.admissionFee,
    this.parking,
    this.contactPhone,
    this.phone,
    this.website,
    this.rating,
    this.businessOpenNow,
    this.businessTodayText,
  }) : _congestionLevel = congestionLevel;

  factory SpotDetail.fromJson(Object? json) {
    final data = json as Map<String, dynamic>? ?? const <String, dynamic>{};
    final imageUrl = data['imageUrl'] as String?;
    final tagValue = data['potatoTags'] as String? ?? '';
    final businessOpeningHours = data['businessOpeningHours'];

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
      congestionLevel: data['congestionLevel'] as String? ?? 'UNKNOWN',
      congestionPredictionDate: data['congestionPredictionDate'] as String?,
      congestionSource: data['congestionSource'] as String?,
      verificationRadiusMeter: data['verificationRadiusMeter'] as int? ?? 0,
      stampEnabled: data['stampEnabled'] as bool? ?? false,
      description: _readNullableString(data['description']),
      openingHours: _readNullableString(data['openingHours']),
      closedDays: _readNullableString(data['closedDays']),
      admissionFee: _readNullableString(data['admissionFee']),
      parking: _readNullableString(data['parking']),
      contactPhone: _readNullableString(data['contactPhone']),
      phone: _readNullableString(data['phone']),
      website: _readNullableString(data['website']),
      rating: _readNullableDouble(data['rating']),
      businessOpenNow: businessOpeningHours is Map<String, dynamic> &&
              businessOpeningHours['openNow'] is bool
          ? businessOpeningHours['openNow'] as bool
          : null,
      businessTodayText: businessOpeningHours is Map<String, dynamic>
          ? _readNullableString(businessOpeningHours['todayText'])
          : null,
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
  final String _congestionLevel;
  final String? congestionPredictionDate;
  final String? congestionSource;
  String get congestionLevel => congestion.currentCongestionLevel(
      _congestionLevel, congestionPredictionDate);
  String get congestionDescription => congestion.congestionDescription(
      congestionLevel, congestionPredictionDate, congestionSource);
  final int verificationRadiusMeter;
  final bool stampEnabled;
  final String? description;
  final String? openingHours;
  final String? closedDays;
  final String? admissionFee;
  final String? parking;
  final String? contactPhone;
  final String? phone;
  final String? website;
  final double? rating;
  final bool? businessOpenNow;
  final String? businessTodayText;

  bool get hasPlaceInformation {
    return _hasText(description) ||
        _hasText(openingHours) ||
        _hasText(closedDays) ||
        _hasText(admissionFee) ||
        _hasText(parking) ||
        _hasText(contactPhone) ||
        _hasText(phone) ||
        _hasText(website) ||
        rating != null ||
        businessOpenNow != null ||
        _hasText(businessTodayText);
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
      _ => '관광지',
    };
  }

  String get congestionLabel => congestion.congestionLabel(congestionLevel);

  static double _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  static String? _readNullableString(Object? value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static double? _readNullableDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;
}
