import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

abstract final class AppLogger {
  const AppLogger._();

  static void debug(String message, {String name = 'app'}) {
    if (!kDebugMode) {
      return;
    }
    developer.log(message, name: name);
  }
}
