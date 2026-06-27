# My Page Profile API Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Return the authenticated user's stored profile and render it in My Page.

**Architecture:** A small backend profile service parses the existing `user:<id>` JWT principal and returns a DTO from `UserRepository`. Flutter fetches that DTO through the existing authenticated Dio client and exposes it with a Riverpod `FutureProvider`; the My Page profile widget keeps its current fallback presentation while loading or on failure.

**Tech Stack:** Spring Boot, Spring Security, JPA, JUnit 5, Flutter, Riverpod, Dio, flutter_test.

---

### Task 1: Backend authenticated profile endpoint

**Files:**
- Create: `backend/src/main/java/com/gamjamubwatna/user/api/UserProfileResponse.java`
- Create: `backend/src/main/java/com/gamjamubwatna/user/api/UserController.java`
- Create: `backend/src/main/java/com/gamjamubwatna/user/application/UserProfileService.java`
- Create: `backend/src/test/java/com/gamjamubwatna/user/application/UserProfileServiceTest.java`
- Modify: `backend/src/main/java/com/gamjamubwatna/auth/domain/UserRepository.java`

- [ ] **Step 1: Write the failing service tests**

```java
@Test
void returnsProfileForAuthenticatedUserId() {
    UserProfileResponse profile = service.getProfile(1L);
    assertThat(profile.nickname()).isEqualTo("감자러버");
}

@Test
void rejectsUnknownUserId() {
    assertThatThrownBy(() -> service.getProfile(99L))
        .isInstanceOf(IllegalArgumentException.class);
}
```

- [ ] **Step 2: Run the service test to verify RED**

Run: `./gradlew.bat test --tests com.gamjamubwatna.user.application.UserProfileServiceTest`

Expected: FAIL because the profile service and DTO do not exist.

- [ ] **Step 3: Implement the endpoint**

```java
@GetMapping("/me")
public AuthApiResponse<UserProfileResponse> getMyProfile(Authentication authentication) {
    return AuthApiResponse.success(userProfileService.getProfile(userId(authentication)));
}
```

The controller accepts only the existing `user:<id>` principal, and the service reads `UserRepository.findById`. The response contains `userId`, `nickname`, `email`, `profileImage`, and `createdAt` only.

- [ ] **Step 4: Run the service test to verify GREEN**

Run: `./gradlew.bat test --tests com.gamjamubwatna.user.application.UserProfileServiceTest`

Expected: PASS with two tests.

### Task 2: Flutter profile data provider and screen rendering

**Files:**
- Create: `frontend/lib/features/mypage/domain/user_profile.dart`
- Create: `frontend/lib/features/mypage/data/user_profile_repository.dart`
- Create: `frontend/lib/features/mypage/application/user_profile_controller.dart`
- Modify: `frontend/lib/core/constants/api_paths.dart`
- Modify: `frontend/lib/features/mypage/presentation/screen/my_page_screen.dart`
- Create: `frontend/test/features/mypage/user_profile_repository_test.dart`
- Modify: `frontend/test/features/mypage/my_page_screen_test.dart`

- [ ] **Step 1: Write failing repository and widget tests**

```dart
test('fetches the authenticated user profile', () async {
  final profile = await repository.fetchProfile();
  expect(profile.nickname, '감자러버');
});

testWidgets('renders the fetched nickname in the profile summary', (tester) async {
  await tester.pumpWidget(profileTestApp(const UserProfile(nickname: '실제 사용자')));
  expect(find.text('실제 사용자'), findsOneWidget);
});
```

- [ ] **Step 2: Run the new Flutter tests to verify RED**

Run: `flutter test --no-pub test/features/mypage/user_profile_repository_test.dart test/features/mypage/my_page_screen_test.dart`

Expected: FAIL because `UserProfile`, repository, provider, and injected screen data are absent.

- [ ] **Step 3: Implement the minimum Flutter flow**

```dart
final userProfileProvider = FutureProvider<UserProfile>(
  (ref) => ref.watch(userProfileRepositoryProvider).fetchProfile(),
);
```

Add `ApiPaths.myProfile = '/users/me'`. `MyPageScreen` watches the provider and passes the API nickname and non-empty image URL to `_ProfileSummary`; loading/error and an absent image retain the current default avatar and `감자여행자` fallback.

- [ ] **Step 4: Run the focused Flutter tests to verify GREEN**

Run: `flutter test --no-pub test/features/mypage/user_profile_repository_test.dart test/features/mypage/my_page_screen_test.dart`

Expected: PASS.

### Task 3: Team A verification and delivery

**Files:**
- Create: `artifacts/validation/issue-37/VALIDATION.md`

- [ ] **Step 1: Run scoped verification**

Run: `./gradlew.bat test`, `flutter analyze`, and the focused My Page Flutter tests.

Expected: backend tests, analyzer, and focused Team A tests pass.

- [ ] **Step 2: Record known external test failure**

Record that the pre-existing `test/features/map/map_screen_test.dart` failure is caused by a missing `ProviderScope`, is outside #37, and remains unchanged.

- [ ] **Step 3: Build and capture Android evidence**

Run: `flutter build apk --debug`, install the debug APK on the Pixel 7 API 36 emulator, and capture the My Page fallback or authenticated profile state without exposing credentials.

- [ ] **Step 4: Commit and push**

```bash
git add backend frontend artifacts/validation/issue-37 docs/superpowers
git commit -m "[FE/BE] feat(mypage): 내 정보 API와 프로필 연동 (#37)"
git push
```

## Plan Review

- Scope covers the profile endpoint, client rendering, fallbacks, and verification required by #37.
- The plan excludes activity aggregates and all Team B files.
- The backend principal format, endpoint path, DTO fields, Flutter provider name, and test commands are consistent with the current codebase.
