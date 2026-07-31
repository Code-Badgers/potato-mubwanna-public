import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/app/router/session_startup_route_gate.dart';

void main() {
  test('holds a deep link until authenticated startup completes', () {
    final gate = SessionStartupRouteGate();

    expect(gate.redirectBeforeSessionStartup('/coupons'), '/startup');
    expect(
      gate.completeSessionStartup(
        fallbackRoute: '/main/map',
        isAuthenticated: true,
      ),
      '/coupons',
    );
    expect(gate.redirectBeforeSessionStartup('/main/stamps'), isNull);
  });

  test('drops a protected deep link when startup remains signed out', () {
    final gate = SessionStartupRouteGate();

    expect(gate.redirectBeforeSessionStartup('/spots/12'), '/startup');
    expect(
      gate.completeSessionStartup(
        fallbackRoute: '/login',
        isAuthenticated: false,
      ),
      '/login',
    );
  });

  test('allows the startup screen without creating a redirect loop', () {
    final gate = SessionStartupRouteGate();

    expect(gate.redirectBeforeSessionStartup('/startup'), isNull);
    expect(gate.redirectBeforeSessionStartup('/startup?source=push'), isNull);
  });

  test('rejects an external pending location', () {
    final gate = SessionStartupRouteGate();

    expect(
      gate.redirectBeforeSessionStartup('https://example.com/coupons'),
      '/startup',
    );
    expect(
      gate.completeSessionStartup(
        fallbackRoute: '/main/map',
        isAuthenticated: true,
      ),
      '/main/map',
    );
  });

  test('rejects unknown and signed-out-only destinations', () {
    for (final location in ['/unknown', '/login', '/onboarding']) {
      final gate = SessionStartupRouteGate();

      expect(gate.redirectBeforeSessionStartup(location), '/startup');
      expect(
        gate.completeSessionStartup(
          fallbackRoute: '/main/map',
          isAuthenticated: true,
        ),
        '/main/map',
      );
    }
  });
}
