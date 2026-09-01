class NetworkTimeouts {
  const NetworkTimeouts._();

  static const connect = Duration(seconds: 5);
  static const send = Duration(seconds: 8);
  static const receive = Duration(seconds: 10);
}
