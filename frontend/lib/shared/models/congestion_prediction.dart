// 한국 관광지의 예측 날짜는 기기 시간대와 무관하게 한국 날짜로 비교한다.
String koreaDate([DateTime? now]) =>
    (now ?? DateTime.now()).toUtc().add(const Duration(hours: 9))
        .toIso8601String().substring(0, 10);

String currentCongestionLevel(String level, String? date, {DateTime? now}) {
  if (date != koreaDate(now) || !const ['LOW', 'NORMAL', 'HIGH'].contains(level)) {
    return 'UNKNOWN';
  }
  return level;
}

String congestionLabel(String level) => switch (level) {
  'LOW' => '여유',
  'NORMAL' => '보통',
  'HIGH' => '혼잡',
  _ => '정보 없음',
};

String congestionDescription(String level, String? date, String? source) {
  if (level == 'UNKNOWN') return '오늘의 혼잡도 예측 정보가 없어요.';
  final sourceLabel = source == 'TOURISM_CONGESTION_API'
      ? '한국관광공사' : '출처: ${source ?? '미제공'}';
  return '예측 기준일 $date · $sourceLabel\n실시간 현장 혼잡도가 아닌 예측 정보예요.';
}

String? historicalCongestionDescription(
  String? level,
  String? date,
  String? source, {
  DateTime? now,
}
) {
  if (level == null || date == null ||
      !const ['LOW', 'NORMAL', 'HIGH'].contains(level)) {
    return null;
  }
  final today = DateTime.parse('${koreaDate(now)}T00:00:00Z');
  final yesterday = today.subtract(const Duration(days: 1))
      .toIso8601String().substring(0, 10);
  final lastWeek = today.subtract(const Duration(days: 7))
      .toIso8601String().substring(0, 10);
  final dayLabel = date == yesterday
      ? '어제'
      : date == lastWeek
          ? '지난주 같은 요일'
          : null;
  if (dayLabel == null) {
    return null;
  }
  final parsed = DateTime.tryParse(date);
  if (parsed == null) {
    return null;
  }
  final sourceLabel = source == 'TOURISM_CONGESTION_API'
      ? '한국관광공사' : '출처: ${source ?? '미제공'}';
  return '$dayLabel(${parsed.month}월 ${parsed.day}일) 예측: ${congestionLabel(level)} · 참고용\n'
      '$sourceLabel 예측값이며, 실제 혼잡도나 오늘 예측이 아니에요.';
}
