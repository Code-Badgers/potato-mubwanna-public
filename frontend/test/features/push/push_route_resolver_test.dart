import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/push/domain/push_message.dart';

void main() {
  test('resolves every whitelisted list destination', () {
    expect(
      PushRouteResolver.resolve({'destination': 'MISSIONS'}),
      '/main/missions',
    );
    expect(PushRouteResolver.resolve({'destination': 'COUPONS'}), '/coupons');
    expect(
      PushRouteResolver.resolve({'destination': 'STAMPS'}),
      '/main/stamps',
    );
    expect(
      PushRouteResolver.resolve({'destination': 'POTATOES'}),
      '/main/potatoes',
    );
    expect(PushRouteResolver.resolve({'destination': 'MAP'}), '/main/map');
  });

  test('resolves a positive spot id', () {
    expect(
      PushRouteResolver.resolve({'destination': 'SPOT', 'destinationId': '17'}),
      '/spots/17',
    );
  });

  test('ignores unknown or malformed destinations', () {
    expect(PushRouteResolver.resolve({'destination': 'ADMIN'}), isNull);
    expect(
      PushRouteResolver.resolve({
        'destination': 'SPOT',
        'destinationId': '../settings',
      }),
      isNull,
    );
    expect(
      PushRouteResolver.resolve({'destination': 'SPOT', 'destinationId': '0'}),
      isNull,
    );
  });
}
