class FavoriteSpot {
  const FavoriteSpot({
    required this.spotId,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
  });

  factory FavoriteSpot.fromJson(Map<String, dynamic> json) {
    return FavoriteSpot(
      spotId: json['spotId'].toString(),
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      latitude: _readDouble(json['latitude']),
      longitude: _readDouble(json['longitude']),
    );
  }

  final String spotId;
  final String name;
  final String category;
  final double latitude;
  final double longitude;

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

class FavoriteSpotToggleResult {
  const FavoriteSpotToggleResult({
    required this.spotId,
    required this.favorite,
  });

  factory FavoriteSpotToggleResult.fromJson(Map<String, dynamic> json) {
    return FavoriteSpotToggleResult(
      spotId: json['spotId'].toString(),
      favorite: json['favorite'] as bool? ?? false,
    );
  }

  final String spotId;
  final bool favorite;
}
