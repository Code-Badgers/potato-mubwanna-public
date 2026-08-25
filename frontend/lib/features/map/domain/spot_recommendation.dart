import 'map_spot.dart';

class SpotRecommendation {
  const SpotRecommendation({
    required this.spotId,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.cityName,
    required this.imageUrl,
    this.imageUrls = const [],
    required this.externalRank,
  });

  factory SpotRecommendation.fromJson(Map<String, dynamic> json) {
    final imageUrl = json['imageUrl'] as String?;
    return SpotRecommendation(
      spotId: '${json['spotId'] ?? ''}',
      name: json['name'] as String? ?? '이름 없는 추천 장소',
      category: json['category'] as String? ?? 'POTATO_TOUR',
      latitude: _readDouble(json['latitude']),
      longitude: _readDouble(json['longitude']),
      address: json['address'] as String? ?? '',
      cityName: json['cityName'] as String? ?? '',
      imageUrl: imageUrl == null || imageUrl.trim().isEmpty ? null : imageUrl,
      imageUrls: _readImageUrls(json),
      externalRank: _readInt(json['externalRank']),
    );
  }

  final String spotId;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final String address;
  final String cityName;
  final String? imageUrl;
  final List<String> imageUrls;
  final int externalRank;

  bool get hasValidCoordinates => latitude != 0 && longitude != 0;

  MapSpot toMapSpot() {
    return MapSpot(
      id: spotId,
      name: name,
      category: category,
      latitude: latitude,
      longitude: longitude,
      address: address,
      cityName: cityName,
      imageUrl: imageUrl,
      imageUrls: imageUrls,
      congestionLevel: 'NORMAL',
      stampEnabled: false,
      isRecommended: true,
    );
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

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static List<String> _readImageUrls(Map<String, dynamic> json) {
    final values = (json['imageUrls'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    final imageUrl = json['imageUrl'] as String?;
    final trimmedImageUrl = imageUrl?.trim();
    if (trimmedImageUrl == null ||
        trimmedImageUrl.isEmpty ||
        values.contains(trimmedImageUrl)) {
      return values;
    }
    return [trimmedImageUrl, ...values];
  }
}
