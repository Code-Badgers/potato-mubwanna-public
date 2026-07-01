# Issue 51 Validation

## 작업 목표

- 프론트 미션 화면의 mock 데이터를 대체할 백엔드 미션 MVP API를 구축한다.
- 로그인 사용자 기준으로 미션 목록, 상세, 완료 상태를 조회하고 미션 완료를 저장한다.
- 실제 QR/OCR/GPS/걸음 수 검증은 후속 작업으로 분리하고, MVP에서는 활성 미션과 중복 완료 여부를 서버에서 방어한다.

## API 계약

- `GET /missions`: 로그인 사용자의 미션 목록과 완료 상태 조회
- `GET /missions/{missionId}`: 단일 미션 상세와 완료 상태 조회
- `POST /missions/{missionId}/complete`: 활성 미션 완료 처리
- 중복 완료 요청은 `409 Conflict`, 존재하지 않는 미션은 `404 Not Found`, 비활성 또는 준비 중 미션 완료 요청은 `400 Bad Request`로 응답한다.
- 구현 전 GitHub Issue #51에 request/response 계약 초안을 기록했다.

## 진행 과정

1. 최신 `main`에서 `feat/51-mission-backend` 브랜치를 생성했다.
2. `missions`, `user_missions` 테이블을 만드는 Flyway `V5__create_missions.sql`을 추가했다.
3. MVP 미션 8개를 seed 데이터로 추가했다.
4. `mission` 패키지를 `api`, `application`, `domain` 계층으로 구성했다.
5. 미션 목록/상세/완료 API와 사용자 인증 principal 파싱을 구현했다.
6. 서비스 단위 테스트, 컨트롤러 테스트, 보안 테스트, migration 테스트를 추가했다.
7. 사용자 제공 미션 목록 중 기존 seed와 중복되는 남이섬 1,000보/정선 5일장 퀴즈를 제외하고 추가 미션 16개를 `V6__seed_additional_missions.sql`로 분리해 추가했다.

## 발생한 문제와 해결

- 첫 `./gradlew test --tests '*mission*'` 실행에서 POST 컨트롤러 테스트가 `403 Forbidden`으로 실패했다. `@WebMvcTest`에서도 CSRF가 적용되므로 POST 요청 테스트에 `csrf()`를 추가했다.
- 같은 테스트 실행에서 `MissionService` 생성자 선택 실패로 Spring context가 뜨지 않았다. 테스트용 `Clock` 주입 생성자와 Spring용 생성자가 함께 있어 생긴 문제라 Spring용 생성자에 `@Autowired`를 명시했다.
- 프론트 mock의 완료 미션 seed를 그대로 백엔드 기본 상태로 두면 모든 사용자가 완료한 것처럼 보일 수 있었다. 완료 여부는 `user_missions`가 기준이므로 seed의 기본 상태는 완료 전 상태로 조정했다.
- PR 리뷰에서 동시 완료 요청 시 DB unique 제약의 `DataIntegrityViolationException`이 500으로 노출될 수 있다는 지적이 있었다. 컨트롤러에서 해당 예외를 409 Conflict로 매핑하고 회귀 테스트를 추가했다.
- 추가 미션 원본은 MySQL/backtick 기반 예시였고 현재 스키마와 달리 `tourist_spot_id`, `reward_value` 컬럼을 포함하고 있었다. 기존 PostgreSQL/Flyway 스키마에 맞춰 `reward_label`, `condition_label`, `display_order`, `default_status`로 변환하고, 이미 PR 브랜치에 올라간 `V5`를 수정하지 않기 위해 `V6` 추가 migration으로 분리했다.

## 변경 파일 요약

- `backend/src/main/java/com/gamjamubwatna/mission/domain/*`: 미션 enum, `Mission`, `UserMission`, repository 추가
- `backend/src/main/java/com/gamjamubwatna/mission/application/*`: 미션 조회/완료 서비스와 예외 추가
- `backend/src/main/java/com/gamjamubwatna/mission/api/*`: 목록/상세/완료 응답 DTO와 컨트롤러 추가
- `backend/src/main/resources/db/migration/V5__create_missions.sql`: 미션/사용자 미션 테이블과 MVP seed 추가
- `backend/src/test/java/com/gamjamubwatna/mission/**/*`: API, 보안, 서비스, migration 테스트 추가
- `backend/src/main/java/com/gamjamubwatna/mission/api/MissionController.java`: 동시 중복 완료로 발생할 수 있는 DB unique 제약 예외를 409로 변환
- `backend/src/test/java/com/gamjamubwatna/mission/api/MissionControllerTest.java`: `DataIntegrityViolationException` 중복 완료 응답 테스트 추가
- `backend/src/main/resources/db/migration/V6__seed_additional_missions.sql`: 강원 18개 시군 기반 추가 점순이 미션 seed 16개 추가
- `backend/src/main/java/com/gamjamubwatna/mission/domain/MissionType.java`: OCR 사진 인증 미션 구분을 위한 `PHOTO_OCR` 타입 추가
- `backend/src/test/java/com/gamjamubwatna/mission/domain/MissionMigrationTest.java`: 총 seed 개수 24개와 `PHOTO_OCR` enum 매핑 검증

## 검증

- `cd backend && ./gradlew test --tests '*mission*'`: 1차 실패. CSRF 토큰 누락과 `MissionService` 생성자 선택 문제 확인.
- `cd backend && ./gradlew test --tests '*mission*'`: 성공
- `cd backend && ./gradlew test`: 성공
- `cd backend && ./gradlew build`: 성공
- `cd backend && ./gradlew test --tests 'com.gamjamubwatna.mission.api.MissionControllerTest' --tests '*mission*'`: 성공. 동시 중복 완료 예외 매핑 리뷰 반영 후 재검증했다.
- `cd backend && ./gradlew test`: 성공
- `cd backend && ./gradlew test --tests 'com.gamjamubwatna.mission.domain.MissionMigrationTest'`: 성공. `V6` seed와 `PHOTO_OCR` enum 매핑을 검증했다.
- `cd backend && ./gradlew test --tests '*mission*'`: 성공
- `cd backend && ./gradlew test`: 성공

## 남은 리스크

- QR/OCR/GPS/걸음 수 등 실제 인증 검증 로직은 아직 없다.
- 쿠폰, 감자 캐릭터, 코인 등 보상 도메인과의 실지급 연동은 후속 작업이 필요하다.
- 프론트 미션 화면은 아직 mock repository를 사용한다. 후속 이슈에서 `/missions` API 연동이 필요하다.
- iOS Xcode 메타파일 변경은 작업 전 stash로 보존했으며 이번 백엔드 작업에는 포함하지 않았다.
