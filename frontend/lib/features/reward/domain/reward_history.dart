enum RewardType {
  potato('감자'),
  coupon('쿠폰'),
  item('아이템'),
  coin('감자 코인');

  const RewardType(this.label);

  final String label;

  static RewardType fromApiValue(String value) => switch (value) {
        'POTATO' => RewardType.potato,
        'COUPON' => RewardType.coupon,
        'ITEM' => RewardType.item,
        'COIN' => RewardType.coin,
        _ => throw FormatException('알 수 없는 보상 유형입니다: $value'),
      };
}

enum RewardSourceType {
  mission('미션 보상'),
  stamp('스탬프 보상'),
  event('이벤트 보상');

  const RewardSourceType(this.label);

  final String label;

  static RewardSourceType fromApiValue(String value) => switch (value) {
        'MISSION' => RewardSourceType.mission,
        'STAMP' => RewardSourceType.stamp,
        'EVENT' => RewardSourceType.event,
        _ => throw FormatException('알 수 없는 보상 지급 경로입니다: $value'),
      };
}

class RewardHistory {
  const RewardHistory({
    required this.rewardHistoryId,
    required this.rewardType,
    required this.rewardName,
    required this.sourceType,
    required this.sourceId,
    required this.createdAt,
  });

  final int rewardHistoryId;
  final RewardType rewardType;
  final String rewardName;
  final RewardSourceType sourceType;
  final int sourceId;
  final DateTime createdAt;

  static RewardHistory fromJson(Map<String, dynamic> json) => RewardHistory(
        rewardHistoryId: (json['rewardHistoryId'] as num?)?.toInt() ?? 0,
        rewardType: RewardType.fromApiValue(
          json['rewardType'] as String? ?? '',
        ),
        rewardName: json['rewardName'] as String? ?? '',
        sourceType: RewardSourceType.fromApiValue(
          json['sourceType'] as String? ?? '',
        ),
        sourceId: (json['sourceId'] as num?)?.toInt() ?? 0,
        createdAt: _requiredDateTime(json['createdAt']),
      );
}

DateTime _requiredDateTime(Object? value) {
  if (value is! String || value.isEmpty) {
    throw const FormatException('필수 날짜 형식이 올바르지 않습니다.');
  }
  return DateTime.parse(value);
}
