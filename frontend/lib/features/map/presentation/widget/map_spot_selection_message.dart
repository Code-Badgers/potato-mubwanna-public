String? mapSpotIdFromSelectionMessage(Object? message) {
  final rawSpotId = switch (message) {
    Map<Object?, Object?> payload => _spotIdFromPayload(payload),
    String value => value,
    num value => value.toString(),
    _ => null,
  };
  final spotId = rawSpotId?.trim();
  if (spotId == null || spotId.isEmpty) {
    return null;
  }
  return _normalizeSpotId(spotId);
}

String? _spotIdFromPayload(Map<Object?, Object?> payload) {
  final value = payload['spotId'] ??
      payload['spotID'] ??
      payload['id'] ??
      payload['poiID'];
  return value?.toString();
}

String _normalizeSpotId(String value) {
  var spotId = value.trim();
  if (spotId.startsWith('potato-')) {
    spotId = spotId.substring('potato-'.length);
  }
  if (spotId.endsWith('.0')) {
    spotId = spotId.substring(0, spotId.length - 2);
  }
  return spotId;
}
