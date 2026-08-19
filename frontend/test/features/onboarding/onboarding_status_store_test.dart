import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/onboarding/data/onboarding_status_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('uses a versioned key for the login intro onboarding', () async {
    SharedPreferences.setMockInitialValues({
      'hasCompletedOnboarding': true,
    });

    const store = SharedPreferencesOnboardingStatusStore();

    expect(await store.hasCompletedOnboarding(), isFalse);

    await store.markOnboardingCompleted();

    expect(await store.hasCompletedOnboarding(), isTrue);
  });
}
