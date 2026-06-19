class KakaoLoginUnsupportedException implements Exception {
  const KakaoLoginUnsupportedException(this.message);

  final String message;

  @override
  String toString() => message;
}
