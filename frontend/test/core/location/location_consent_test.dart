import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/location/location_service.dart';

void main() {
  test('blocks device location access before personal location consent',
      () async {
    final service = LocationService(
      hasPersonalLocationConsent: () async => false,
    );

    await expectLater(
      service.getCurrentPosition(),
      throwsA(
        isA<LocationFailure>()
            .having(
              (failure) => failure.type,
              'type',
              LocationFailureType.consentRequired,
            )
            .having((failure) => failure.actionLabel, 'action', '동의하기'),
      ),
    );
  });
}
