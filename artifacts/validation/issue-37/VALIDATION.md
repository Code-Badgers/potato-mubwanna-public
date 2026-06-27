# Issue 37 Validation

## 작업 목표

- 인증된 사용자 기준 `GET /api/users/me`에서 `userId`, `nickname`, `email`, `profileImage`, `createdAt`을 반환한다.
- Flutter 마이페이지 프로필 닉네임과 아바타를 내 정보 API 응답으로 교체한다.
- 로딩, 실패, 이미지 없음 상태에서도 기존 fallback 프로필을 유지한다.

## 변경 요약

- Backend
  - `user` 도메인에 `UserController`, `UserProfileService`, `UserProfileResponse` 추가.
  - 기존 JWT principal `user:<id>`에서 사용자 ID를 읽어 `UserRepository.findById`로 프로필을 조회.
  - `User.getCreatedAt()` 추가.
- Frontend
  - `UserProfile`, `UserProfileRepository`, `userProfileProvider` 추가.
  - `userProfileProvider`를 `autoDispose`로 전환해 로그아웃 후 다른 계정으로 로그인할 때 이전 프로필 캐시가 재사용되지 않도록 수정.
  - `ApiPaths.myProfile = '/users/me'` 추가.
  - `MyPageScreen`이 provider 값을 사용해 닉네임과 optional 프로필 이미지를 렌더링.
  - provider loading/error 및 빈 `profileImage`에서는 기존 기본 아바타와 `감자여행자` fallback 유지.
- Validation artifacts
  - `artifacts/validation/issue-37/mypage_profile_preview.dart`
  - `artifacts/validation/issue-37/android-mypage-profile.png`

## 실행한 검증

| 명령 | 결과 |
| --- | --- |
| `backend/.gradlew.bat test --tests com.gamjamubwatna.user.application.UserProfileServiceTest` | RED: `UserProfileResponse`, `UserProfileService` 없음으로 컴파일 실패 확인 |
| `backend/.gradlew.bat test --tests com.gamjamubwatna.user.application.UserProfileServiceTest --tests com.gamjamubwatna.user.api.UserControllerTest` | PASS |
| `frontend/flutter test --no-pub test/features/mypage/user_profile_repository_test.dart test/features/mypage/my_page_screen_test.dart` | RED: repository/model/provider 없음으로 컴파일 실패 확인 |
| `frontend/flutter test --no-pub test/features/mypage/user_profile_repository_test.dart test/features/mypage/my_page_screen_test.dart` | PASS, 12 tests |
| `frontend/flutter test --no-pub test/features/mypage/user_profile_controller_test.dart` | RED: 마지막 listener 제거 후에도 프로필 캐시가 유지되어 재조회 횟수가 예상 `2`가 아닌 `1`로 확인됨 |
| `frontend/flutter test --no-pub test/features/mypage/user_profile_controller_test.dart` | PASS, `autoDispose` 적용 후 재진입 시 프로필 재조회 확인 |
| `frontend/flutter test --no-pub test/features/mypage` | PASS, 13 tests |
| `backend/.gradlew.bat test` | PASS |
| `frontend/flutter analyze` | 첫 실행: `prefer_const_constructors` 1건 실패, 수정 후 PASS. 리뷰 반영 후 재실행도 PASS |
| `frontend/flutter test --no-pub` | FAIL: 기존 `test/features/map/map_screen_test.dart`가 `ProviderScope` 없이 `MapScreen`을 렌더링해 실패 |
| `frontend/flutter build apk --debug` | PASS, `frontend/build/app/outputs/flutter-apk/app-debug.apk` 생성 확인 |
| `frontend/flutter run -d emulator-5554 -t ..\artifacts\validation\issue-37\mypage_profile_preview.dart` | PASS, Pixel 7 API 36 emulator에서 preview 실행 |

## Android 캡처

- `android-mypage-profile.png`: 마이페이지가 provider의 `실제 사용자` 닉네임을 렌더링하고, 빈 `profileImage`에서는 기본 아바타를 표시하는 상태를 확인했다.
- 실제 앱 시작 경로는 `/onboarding`이며 로그인 세션 없이 마이페이지로 직접 접근할 수 없어, 기존 validation preview 방식으로 My Page 화면을 검증했다.

## 발생한 문제와 해결

- 기존 My Page 위젯 테스트가 새 `userProfileProvider`를 override하지 않아 실제 Dio 요청 timer가 남았다.
  - 원인: 테스트 환경에서 provider 기본 구현이 `/users/me` 네트워크 요청을 시작함.
  - 해결: My Page 테스트 helper가 기본 profile provider override를 제공하도록 수정.
- `flutter analyze`에서 동적 nickname `Text`의 `TextStyle`에 `const`가 가능하다는 lint가 발생했다.
  - 해결: 해당 `TextStyle`을 `const TextStyle`로 수정.
- PR 리뷰에서 일반 `FutureProvider`가 로그아웃 이후에도 이전 사용자의 프로필을 캐시할 수 있다는 지적이 있었다.
  - 원인: 앱 루트 `ProviderScope`는 로그인 세션보다 오래 유지되고, 로그아웃 과정에서 `userProfileProvider`를 별도로 무효화하지 않음.
  - 해결: `FutureProvider.autoDispose`로 전환하고 마지막 listener 해제 후 재진입 시 API가 다시 호출되는 회귀 테스트를 추가.
- PR 리뷰에서 잘못된 `createdAt`을 `DateTime.tryParse`로 허용하자는 제안은 반영하지 않았다.
  - 판단: 백엔드 응답 타입이 `Instant`로 고정된 첫 번째 파티 API 계약이며, 파싱 실패는 `FutureProvider`의 `AsyncError`와 기존 fallback UI로 처리된다. `null`로 조용히 변환하기보다 계약 위반을 드러내는 엄격한 파싱을 유지한다.

## 남은 리스크

- `flutter test --no-pub` 전체 실패는 #37 변경 범위 밖의 기존 지도 테스트 문제다. 실패 내용은 `MapScreen`이 `ProviderScope` 없이 렌더링되어 `Bad state: No ProviderScope found`가 발생하고, 이어서 지도 홈 텍스트 expectation도 실패한다.
- 실제 인증 세션 기반 API 응답 화면은 테스트 계정/토큰 없이 검증하지 않았다. 대신 repository/widget 테스트와 Android preview로 응답 렌더링 및 fallback 상태를 검증했다.
- debug APK 빌드 중 Flutter가 Kotlin Gradle Plugin migration 경고를 출력했다. 빌드는 성공했으며, 메이저 Flutter 호환성 대응은 별도 빌드/의존성 이슈 범위다.

## 후속 작업

- 별도 이슈에서 `test/features/map/map_screen_test.dart`에 `ProviderScope`와 필요한 provider overrides를 추가해 전체 Flutter 테스트를 회복한다.
- 실제 테스트 계정 또는 mock backend 환경이 준비되면 로그인 세션으로 `/api/users/me` end-to-end 화면을 추가 검증한다.
