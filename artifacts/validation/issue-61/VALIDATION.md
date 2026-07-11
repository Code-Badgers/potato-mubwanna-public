# Issue 61 Validation - Mission Reward History

## 목표

- 미션 완료 성공 시 사용자가 획득한 보상 이력을 서버 DB에 남긴다.
- 실제 쿠폰 지급, 감자 도감 지급, 프론트 보상함 화면 연동 전에 공통 보상 기록 기반을 만든다.

## 진행 내용

1. GitHub Issue #61 `[Mission] 미션 완료 보상 히스토리 저장`을 생성했다.
2. 최신 `main`에서 `feat/61-mission-reward-history` 브랜치를 생성했다.
3. `reward_histories` 테이블을 추가하는 Flyway V8 migration을 작성했다.
4. `RewardHistory`, `RewardSourceType`, `RewardHistoryRepository` 도메인 기반을 추가했다.
5. `MissionService.completeMission`과 `MissionService.verifyMission` 성공 시 `RewardHistory`가 저장되도록 연결했다.
6. 서비스 테스트에서 미션 완료 성공 시 보상 타입, 보상명, source type, source id, 생성 시간이 기록되는지 검증했다.
7. 중복 완료 요청에서는 보상 히스토리가 추가 저장되지 않는지 검증했다.

## 변경 파일 요약

- `backend/src/main/resources/db/migration/V8__create_reward_histories.sql`
  - `reward_histories` 테이블, 사용자/출처 unique constraint, 사용자 조회 index 추가
- `backend/src/main/java/com/gamjamubwatna/reward/domain/RewardHistory.java`
  - 보상 이력 JPA Entity 추가
- `backend/src/main/java/com/gamjamubwatna/reward/domain/RewardSourceType.java`
  - 보상 출처 enum 추가
- `backend/src/main/java/com/gamjamubwatna/reward/domain/RewardHistoryRepository.java`
  - 사용자별 보상 이력 조회 repository 추가
- `backend/src/main/java/com/gamjamubwatna/mission/application/MissionService.java`
  - 미션 완료 성공 시 보상 이력 저장 연결
- `backend/src/test/java/com/gamjamubwatna/mission/application/MissionServiceTest.java`
  - 완료/인증 성공 보상 이력 저장 검증 추가
- `backend/src/test/java/com/gamjamubwatna/mission/domain/MissionMigrationTest.java`
  - `reward_histories` 조회 index 생성 검증 추가

## 실행한 검증

```bash
cd backend && ./gradlew test --tests '*MissionMigrationTest'
```

- 결과: 통과
- 확인 내용: Flyway V8 migration 적용, JPA validate, reward history index 생성

```bash
cd backend && ./gradlew test --tests '*mission*'
```

- 결과: 통과
- 확인 내용: 미션 완료/인증 성공 시 보상 히스토리 저장, 중복 완료 시 저장 방지

```bash
cd backend && ./gradlew test
```

- 결과: 통과
- 확인 내용: 백엔드 전체 테스트 회귀 없음

## 남은 리스크

- 이번 작업은 보상 이력 저장 기반만 다룬다. 실제 쿠폰 발급, 감자 도감 지급, 아이템 인벤토리 반영은 후속 이슈가 필요하다.
- `GET /api/rewards/history` 응답 API는 아직 구현하지 않았다. 프론트 보상함/마이페이지 연결 시 별도 이슈로 추가하는 것이 좋다.
- `reward_histories`의 unique constraint는 동일 사용자와 동일 source에 대해 한 번만 기록하도록 막는다. 하나의 미션에서 여러 보상을 지급하는 정책이 생기면 reward policy 모델을 별도로 분리해야 한다.

## 후속 작업

- 보상 히스토리 조회 API 구현
- 쿠폰 보상일 때 `user_coupons` 발급 연결
- 감자 보상일 때 `user_potatoes` 지급 연결
- 프론트 보상함/마이페이지에서 보상 히스토리 표시
