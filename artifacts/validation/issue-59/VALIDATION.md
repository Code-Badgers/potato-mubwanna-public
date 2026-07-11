# Issue 59 Validation - Mission Verification Policy

## 목표

- 미션 검증 기준을 코드 하드코딩에서 DB 정책으로 분리한다.
- 퀴즈 정답, QR 코드, 사진 업로드 필수 여부, 걸음 수 최소 기준을 미션별 정책 데이터로 관리한다.
- 기존 `POST /api/missions/{missionId}/verify` API 계약은 유지한다.

## 진행 내용

1. `mission_verification_policies` 테이블을 추가하는 Flyway V7 migration을 작성했다.
2. 기존 seed 미션 중 `QUIZ`, `VISIT_AND_STEP`, `PHOTO`, `PHOTO_OCR`, `QR_SCAN` 타입 17건에 검증 정책 seed를 추가했다.
3. `MissionVerificationPolicy` JPA Entity와 `MissionVerificationPolicyRepository`를 추가했다.
4. `MissionService.verifyMission`이 미션 제목 문자열을 추론하지 않고 정책 테이블을 조회해 검증하도록 변경했다.
5. 서비스 테스트에 정책 기반 퀴즈, 걸음, QR, 사진 업로드 검증 케이스를 추가했다.
6. 마이그레이션 테스트에서 정책 seed 개수와 대표 퀴즈 정답 정책을 확인하도록 보강했다.
7. PR 리뷰 대응으로 `mission_id` unique constraint와 중복되는 별도 index를 제거했다.
8. `required_upload`는 DB에서 `NOT NULL`이므로 Java 도메인 타입을 `Boolean`에서 primitive `boolean`으로 정리했다.
9. 사진 인증 검증은 `"upload-not-required"` 같은 sentinel 문자열 없이 정책 값에 따라 업로드 키만 확인하도록 분리했다.
10. 걸음 수 정책 누락과 사용자의 걸음 수 부족을 서로 다른 오류 메시지로 구분했다.

## 발생한 문제와 해결

- 최초 테스트 실행에서 `verifyMission` 성공 테스트에 정책 repository stub이 빠져 `미션 검증 정책을 찾을 수 없습니다.` 예외가 발생했다.
  - 해결: 성공 케이스에 `MissionVerificationPolicyRepository.findByMissionId` stub을 추가했다.
- 반대로 기존 `completeMission` 테스트에는 정책 repository stub이 잘못 들어가 Mockito unused stubbing 실패가 발생했다.
  - 해결: 완료 API 호환 테스트에서 불필요한 정책 stub을 제거했다.
- 구현 중 비정책 타입을 위해 임시 정책 엔티티를 생성하는 구조가 생겼다.
  - 해결: 정책이 필요한 타입의 switch branch에서만 repository를 조회하도록 정리했다.
- PR 리뷰에서 `UNIQUE (mission_id)`가 이미 PostgreSQL unique index를 생성하므로 별도 `mission_id` index가 중복이라는 지적이 있었다.
  - 해결: V7 migration의 중복 index 생성을 제거하고 migration 테스트를 다시 실행했다.
- PR 리뷰에서 `required_upload`가 nullable하지 않은데 도메인 필드가 `Boolean`인 점과, 사진 인증 우회용 sentinel 문자열이 읽기 어렵다는 지적이 있었다.
  - 해결: `requiredUpload`를 primitive `boolean`으로 변경하고 `validatePhoto` 메서드로 정책 기반 검증을 명시했다.
- PR 리뷰에서 걸음 정책 누락과 걸음 부족이 같은 메시지로 처리되는 점이 지적되었다.
  - 해결: 정책 데이터 누락 시 `"미션 걸음 수 정책을 확인할 수 없습니다."`, 사용자 걸음 수 부족 시 `"걸음을 다 채우고 재시도해주세요."`가 반환되도록 분리하고 테스트를 추가했다.

## 실행한 검증

```bash
cd backend && ./gradlew test --tests '*mission*'
```

- 결과: 통과
- 비고: 첫 실행은 테스트 stub 위치 오류로 실패했고 수정 후 통과했다.

```bash
cd backend && ./gradlew test --tests '*MissionMigrationTest'
```

- 결과: 통과
- 비고: 중복 index 제거 후 Flyway V7 migration과 seed 검증이 통과하는지 확인했다.

```bash
cd backend && ./gradlew test --tests '*mission*'
```

- 결과: 통과
- 비고: 리뷰 대응 후 정책 기반 미션 서비스 테스트와 migration 테스트를 함께 재확인했다.

```bash
cd backend && ./gradlew build
```

- 결과: 통과
- 비고: Flyway V7, JPA validate, 전체 테스트, jar/bootJar 생성까지 확인했다.

## 변경 파일 요약

- `backend/src/main/resources/db/migration/V7__create_mission_verification_policies.sql`
  - 검증 정책 테이블과 seed 데이터 추가
- `backend/src/main/java/com/gamjamubwatna/mission/domain/MissionVerificationPolicy.java`
  - 미션 검증 정책 JPA Entity 추가
- `backend/src/main/java/com/gamjamubwatna/mission/domain/MissionVerificationPolicyRepository.java`
  - 미션별 검증 정책 조회 repository 추가
- `backend/src/main/java/com/gamjamubwatna/mission/application/MissionService.java`
  - 정책 기반 검증으로 전환
- `backend/src/test/java/com/gamjamubwatna/mission/application/MissionServiceTest.java`
  - 정책 기반 검증 테스트 보강
- `backend/src/test/java/com/gamjamubwatna/mission/domain/MissionMigrationTest.java`
  - 정책 seed 검증 추가

## 남은 리스크

- QR 정책 seed는 현재 프론트 MVP mock 값인 `mock-qr`에 맞춰져 있다. 실제 QR 스캐너 연동 시 미션별 실제 QR payload로 교체해야 한다.
- 사진/OCR 정책은 아직 `uploadKey` 존재 여부만 확인한다. 실제 업로드 저장소와 OCR 결과 검증은 후속 작업이다.
- 걸음 수 정책은 서버가 전달받은 `stepCount`를 신뢰한다. HealthKit/Google Fit/Pedometer 연동 후 신뢰 가능한 측정값으로 바꿔야 한다.
- 관리자 화면 또는 운영 도구에서 정책을 편집하는 기능은 아직 없다.

## 후속 작업

- 실제 QR scanner 플러그인과 QR payload 검증 연결
- 이미지 업로드 및 OCR 검증 API 연결
- HealthKit/Google Fit/Pedometer 걸음 수 연동
- 미션 완료 후 보상/도감/쿠폰 지급 도메인과 연결
