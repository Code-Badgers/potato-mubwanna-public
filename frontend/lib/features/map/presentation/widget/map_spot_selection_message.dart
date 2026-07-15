String? mapSpotIdFromSelectionMessage(Object? message) {
  final rawSpotId = switch (message) {
    {'spotId': final Object spotId} => spotId.toString(),
    String value => value,
    _ => null,
  };
  final spotId = rawSpotId?.trim();
  if (spotId == null || spotId.isEmpty) {
    return null;
  }
  return spotId;
}
