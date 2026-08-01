# Issue #192 Validation

## 작업 목표

- 일일 활동 동기화 응답에 서버가 확정한 대표 감자 성장 결과를 추가한다.
- 레벨업이 발생하면 최신 도감 조회 후 사용자에게 한 번만 성장 결과를 안내한다.
- 레벨 5 도달은 일반 레벨업과 구분해 완전 성장으로 안내한다.
- 기존 동기화 실패 fallback, API 요청 형식, DB schema를 유지한다.

## 구현 결과

### Backend

- `PotatoDailyActivitySyncResponse`에 nullable `growthResult`를 추가했다.
- 성장 전후 레벨, 감자 식별자/이름, 레벨업 여부, 완전 성장 여부를 반환한다.
- 동일·감소 스냅샷, 대표 감자 없음, 이미 완전 성장한 감자는 `growthResult=null`을 반환한다.
- 단위 테스트와 H2/Flyway 통합 테스트에서 진행도 증가, 단일/다단계 레벨업, 완전 성장, 중복 방지를 검증했다.

### Frontend

- 활동 동기화 응답을 구조화해 `PotatoGrowthResult`로 파싱한다.
- 공유 동기화 provider가 성장 결과를 도감 화면에 전달한다.
- 최신 도감 조회가 끝난 뒤 레벨업 다이얼로그를 한 번만 표시한다.
- 일반 레벨업과 최종 성장 단계의 아이콘, 색상, 문구를 구분했다.
- 동기화 실패나 레벨 변화가 없는 경우 기존 도감 진입 흐름을 유지한다.

## API / DB / 환경 영향

- API: `PUT /api/potatoes/me/activity/daily` 응답에 nullable `growthResult` 추가
- Request: 변경 없음
- 기존 Response 필드: 변경 없음
- DB migration: 없음
- 환경 변수: 없음
- 외부 API: 없음

## 검증 과정과 문제 해결

1. 구현 전에 백엔드·프론트 계약 테스트를 추가했다.
2. 첫 백엔드 테스트는 `PotatoGrowthResultResponse`와 `growthResult()`가 없어 컴파일 실패했다. 응답 DTO와 서비스 결과 계산을 구현한 뒤 통과했다.
3. 새 worktree의 첫 Flutter 테스트는 `.dart_tool` 의존성 정보가 없어 실행되지 않았다. `flutter pub get`으로 기존 lockfile 기준 의존성을 준비했다.
4. 다음 Flutter 테스트는 `PotatoGrowthResult`와 provider 반환값이 없어 컴파일 실패했다. 도메인 파서, repository, provider를 구현한 뒤 통과했다.
5. widget golden 캡처는 테스트 환경에 한국어 폰트가 없어 글자가 사각형으로 표시됐다. golden은 폐기하고 API 36 에뮬레이터에서 임시 preview entrypoint로 실제 폰트 렌더링을 확인했다.
6. 에뮬레이터 캡처 후 임시 preview entrypoint를 삭제하고 화면 테스트를 다시 통과시켰다.

## 실행 명령과 결과

### Backend

- `.\\gradlew.bat test --tests "com.gamjamubwatna.potato.application.PotatoCommandServiceTest" --tests "com.gamjamubwatna.potato.api.PotatoControllerTest"`
  - 최초: 예상한 컴파일 실패
  - 구현 후: 성공
- `.\\gradlew.bat test --tests "com.gamjamubwatna.potato.*"`
  - 성공
- `.\\gradlew.bat clean test`, 이후 `.\\gradlew.bat test`
  - 성공, 최종 357 tests, failures 0
- `.\\gradlew.bat build -x test`
  - 성공

### Frontend

- `flutter pub get`
  - 성공
- `flutter test --no-pub test/features/potato/potato_collection_controller_test.dart test/features/potato/potato_collection_screen_test.dart`
  - 최초: 예상한 컴파일 실패
  - 구현 후: 13 tests 통과
- `flutter analyze --no-fatal-infos --no-pub`
  - No issues found
- `flutter test --no-pub`
  - 211 tests 통과
- `flutter build apk --debug --no-pub`
  - 성공, `build/app/outputs/flutter-apk/app-debug.apk`
  - 외부 플러그인의 기존 KGP 적용 경고와 Java 8 target 경고가 남아 있다.
- `flutter test --no-pub test/features/potato/potato_collection_screen_test.dart`
  - 임시 preview 제거 후 8 tests 재통과

### Android API 36 화면 검증

- `flutter run -d emulator-5554 -t lib/growth_feedback_preview.dart --no-pub`
  - 검증용 provider 데이터로 레벨 2에서 3으로 성장한 상태를 실행했다.
  - `topResumedActivity`가 `com.gamjamubwatna.frontend/.MainActivity`임을 확인했다.
- `potato-growth-feedback-api36.png`
  - 한국어 문구, 아이콘, 레벨 변화, 확인 버튼이 정상 렌더링됐다.
  - 다이얼로그와 대표 감자 카드, 희귀도 필터, 시스템 영역 사이에 겹침이나 잘림이 없었다.

## 변경 파일 요약

- `agents_docs/07_api_specification.md`
- `backend/src/main/java/com/gamjamubwatna/potato/api/PotatoDailyActivitySyncResponse.java`
- `backend/src/main/java/com/gamjamubwatna/potato/api/PotatoGrowthResultResponse.java`
- `backend/src/main/java/com/gamjamubwatna/potato/application/PotatoCommandService.java`
- `backend/src/test/java/com/gamjamubwatna/potato/**`
- `frontend/lib/features/potato/**`
- `frontend/test/features/potato/**`

## 남은 리스크

- 실제 로그인 계정과 HealthKit/Health Connect 데이터로 레벨업을 발생시키는 실기기 종단 간 검증은 수행하지 않았다.
- 응답의 추가 필드는 하위 호환이지만 배포 시 백엔드를 먼저 배포해야 새 프론트가 성장 피드백을 받을 수 있다. 백엔드가 이전 버전이면 프론트는 `growthResult=null`로 처리해 도감 자체는 정상 동작한다.
- APK 빌드의 외부 플러그인 KGP/Java 8 경고는 이번 이슈 범위 밖이며 빌드 결과에는 영향을 주지 않았다.

## 후속 작업

- Firebase 자격 증명과 Android/iOS 실기기가 준비되면 #176 FCM 수신 QA를 완료한다.
- 실제 HealthKit/Health Connect 계정으로 일반 레벨업과 레벨 5 완전 성장 흐름을 각각 한 번 검증한다.
