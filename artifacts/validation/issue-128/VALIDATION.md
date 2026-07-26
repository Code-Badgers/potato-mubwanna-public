# Issue #128 검증 기록

## 작업 목표

- 방문 인증 성공 시 감자 도감 획득 흐름을 백엔드에 연결한다.
- #125에서 저장한 `tourist_spots.congestion_level`을 감자 희귀도 정책에 사용한다.
- `POST /api/visits/verify` 응답에 감자 획득 결과를 포함한다.

## PAAR 기록

### 1. 혼잡도 기반 감자 획득 정책

- Problem: 기존 방문 인증은 스탬프만 지급하고 `potatoAcquired=false`를 고정으로 반환했다. 이 상태에서는 “한적한 장소를 방문하면 더 희귀한 감자를 얻는다”는 서비스 차별점이 실제 데이터 흐름으로 이어지지 않았다.
- Action: `CongestionRarityPolicy`에 방문 인증 후보 희귀도 순서를 추가하고, `VisitPotatoAcquisitionService`를 만들었다.
- Analysis: 랜덤 확률을 바로 넣으면 테스트가 흔들리고 공모전 MVP에서 결과 재현이 어렵다. 그래서 이번 이슈에서는 deterministic fallback 정책으로 설계했다. `LOW → EPIC, RARE, COMMON`, `NORMAL → RARE, COMMON`, `HIGH → COMMON` 순서로 활성 감자를 찾는다.
- Result: 혼잡도 낮음에서는 황금급 감자, 보통에서는 희귀/일반 fallback, 높음에서는 일반 감자를 지급하는 단위 테스트를 통과했다.

### 2. 중복 획득 처리

- Problem: 같은 사용자가 이미 가진 감자를 다시 획득하면 `user_potatoes`의 unique 제약에 걸릴 수 있고, 사용자에게도 “새 획득”인지 “이미 보유”인지 구분이 필요하다.
- Action: `UserPotatoRepository.findByUserIdAndPotatoId`를 추가하고, 이미 보유한 감자면 새 row를 만들지 않도록 처리했다.
- Analysis: 중복 방문 인증은 `user_visits`에서 이미 409로 막지만, 서로 다른 스팟에서 같은 감자 후보가 나올 수 있다. 따라서 감자 획득 서비스 자체도 중복 저장을 방어해야 한다.
- Result: 이미 보유한 감자는 저장하지 않고 `alreadyOwned=true`, `newlyAcquired=false`로 응답하는 테스트를 추가했다.

### 3. 방문 인증 응답 연결

- Problem: 프론트가 방문 인증 성공 화면에서 어떤 감자를 얻었는지 표시하려면 응답에 감자 요약이 포함되어야 한다.
- Action: `VisitVerifyResponse`에 `acquiredPotato`를 추가하고, `VisitVerificationService`에서 스탬프 지급 후 감자 획득 서비스를 호출하도록 연결했다.
- Analysis: 기존 응답의 `potatoAcquired`는 새 획득 여부를 의미하도록 유지했다. 이미 보유한 감자가 나온 경우에는 `potatoAcquired=false`, `acquiredPotato.alreadyOwned=true`가 된다.
- Result: 컨트롤러 JSON 응답과 방문 인증 통합 흐름 테스트가 통과했다.

## 변경 파일 요약

- `backend/src/main/java/com/gamjamubwatna/potato/application/CongestionRarityPolicy.java`
  - 혼잡도별 방문 인증 감자 후보 희귀도 추가
- `backend/src/main/java/com/gamjamubwatna/potato/application/VisitPotatoAcquisitionService.java`
  - 방문 인증 성공 시 감자 선택/저장/중복 처리 추가
- `backend/src/main/java/com/gamjamubwatna/potato/api/PotatoAcquisitionResponse.java`
  - 방문 인증 응답에 포함할 감자 획득 요약 DTO 추가
- `backend/src/main/java/com/gamjamubwatna/visit/application/VisitVerificationService.java`
  - 방문 인증 성공 흐름에 감자 획득 연결
- `backend/src/main/java/com/gamjamubwatna/visit/api/VisitVerifyResponse.java`
  - `acquiredPotato` 필드 추가
- `agents_docs/07_api_specification.md`
  - 방문 인증 API 응답 예시 갱신

## 실행한 검증

```bash
cd backend && ./gradlew test --tests 'com.gamjamubwatna.potato.application.VisitPotatoAcquisitionServiceTest' --tests 'com.gamjamubwatna.potato.application.CongestionRarityPolicyTest'
```

- 결과: 성공

```bash
cd backend && ./gradlew test --tests 'com.gamjamubwatna.visit.application.VisitVerificationServiceTest' --tests 'com.gamjamubwatna.visit.api.VisitControllerTest'
```

- 결과: 성공

```bash
cd backend && ./gradlew test --tests 'com.gamjamubwatna.visit.application.VisitStampFlowIntegrationTest'
```

- 결과: 성공

```bash
cd backend && ./gradlew test --tests 'com.gamjamubwatna.visit.*' --tests 'com.gamjamubwatna.potato.*'
```

- 결과: 성공

```bash
cd backend && ./gradlew test
```

- 결과: 성공

## 성능 검증

- 이번 이슈는 `POST /api/visits/verify`의 내부 트랜잭션에 감자 획득 저장을 추가했으므로 성능 영향 가능성이 있다.
- 다만 로컬에서 인증 토큰/실제 DB 서버/API 서버를 함께 띄운 k6 시나리오가 준비되어 있지 않아 k6는 실행하지 않았다.
- 후속 k6 권장 시나리오:
  - 이미 방문한 스팟에 대한 중복 인증 409 응답 처리
  - 신규 방문 인증 성공 시 `user_visits`, `user_stamps`, `user_potatoes` 저장 처리
  - 여러 사용자가 같은 스팟을 인증하는 동시 요청
- 예상 병목:
  - `user_potatoes(user_id, potato_id)` unique 체크
  - `user_visits(user_id, tourist_spot_id)` unique 체크
  - 방문 인증 트랜잭션 내 저장 쿼리 수 증가

## 남은 리스크

- 이번 정책은 재현 가능한 MVP 정책이다. 실제 확률형 보상으로 바꾸려면 seeded random 또는 정책 테이블 분리가 필요하다.
- 전설 감자는 방문 인증 기본 보상에서 제외했다. 미션/장기 성장 보상으로 지급하는 후속 정책이 필요하다.
- 프론트 방문 인증 성공 팝업은 아직 `acquiredPotato`를 사용하지 않는다. 후속 FE 이슈에서 연결해야 한다.
- 중복 감자 획득 시 성장 경험치로 전환할지 여부는 아직 미정이다.

## 후속 작업

- 방문 인증 성공 화면에서 감자 획득/이미 보유 상태 표시
- 중복 감자 획득 시 성장 거리 또는 조각 보상 정책 설계
- 미션 완료 보상과 감자 획득 정책 통합
- k6 방문 인증 부하 테스트 스크립트 작성
