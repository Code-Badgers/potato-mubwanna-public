class PushMessage {
  const PushMessage({
    required this.title,
    required this.body,
    required this.data,
  });

  final String? title;
  final String? body;
  final Map<String, String> data;

  bool get hasDisplayContent =>
      title != null && title!.isNotEmpty || body != null && body!.isNotEmpty;
}

class PushRouteResolver {
  const PushRouteResolver._();

  static String? resolve(Map<String, String> data) {
    return switch (data['destination']) {
      'MISSIONS' => '/main/missions',
      'COUPONS' => '/coupons',
      'STAMPS' => '/main/stamps',
      'MAP' => '/main/map',
      'SPOT' => _spotRoute(data['destinationId']),
      _ => null,
    };
  }

  static String? _spotRoute(String? value) {
    final spotId = int.tryParse(value ?? '');
    if (spotId == null || spotId < 1) {
      return null;
    }
    return '/spots/$spotId';
  }
}
