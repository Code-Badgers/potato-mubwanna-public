class UserActivitySummary {
  const UserActivitySummary({
    required this.totalSteps,
    required this.stampCount,
    required this.ownedPotatoCount,
  });

  static const empty = UserActivitySummary(
    totalSteps: 0,
    stampCount: 0,
    ownedPotatoCount: 0,
  );

  final int totalSteps;
  final int stampCount;
  final int ownedPotatoCount;

  static UserActivitySummary fromJson(Object? json) {
    final data = json as Map<String, dynamic>? ?? const <String, dynamic>{};
    return UserActivitySummary(
      totalSteps: (data['totalSteps'] as num?)?.toInt() ?? 0,
      stampCount: (data['stampCount'] as num?)?.toInt() ?? 0,
      ownedPotatoCount: (data['ownedPotatoCount'] as num?)?.toInt() ?? 0,
    );
  }
}
