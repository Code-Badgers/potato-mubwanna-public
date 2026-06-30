# Stamp Rallybook API Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 로그인 사용자의 18개 시군 스탬프 진행률과 6·12·18 다음 보상 기준을 백엔드 API와 Flutter 랠리북 화면에 연결한다.

**Architecture:** Flyway가 18개 기준 스탬프와 사용자 획득 관계를 만든다. Spring 서비스가 기준 목록과 사용자 획득 행을 조합하고 보상 경계를 계산하며, Flutter Repository와 인증 상태 연동 FutureProvider가 두 API를 화면 모델로 합친다.

**Tech Stack:** Java 21, Spring Boot 3.5, Spring Data JPA, Flyway, PostgreSQL/H2, Flutter, Riverpod 2, Dio, JUnit 5, MockMvc, flutter_test

---

### Task 1: 스탬프 스키마와 도메인 모델

**Files:**
- Create: `backend/src/main/resources/db/migration/V4__create_stamps.sql`
- Create: `backend/src/main/java/com/gamjamubwatna/stamp/domain/Stamp.java`
- Create: `backend/src/main/java/com/gamjamubwatna/stamp/domain/UserStamp.java`
- Create: `backend/src/main/java/com/gamjamubwatna/stamp/domain/StampRepository.java`
- Create: `backend/src/main/java/com/gamjamubwatna/stamp/domain/UserStampRepository.java`
- Test: `backend/src/test/java/com/gamjamubwatna/stamp/domain/StampMigrationTest.java`

- [ ] **Step 1: 18개 기준 데이터와 유일 제약을 검증하는 실패 테스트 작성**

```java
@SpringBootTest(properties = {
    "spring.datasource.url=jdbc:h2:mem:stamp_migration;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE",
    "spring.jpa.hibernate.ddl-auto=validate"
})
class StampMigrationTest {
    @Autowired StampRepository stampRepository;

    @Test
    void seedsEighteenGangwonStampsInDisplayOrder() {
        List<Stamp> stamps = stampRepository.findAllByOrderByDisplayOrderAsc();
        assertThat(stamps).hasSize(18);
        assertThat(stamps.getFirst().getCityName()).isEqualTo("강릉시");
        assertThat(stamps.getLast().getCityName()).isEqualTo("철원군");
    }
}
```

- [ ] **Step 2: RED 확인**

Run: `cd backend && .\gradlew.bat test --tests "com.gamjamubwatna.stamp.domain.StampMigrationTest" --rerun-tasks`

Expected: `StampRepository`와 migration이 없어 컴파일 또는 컨텍스트 시작 실패.

- [ ] **Step 3: migration과 최소 JPA 모델 구현**

```sql
CREATE TABLE stamps (
    stamp_id BIGSERIAL PRIMARY KEY,
    city_name VARCHAR(100) NOT NULL UNIQUE,
    stamp_name VARCHAR(100) NOT NULL,
    stamp_image VARCHAR(500),
    display_order INTEGER NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE user_stamps (
    user_stamp_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    stamp_id BIGINT NOT NULL REFERENCES stamps(stamp_id),
    tourist_spot_id BIGINT NOT NULL REFERENCES tourist_spots(tourist_spot_id),
    acquired_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT uk_user_stamps_user_stamp UNIQUE (user_id, stamp_id)
);
```

`Stamp`는 `id`, `cityName`, `stampName`, `stampImage`, `displayOrder` getter를 제공한다. `UserStamp`는 `User`, `Stamp`, `TouristSpot`, `acquiredAt`을 `LAZY` 관계로 매핑한다. Repository는 다음 메서드를 제공한다.

```java
List<Stamp> findAllByOrderByDisplayOrderAsc();

@Query("""
    SELECT userStamp FROM UserStamp userStamp
    JOIN FETCH userStamp.stamp
    WHERE userStamp.user.id = :userId
    """)
List<UserStamp> findByUserIdWithStamp(@Param("userId") Long userId);
```

- [ ] **Step 4: GREEN 확인**

Run: `cd backend && .\gradlew.bat test --tests "com.gamjamubwatna.stamp.domain.StampMigrationTest" --rerun-tasks`

Expected: 18개 기준 데이터 테스트 통과.

- [ ] **Step 5: Task 1 커밋**

```powershell
git add backend/src/main/resources/db/migration/V4__create_stamps.sql backend/src/main/java/com/gamjamubwatna/stamp/domain backend/src/test/java/com/gamjamubwatna/stamp/domain/StampMigrationTest.java
git commit -m "[BE] feat(stamp): 스탬프 기준 데이터 모델 추가 (#43)"
```

### Task 2: 조회 서비스와 다음 보상 정책

**Files:**
- Create: `backend/src/main/java/com/gamjamubwatna/stamp/api/StampItemResponse.java`
- Create: `backend/src/main/java/com/gamjamubwatna/stamp/api/StampBookResponse.java`
- Create: `backend/src/main/java/com/gamjamubwatna/stamp/api/StampRewardStatusResponse.java`
- Create: `backend/src/main/java/com/gamjamubwatna/stamp/application/StampQueryService.java`
- Test: `backend/src/test/java/com/gamjamubwatna/stamp/application/StampQueryServiceTest.java`

- [ ] **Step 1: 목록 조합과 6·12·18 경계 실패 테스트 작성**

```java
@Test
void returnsAllStampsWithUserAcquisitionState() {
    when(stampRepository.findAllByOrderByDisplayOrderAsc()).thenReturn(stamps);
    when(userStampRepository.findByUserIdWithStamp(1L)).thenReturn(List.of(acquired));

    StampBookResponse result = service.getStampBook(1L);

    assertThat(result.totalCount()).isEqualTo(18);
    assertThat(result.acquiredCount()).isEqualTo(1);
    assertThat(result.stamps().getFirst().acquired()).isTrue();
}

@ParameterizedTest
@CsvSource({"0,6,6,false", "6,12,6,false", "12,18,6,false", "18,,0,true"})
void calculatesNextRewardBoundary(int acquired, Integer target, int remaining, boolean completed) {
    StampRewardStatusResponse result = service.rewardStatus(acquired);
    assertThat(result.nextTargetCount()).isEqualTo(target);
    assertThat(result.remainingCount()).isEqualTo(remaining);
    assertThat(result.completed()).isEqualTo(completed);
}
```

- [ ] **Step 2: RED 확인**

Run: `cd backend && .\gradlew.bat test --tests "com.gamjamubwatna.stamp.application.StampQueryServiceTest" --rerun-tasks`

Expected: 서비스와 응답 DTO가 없어 컴파일 실패.

- [ ] **Step 3: 최소 조회·보상 계산 구현**

```java
private static final List<Integer> REWARD_TARGETS = List.of(6, 12, 18);

public StampBookResponse getStampBook(Long userId) {
    List<Stamp> stamps = stampRepository.findAllByOrderByDisplayOrderAsc();
    Map<Long, UserStamp> acquiredByStampId = userStampRepository
        .findByUserIdWithStamp(userId)
        .stream()
        .collect(Collectors.toMap(value -> value.getStamp().getId(), Function.identity()));
    List<StampItemResponse> items = stamps.stream()
        .map(stamp -> StampItemResponse.from(stamp, acquiredByStampId.get(stamp.getId())))
        .toList();
    return new StampBookResponse(items.size(), (int) items.stream().filter(StampItemResponse::acquired).count(), items);
}

public StampRewardStatusResponse getRewardStatus(Long userId) {
    int acquired = userStampRepository.countByUserId(userId);
    Integer target = REWARD_TARGETS.stream().filter(value -> value > acquired).findFirst().orElse(null);
    return new StampRewardStatusResponse(acquired, target, target == null ? 0 : target - acquired, target == null);
}
```

- [ ] **Step 4: GREEN 확인**

Run: `cd backend && .\gradlew.bat test --tests "com.gamjamubwatna.stamp.application.StampQueryServiceTest" --rerun-tasks`

Expected: 목록 조합 및 보상 경계 테스트 통과.

- [ ] **Step 5: Task 2 커밋**

```powershell
git add backend/src/main/java/com/gamjamubwatna/stamp backend/src/test/java/com/gamjamubwatna/stamp/application
git commit -m "[BE] feat(stamp): 랠리북 조회와 보상 정책 구현 (#43)"
```

### Task 3: 인증된 Stamp API

**Files:**
- Create: `backend/src/main/java/com/gamjamubwatna/stamp/api/StampController.java`
- Test: `backend/src/test/java/com/gamjamubwatna/stamp/api/StampControllerTest.java`
- Test: `backend/src/test/java/com/gamjamubwatna/stamp/api/StampControllerSecurityTest.java`

- [ ] **Step 1: API 계약 실패 테스트 작성**

```java
mockMvc.perform(get("/stamps/me").with(user("user:1")))
    .andExpect(status().isOk())
    .andExpect(jsonPath("$.success").value(true))
    .andExpect(jsonPath("$.data.totalCount").value(18));

mockMvc.perform(get("/stamps/rewards/check").with(user("user:1")))
    .andExpect(status().isOk())
    .andExpect(jsonPath("$.data.nextTargetCount").value(12));
```

Security Filter Chain 테스트는 토큰 누락 시 두 API가 401인지 검증한다.

- [ ] **Step 2: RED 확인**

Run: `cd backend && .\gradlew.bat test --tests "com.gamjamubwatna.stamp.api.*" --rerun-tasks`

Expected: `/stamps/...` 매핑이 없어 404 또는 컴파일 실패.

- [ ] **Step 3: 컨트롤러 구현**

```java
@RestController
@RequestMapping("/stamps")
public class StampController {
    @GetMapping("/me")
    public AuthApiResponse<StampBookResponse> getMyStamps(Authentication authentication) {
        return AuthApiResponse.success(stampQueryService.getStampBook(userId(authentication)));
    }

    @GetMapping("/rewards/check")
    public AuthApiResponse<StampRewardStatusResponse> getRewardStatus(Authentication authentication) {
        return AuthApiResponse.success(stampQueryService.getRewardStatus(userId(authentication)));
    }
}
```

`userId`는 `^user:([1-9]\\d*)$`를 검증하고 잘못된 principal은 공통 401 형태로 반환한다. 예상하지 못한 서비스 예외는 숨기지 않는다.

- [ ] **Step 4: GREEN과 백엔드 전체 회귀 확인**

Run: `cd backend && .\gradlew.bat test --rerun-tasks`

Expected: 전체 백엔드 테스트 통과.

- [ ] **Step 5: Task 3 커밋**

```powershell
git add backend/src/main/java/com/gamjamubwatna/stamp/api backend/src/test/java/com/gamjamubwatna/stamp/api
git commit -m "[BE] feat(stamp): 인증된 랠리북 API 추가 (#43)"
```

### Task 4: Flutter 데이터 계층과 인증 연동 Provider

**Files:**
- Create: `frontend/lib/features/stamp/domain/stamp_book.dart`
- Create: `frontend/lib/features/stamp/data/stamp_repository.dart`
- Create: `frontend/lib/features/stamp/application/stamp_book_controller.dart`
- Modify: `frontend/lib/core/constants/api_paths.dart`
- Test: `frontend/test/features/stamp/stamp_repository_test.dart`
- Test: `frontend/test/features/stamp/stamp_book_controller_test.dart`

- [ ] **Step 1: JSON 파싱과 세션 전환 실패 테스트 작성**

```dart
test('parses stamp book and reward responses', () async {
  final result = await repository.fetchStampBook();
  expect(result.progress.totalCount, 18);
  expect(result.progress.acquiredCount, 8);
  expect(result.nextReward.nextTargetCount, 12);
});

test('does not fetch while logged out and refetches for the next session', () async {
  expect(await container.read(stampBookProvider.future), isNull);
  await authController.refreshSession();
  await container.pump();
  expect((await container.read(stampBookProvider.future))?.progress.acquiredCount, 1);
  await authController.logout();
  await authController.refreshSession();
  await container.pump();
  expect((await container.read(stampBookProvider.future))?.progress.acquiredCount, 2);
});
```

- [ ] **Step 2: RED 확인**

Run: `cd frontend && flutter test test/features/stamp/stamp_repository_test.dart test/features/stamp/stamp_book_controller_test.dart`

Expected: 모델, Repository, Provider가 없어 컴파일 실패.

- [ ] **Step 3: 모델, Repository, Provider 구현**

```dart
final stampBookProvider = FutureProvider.autoDispose<StampBook?>(
  (ref) async {
    final status = ref.watch(authControllerProvider.select((value) => value.status));
    if (status != AuthStatus.authenticated) return null;
    return ref.watch(stampRepositoryProvider).fetchStampBook();
  },
);
```

Repository는 `Future.wait`로 `ApiPaths.myStamps`와 `ApiPaths.stampRewardCheck`를 호출하고, 공통 `ApiResponse` 실패 시 한국어 기본 메시지의 `ApiException`을 던진다.

- [ ] **Step 4: GREEN 확인**

Run: `cd frontend && flutter test test/features/stamp/stamp_repository_test.dart test/features/stamp/stamp_book_controller_test.dart`

Expected: Repository 및 인증 세션 수명주기 테스트 통과.

- [ ] **Step 5: Task 4 커밋**

```powershell
git add frontend/lib/core/constants/api_paths.dart frontend/lib/features/stamp/domain frontend/lib/features/stamp/data frontend/lib/features/stamp/application frontend/test/features/stamp
git commit -m "[FE] feat(stamp): 랠리북 데이터 계층 연동 (#43)"
```

### Task 5: 랠리북 화면 상태 UI

**Files:**
- Modify: `frontend/lib/features/stamp/presentation/screen/stamp_book_screen.dart`
- Modify: `frontend/test/features/stamp/stamp_book_screen_test.dart`

- [ ] **Step 1: 실제 데이터·로딩·오류·완주 실패 테스트 작성**

```dart
await tester.pumpWidget(ProviderScope(
  overrides: [stampBookProvider.overrideWith((ref) async => fixture)],
  child: const MaterialApp(home: StampBookScreen()),
));
await tester.pumpAndSettle();
expect(find.text('8 / 18'), findsOneWidget);
expect(find.text('12개 달성까지 4개 남았어요'), findsOneWidget);

expect(find.byType(CircularProgressIndicator), findsOneWidget);
expect(find.text('랠리북을 불러오지 못했습니다.'), findsOneWidget);
expect(find.text('다시 시도'), findsOneWidget);
expect(find.text('18개 시군 랠리를 모두 완주했어요.'), findsOneWidget);
```

- [ ] **Step 2: RED 확인**

Run: `cd frontend && flutter test test/features/stamp/stamp_book_screen_test.dart`

Expected: 화면이 Provider를 소비하지 않아 fixture, loading, error 테스트 실패.

- [ ] **Step 3: 화면을 ConsumerWidget과 상태별 본문으로 전환**

```dart
class StampBookScreen extends ConsumerWidget {
  const StampBookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(stampBookProvider);
    return Scaffold(
      body: SafeArea(
        child: value.when(
          data: (book) => book == null ? const _SignedOutState() : _StampBookBody(book: book),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _StampBookError(onRetry: () => ref.invalidate(stampBookProvider)),
        ),
      ),
    );
  }
}
```

기존 카드와 그리드 스타일은 유지하고, 정적 `_stamps`, `acquiredCount`, `nextRewardTarget`만 도메인 모델 값으로 교체한다.

- [ ] **Step 4: GREEN과 Flutter 정적 검증**

Run: `cd frontend && dart format lib/features/stamp test/features/stamp && flutter analyze && flutter test test/features/stamp`

Expected: 포맷 변경 없음, 분석 오류 0, stamp 테스트 전체 통과.

- [ ] **Step 5: Task 5 커밋**

```powershell
git add frontend/lib/features/stamp frontend/test/features/stamp
git commit -m "[FE] feat(stamp): 랠리북 실데이터 화면 전환 (#43)"
```

### Task 6: 검증 기록과 게시

**Files:**
- Create: `artifacts/validation/issue-43/VALIDATION.md`

- [ ] **Step 1: 전체 검증 실행**

```powershell
cd backend
.\gradlew.bat test --rerun-tasks
cd ..\frontend
flutter analyze
flutter test test/features/stamp
flutter build apk --debug
```

Expected: 모든 명령 exit code 0. 전체 Flutter suite에 기존 팀 B 실패가 남아 있으면 별도 실행해 정확한 파일과 실패 원인을 기록한다.

- [ ] **Step 2: 검증 기록 작성과 범위 확인**

`VALIDATION.md`에 RED/GREEN 증거, 전체 명령 결과, APK 경로, 제외 범위를 기록한다. `git diff origin/main...HEAD --name-only`에 지도, 감자, 미션 파일이 없는지 확인한다.

- [ ] **Step 3: 검증 문서 커밋**

```powershell
git add artifacts/validation/issue-43/VALIDATION.md docs/superpowers/plans/2026-06-30-stamp-rallybook-api.md
git commit -m "chore(validation): 랠리북 API 검증 기록 추가 (#43)"
```

- [ ] **Step 4: 푸시와 PR 생성**

```powershell
git push -u origin feat/43-stamp-rallybook
```

Ready PR 제목은 `[FE/BE] feat(stamp): 랠리북 진행률과 다음 보상 연동`으로 하고, 본문에 `Closes #43`, API/DB 변경, 테스트 결과, 팀 B 제외 범위를 기록한다.
