enum CouponStatus {
  available,
  used,
  expired;

  static CouponStatus fromApiValue(String value) => switch (value) {
        'AVAILABLE' => CouponStatus.available,
        'USED' => CouponStatus.used,
        'EXPIRED' => CouponStatus.expired,
        _ => throw FormatException('알 수 없는 쿠폰 상태입니다: $value'),
      };
}

class CouponSummary {
  const CouponSummary({
    required this.userCouponId,
    required this.name,
    required this.description,
    required this.benefitAmount,
    required this.status,
    required this.expiresAt,
  });

  final int userCouponId;
  final String name;
  final String description;
  final int benefitAmount;
  final CouponStatus status;
  final DateTime expiresAt;

  static CouponSummary fromJson(Map<String, dynamic> json) => CouponSummary(
        userCouponId: json['userCouponId'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        benefitAmount: (json['benefitAmount'] as num?)?.toInt() ?? 0,
        status: CouponStatus.fromApiValue(json['status'] as String? ?? ''),
        expiresAt: _requiredDateTime(json['expiresAt']),
      );
}

class CouponDetail extends CouponSummary {
  const CouponDetail({
    required super.userCouponId,
    required super.name,
    required super.description,
    required super.benefitAmount,
    required super.status,
    required super.expiresAt,
    required this.usagePlace,
    required this.issuedAt,
    required this.usedAt,
  });

  final String usagePlace;
  final DateTime issuedAt;
  final DateTime? usedAt;

  static CouponDetail fromJson(Map<String, dynamic> json) => CouponDetail(
        userCouponId: json['userCouponId'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        benefitAmount: (json['benefitAmount'] as num?)?.toInt() ?? 0,
        status: CouponStatus.fromApiValue(json['status'] as String? ?? ''),
        expiresAt: _requiredDateTime(json['expiresAt']),
        usagePlace: json['usagePlace'] as String? ?? '',
        issuedAt: _requiredDateTime(json['issuedAt']),
        usedAt: _optionalDateTime(json['usedAt']),
      );
}

DateTime _requiredDateTime(Object? value) {
  if (value is! String || value.isEmpty) {
    throw const FormatException('필수 날짜 형식이 올바르지 않습니다.');
  }
  return DateTime.parse(value);
}

DateTime? _optionalDateTime(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.parse(value);
}
