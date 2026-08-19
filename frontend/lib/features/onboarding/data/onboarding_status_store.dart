import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final onboardingStatusStoreProvider = Provider<OnboardingStatusStore>(
  (ref) => const SharedPreferencesOnboardingStatusStore(),
);

abstract interface class OnboardingStatusStore {
  Future<bool> hasCompletedOnboarding();

  Future<void> markOnboardingCompleted();
}

class SharedPreferencesOnboardingStatusStore implements OnboardingStatusStore {
  const SharedPreferencesOnboardingStatusStore();

  static const _completedKey = 'hasCompletedLoginIntroOnboardingV1';

  @override
  Future<bool> hasCompletedOnboarding() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_completedKey) ?? false;
  }

  @override
  Future<void> markOnboardingCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_completedKey, true);
  }
}
