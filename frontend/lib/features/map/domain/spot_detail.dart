import 'package:potato_mubwanna/features/map/domain/map_spot.dart';

class SpotDetail {
  const SpotDetail({
    required this.id,
    required this.name,
    required this.category,
    required this.cityName,
    required this.address,
    this.imageUrl,
    this.imageUrls = const [],
    this.menuItems = const [],
    this.description,
    this.openingHours,
    this.closedDays,
    this.admissionFee,
    this.parking,
    this.contactPhone,
  });

  factory SpotDetail.fromJson(Map<String, dynamic> json) {
    return SpotDetail(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      cityName: json['cityName'] as String? ?? '',
      address: json['address'] as String? ?? '',
      imageUrl: _readNullableString(json['imageUrl']),
      imageUrls: _readImageUrls(json),
      menuItems: _readMenuItems(json),
      description: _readNullableString(json['description']),
      openingHours: _readNullableString(json['openingHours']),
      closedDays: _readNullableString(json['closedDays']),
      admissionFee: _readNullableString(json['admissionFee']),
      parking: _readNullableString(json['parking']),
      contactPhone: _readNullableString(json['contactPhone']),
    );
  }

  final String id;
  final String name;
  final String category;
  final String cityName;
  final String address;
  final String? imageUrl;
  final List<String> imageUrls;
  final List<MapSpotMenuItem> menuItems;
  final String? description;
  final String? openingHours;
  final String? closedDays;
  final String? admissionFee;
  final String? parking;
  final String? contactPhone;

  bool get hasTourInfo {
    return _hasText(description) ||
        _hasText(openingHours) ||
        _hasText(closedDays) ||
        _hasText(admissionFee) ||
        _hasText(parking) ||
        _hasText(contactPhone);
  }

  static String? _readNullableString(dynamic value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;

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

  static List<MapSpotMenuItem> _readMenuItems(Map<String, dynamic> json) {
    return (json['menuItems'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(MapSpotMenuItem.fromJson)
        .where((item) => item.name.isNotEmpty && item.hasPrice)
        .toList(growable: false);
  }
}
