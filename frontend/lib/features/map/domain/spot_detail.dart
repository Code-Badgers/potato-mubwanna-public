class SpotDetail {
  const SpotDetail({
    required this.id,
    required this.name,
    required this.category,
    required this.cityName,
    this.imageUrl,
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
      imageUrl: _readNullableString(json['imageUrl']),
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
  final String? imageUrl;
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
}
