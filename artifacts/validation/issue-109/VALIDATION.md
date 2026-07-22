# Issue 109 Validation

## 작업 목표

방문 인증 백엔드의 첫 기반을 구현했다. 이번 범위는 프론트 UI와 겹치지 않도록 백엔드 중심으로 제한했다.

- `POST /api/visits/verify` 방문 인증 API 추가
- 사용자 현재 좌표와 감자 스팟 좌표 간 거리 계산
- 스팟 인증 반경 이내일 때만 방문 기록 저장
- 사용자별 동일 스팟 중복 방문 인증 방지
- 후속 스탬프/감자/미션 연결을 위한 응답 필드 준비

## PAR 기록

### Problem

지도, 감자, 미션, 오디오 작업은 각각 진행되었지만, 실제 서비스 루프인 `지도 탐색 -> 방문 인증 -> 스탬프/감자/미션 획득`에서 서버가 방문을 확정하는 지점이 부족했다. 클라이언트에서만 위치를 판단하면 조작 가능성이 크고, 중복 방문 기록도 안정적으로 막기 어렵다.

### Action

`user_visits` 테이블을 추가하고 `user_id + tourist_spot_id` 유니크 제약을 두었다. `VisitDistancePolicy`는 Haversine 공식을 사용해 좌표 간 거리를 meter 단위로 계산한다. `VisitVerificationService`는 사용자, 스팟, 중복 여부, 좌표 유효성, 반경 초과 여부를 검증한 뒤 방문 기록을 저장한다. `VisitController`는 인증된 사용자만 `POST /api/visits/verify`를 호출할 수 있게 하고, 실패 유형별로 400/401/404/409를 분리한다.

### Result

방문 인증 API의 성공, 반경 초과, 중복 인증, 인증 없음, migration validate를 테스트로 확인했다. 전체 백엔드 테스트도 통과했다.

## 구현 범위

### Backend

- `backend/src/main/resources/db/migration/V16__create_user_visits.sql`
- `backend/src/main/java/com/gamjamubwatna/visit/domain/UserVisit.java`
- `backend/src/main/java/com/gamjamubwatna/visit/domain/UserVisitRepository.java`
- `backend/src/main/java/com/gamjamubwatna/visit/application/VisitDistancePolicy.java`
- `backend/src/main/java/com/gamjamubwatna/visit/application/VisitVerificationService.java`
- `backend/src/main/java/com/gamjamubwatna/visit/api/VisitController.java`
- `backend/src/main/java/com/gamjamubwatna/visit/api/VisitVerifyRequest.java`
- `backend/src/main/java/com/gamjamubwatna/visit/api/VisitVerifyResponse.java`

### Docs

- `agents_docs/07_api_specification.md`

## API 계약

```http
POST /api/visits/verify
Authorization: Bearer {accessToken}
```

Request:

```json
{
  "spotId": 1,
  "latitude": 37.3801,
  "longitude": 128.6609
}
```

Response:

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": {
    "spotId": 1,
    "verified": true,
    "distanceMeters": 23.5,
    "verificationRadiusMeter": 100,
    "stampIssued": false,
    "potatoAcquired": false,
    "missionAvailable": false
  }
}
```

## 발생한 문제와 해결

### WebMvcTest 인증 principal 전달 문제

처음 컨트롤러 테스트에서 `SecurityMockMvcRequestPostProcessors.authentication(...)`을 사용했지만, `@AutoConfigureMockMvc(addFilters = false)` 상태에서는 컨트롤러의 `Authentication` 인자로 전달되지 않아 모든 요청이 401로 떨어졌다.

해결은 컨트롤러 단위 테스트에서는 `.principal(authentication())`로 요청 principal을 직접 넣는 방식으로 바꿨다. 실제 보안 필터 보호 여부는 별도의 `VisitControllerSecurityTest`에서 SpringBootTest로 검증했다.

## 실행한 검증 명령

```bash
cd backend
./gradlew test --tests 'com.gamjamubwatna.visit.domain.UserVisitMigrationTest'
```

결과: 성공

```bash
cd backend
./gradlew test --tests 'com.gamjamubwatna.visit.application.*'
```

결과: 성공

```bash
cd backend
./gradlew test --tests 'com.gamjamubwatna.visit.api.VisitControllerTest' --tests 'com.gamjamubwatna.visit.application.*' --tests 'com.gamjamubwatna.visit.domain.UserVisitMigrationTest'
```

1차 결과: 실패. WebMvcTest 인증 principal 전달 문제 확인.

2차 결과: 성공. `.principal(authentication())` 적용 후 통과.

```bash
cd backend
./gradlew test --tests 'com.gamjamubwatna.visit.api.VisitControllerSecurityTest' --tests 'com.gamjamubwatna.visit.*'
```

결과: 성공

```bash
cd backend
./gradlew test
```

결과: 성공

## k6 성능 테스트

이번 API는 JWT 인증과 DB seed가 필요한 상태라 k6 smoke를 바로 안정적으로 재현하지 않았다. 인증/시드가 정리되는 후속 통합 이슈에서 다음 시나리오를 k6로 측정한다.

- 로그인 사용자 JWT 준비
- 테스트 스팟 좌표 기준 정상 방문 인증 1회
- 동일 스팟 중복 인증 409 응답
- 반경 초과 400 응답
- p95 latency와 error rate 기록

## 남은 리스크

- `stampIssued`, `potatoAcquired`, `missionAvailable`은 현재 후속 이벤트 연결 전이라 `false`로 고정되어 있다.
- 스탬프 지급, 감자 획득, 미션 등장 조건은 별도 이슈에서 연결해야 한다.
- 사용자별 동일 스팟 인증은 한 번만 허용한다. 일별 재방문 이벤트가 필요해지면 유니크 제약을 `user_id + tourist_spot_id + visit_date` 형태로 바꿔야 한다.

## 후속 작업

- 방문 인증 성공 시 스탬프 지급 연결
- 방문 인증 성공 시 감자 획득/성장 연결
- 방문 인증 성공 시 해당 스팟 미션 등장 여부 연결
- 프론트 관광지 상세의 방문 인증 버튼과 `/api/visits/verify` 연동
