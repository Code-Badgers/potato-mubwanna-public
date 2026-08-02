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
  if (spotId.startsWith('potato-')) {
    return spotId.substring('potato-'.length);
  }
  return spotId;
}

String? _spotIdFromPayload(Map<Object?, Object?> payload) {
  final value = payload['spotId'] ??
      payload['spotID'] ??
      payload['id'] ??
      payload['poiID'];
  return value?.toString();
}
