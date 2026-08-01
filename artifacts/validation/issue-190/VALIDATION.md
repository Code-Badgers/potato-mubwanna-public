# Issue #190 Validation

## 작업 요약

- 이슈: #190 `[FE/BE] fix: 감자걸음 동기화로 실제 감자 성장 반영`
- 브랜치: `fix/190-potato-growth`
- 기준 브랜치: `origin/main` (`253da0b`)
- 기능 ID: `POTATO-005`, `POTATO-007`
- 목표: 일일 활동 증가분을 대표 감자의 성장과 레벨에 실제 반영하고, 신규 사용자에게 표시되던 고정 데모 통계를 제거한다.

## 구현 내용

- 최초 일일 활동 동기화는 전체 이동 거리를 현재 대표 감자 성장에 반영한다.
- 같은 날짜와 소스의 재동기화는 저장된 최대 거리보다 늘어난 차이만 성장에 반영한다.
- 같거나 감소한 건강 데이터 스냅샷은 성장량을 중복 지급하거나 회수하지 않는다.
- 기존 활동 행을 비관적 쓰기 잠금으로 조회해 동시 증가 요청의 유실 가능성을 줄인다.
- 성장 목표를 넘긴 잔여 거리는 다음 레벨로 이월하고, IA의 다섯 성장 단계에서 상한을 둔다.
- 완성 단계는 성장 진행률 100%와 남은 거리 0을 유지한다.
- 활동 이력이 없으면 오늘 걸음, 주간 거리, 월간 거리를 모두 0으로 반환한다.
- 프론트는 일일 활동 동기화를 도감과 성장 요약 조회의 공유 선행 작업으로 실행한다.
- 도감과 성장 요약을 함께 구독해도 동기화는 한 번만 실행되며, 실패하면 저장된 서버 상태로 화면을 계속 연다.

## API 및 DB 영향

- `PUT /potatoes/me/activity/daily` request/response 필드는 변경하지 않았다.
- `GET /potatoes/me/growth-summary` response 필드는 변경하지 않았다.
- API의 동작 의미만 이슈 본문에 구현 전에 기록했다.
- DB 스키마와 Flyway migration은 변경하지 않았다.

## 자동 검증

| 명령 | 결과 |
| --- | --- |
| 감자 도메인·서비스 국소 Gradle 테스트 | 성공 |
| `./gradlew.bat test --tests "com.gamjamubwatna.potato.application.PotatoGrowthFlowIntegrationTest"` | 성공, 실제 H2/Flyway 저장·성장·재동기화·조회 흐름 통과 |
| `./gradlew.bat clean test` | 성공, 백엔드 전체 354개 테스트 통과 |
| `./gradlew.bat build -x test` | 성공, `bootJar`와 `jar` 생성 |
| 감자 controller/screen Flutter 국소 테스트 | 성공, 7개 테스트 통과 |
| `flutter analyze --no-fatal-infos --no-pub` | 성공, `No issues found` |
| `flutter test --no-pub` | 성공, Flutter 전체 205개 테스트 통과 |
| `flutter build apk --debug --no-pub` | 성공, debug APK 생성 |
| API 36 에뮬레이터 APK 설치 | 성공 |
| 앱 PID 대상 error log 확인 | `FATAL EXCEPTION` 없음. Android의 비치명적 `ashmem` 폐기 안내만 확인 |

## 통합 시나리오 결과

1. 대표 감자 레벨 1, 성장 거리 0에서 2.0km를 최초 동기화했다.
2. 같은 날짜에 1.5km 감소 스냅샷을 보내 기존 2.0km와 성장 상태가 유지되는지 확인했다.
3. 4.5km 증가 스냅샷을 보내 차이 2.5km만 추가 반영되는지 확인했다.
4. 최종 대표 감자가 레벨 2, 성장 거리 1.5km인지 DB 조회로 검증했다.
5. 성장 요약이 오늘 6,000걸음, 주간/월간 4.5km, 남은 거리 1.5km인지 검증했다.

## 발생한 문제와 해결

1. 구현 전 테스트는 `UserPotato.addGrowthDistance`가 없어 컴파일 실패했다. 성장 동작이 실제로 누락됐음을 확인한 예상 TDD 실패다.
2. 기존 migration 파일을 `V4__seed_gangwon_potato_catalog.sql`로 잘못 추정해 조회가 한 번 실패했다. 실제 `V11__create_potatoes.sql`을 찾아 성장 목표와 5개 카탈로그 seed를 확인했다.
3. 테스트 정리 패치에서 증가 동기화 테스트의 `representative` 선언을 잘못 제거해 첫 `clean test`가 컴파일 실패했다. 선언을 원래 테스트에 복구하고 감소 테스트의 불필요 변수만 제거한 뒤 전체 테스트를 다시 통과시켰다.
4. `adb shell am start -W`는 12초 후 `Status: timeout`을 반환했다. 이어서 PID, `topResumedActivity`, 프로세스 로그와 화면을 확인해 앱이 실제로 정상 실행 중이며 치명적 예외가 없음을 확인했다.

## 산출물

- `artifacts/validation/issue-190/VALIDATION.md`
- `artifacts/validation/issue-190/app-launch-api36.png`

## 잔여 리스크

- 실제 HealthKit/Health Connect 권한이 승인된 로그인 실기기의 걸음 데이터로 화면 변화를 확인하지는 못했다. provider 순서와 API/DB 반영은 자동·통합 테스트로 검증했다.
- 동시에 들어오는 최초 활동 insert는 DB unique constraint와 트랜잭션 rollback에 의존한다. 기존 활동 행의 동시 갱신은 비관적 잠금으로 직렬화한다.
- Android 빌드에는 #133에서 기록한 외부 Flutter 플러그인 KGP 호환 경고가 남는다.

## 다음 작업

- PR에서 성장 단계 상한과 증가분 반영 정책을 리뷰한다.
- Android/iOS 실기기에서 HealthKit/Health Connect 권한 승인 후 도감 첫 진입의 성장 변화를 최종 QA한다.
