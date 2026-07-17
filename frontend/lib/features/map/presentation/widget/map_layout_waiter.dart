Future<bool> waitForMapLayout({
  required bool Function() hasLayout,
  required bool Function() shouldContinue,
  Duration retryInterval = const Duration(milliseconds: 50),
  int maxAttempts = 40,
}) async {
  for (var attempt = 0; attempt < maxAttempts; attempt += 1) {
    if (!shouldContinue()) {
      return false;
    }
    if (hasLayout()) {
      return true;
    }
    if (attempt < maxAttempts - 1) {
      await Future<void>.delayed(retryInterval);
    }
  }
  return false;
}
