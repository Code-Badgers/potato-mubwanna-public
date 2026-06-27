import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/mypage/application/user_profile_controller.dart';
import 'package:potato_mubwanna/features/mypage/data/user_profile_repository.dart';
import 'package:potato_mubwanna/features/mypage/domain/user_profile.dart';

void main() {
  test('refetches the profile after the last listener is removed', () async {
    final repository = _CountingUserProfileRepository();
    final container = ProviderContainer(
      overrides: [
        userProfileRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final firstSubscription = container.listen(
      userProfileProvider,
      (_, __) {},
    );
    await container.read(userProfileProvider.future);
    expect(repository.fetchCount, 1);

    firstSubscription.close();
    await container.pump();

    final secondSubscription = container.listen(
      userProfileProvider,
      (_, __) {},
    );
    addTearDown(secondSubscription.close);
    await container.read(userProfileProvider.future);

    expect(repository.fetchCount, 2);
  });
}

class _CountingUserProfileRepository extends UserProfileRepository {
  _CountingUserProfileRepository() : super(dio: Dio());

  int fetchCount = 0;

  @override
  Future<UserProfile> fetchProfile() async {
    fetchCount++;
    return UserProfile(
      userId: fetchCount,
      nickname: '사용자 $fetchCount',
      email: 'user$fetchCount@example.com',
      profileImage: '',
      createdAt: null,
    );
  }
}
