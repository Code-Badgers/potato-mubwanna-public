import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/app/config/app_environment.dart';

void main() {
  test('uses the deployed API when no endpoint is injected', () {
    expect(
      AppEnvironment.apiBaseUrl,
      'https://potato-mubwanna.duckdns.org/api',
    );
  });
}
