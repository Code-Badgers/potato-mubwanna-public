# #177 반복 미션 주기와 이벤트 기간 Validation

## 1. 작업 범위

- Issue: #177 `[BE] fix: 일일·주간 미션 반복 주기와 이벤트 기간 반영`
- Branch: `fix/177-recurring-mission-periods`
- 목표: DAILY/WEEKLY 완료와 보상을 현재 기간 단위로 저장하고, EVENT 활성 기간을 반개구간으로 검증한다.
- 제외: #166 QR 안내판 운영 자료, #133 Android Built-in Kotlin 전환, FCM/관리자 기능

## 2. PAAR 기록

### Problem

- `user_missions`의 `(user_id, mission_id)` 유일 제약 때문에 반복 미션도 사용자당 평생 한 번만 완료할 수 있었다.
- `reward_histories`도 미션과 사용자의 전체 기간에 한 번만 저장되어 다음 일/주 보상을 막았다.
- 목록과 상세가 과거 전체 완료를 현재 완료로 표시했고, 주간 증빙 종료 시각은 다음 월요일이 아니라 조회 당일 다음 날이었다.
- 이벤트 미션에 시작/종료 시각이 없어 운영 기간 밖 인증을 차단할 수 없었다.

### Analysis

- 서비스 기준 timezone은 `Asia/Seoul`로 고정한다.
- 일간은 서울 기준 당일 00:00부터 다음 날 00:00 미만, 주간은 월요일 00:00부터 다음 월요일 00:00 미만으로 계산한다.
- 이벤트는 `starts_at` 이상 `ends_at` 미만으로 계산하며, 기간 미설정 또는 기간 밖이면 잠금 상태로 응답하고 인증을 거부한다.
- 완료와 보상은 동일한 기간 키를 사용해 애플리케이션 조회와 DB 유일 제약의 기준을 일치시킨다.
- 목록 조회는 과거 반복 완료 전체를 읽지 않고 현재 필요한 기간 키만 조회한다.

### Action

- `MissionPeriod`를 추가해 일간, 주간, 이벤트, 전체 기간 키와 경계를 한 곳에서 계산했다.
- `user_missions.completion_period`와 `reward_histories.source_period`를 추가하고 유일 제약에 포함했다.
- `missions.starts_at`, `missions.ends_at`과 이벤트 기간 정합성 CHECK 제약을 추가했다.
- 목록, 상세, 인증, 증빙 진행도를 현재 기간 기준으로 변경했다.
- 이벤트 방문 증빙도 이벤트 기간 안에 생성된 방문만 인정하도록 변경했다.
- 걸음 증빙은 일간뿐 아니라 주간/다일 이벤트에서도 전체 기간의 신뢰 가능한 활동 기록을 합산하도록 변경했다.
- API 계약에 기간 경계, 이벤트 잠금, 응답 기간 필드, 기간별 멱등성을 명시했다.

### Result

- 같은 일/주에는 같은 미션의 완료와 보상이 한 번만 저장된다.
- 다음 일/주에는 새 기간 키로 같은 미션을 다시 완료하고 보상받을 수 있다.
- 이전 기간 완료와 진행도는 현재 목록/상세에 반영되지 않는다.
- 기간이 없는 기존 이벤트 seed는 운영 일정이 입력될 때까지 `LOCKED`로 응답되고 인증이 차단된다.

## 3. 검증 명령

### 실패 후 수정

```bash
cd backend
./gradlew test --tests "com.gamjamubwatna.mission.*"
```

- 최초 결과: 테스트 컴파일 실패
- 원인: `MissionItemResponse`에 기간 필드가 추가됐지만 컨트롤러 테스트 fixture에 인자가 누락됨
- 해결: fixture에 `periodStartsAt`, `periodEndsAt`을 추가

```bash
cd backend
./gradlew test --tests "com.gamjamubwatna.mission.*"
```

- 두 번째 결과: 3개 테스트 실패
- 원인: 기존 주간 테스트가 종료 시각을 다음 날로 가정했고, 서비스 mock이 기간 인자가 없는 이전 validator signature를 사용함
- 해결: 주간 종료를 다음 월요일로 수정하고 기간 인자를 포함해 mock 검증

### 통과

```bash
cd backend
./gradlew test --tests "com.gamjamubwatna.mission.*"
```

- 결과: `BUILD SUCCESSFUL`
- 확인 내용:
  - 서울 자정과 월요일 자정 기간 경계
  - 이벤트 `[startsAt, endsAt)` 경계와 미설정 이벤트 잠금
  - 같은 기간 DB 중복 완료/보상 차단
  - 다음 날 동일 미션 재완료와 재보상
  - 현재 기간 완료/진행도만 목록에 반영

```bash
cd backend
./gradlew clean test
```

- 결과: `BUILD SUCCESSFUL`
- 확인 내용: 전체 백엔드 회귀 테스트 통과 및 Flyway V20/Hibernate schema validate 성공

## 4. 성능 테스트

- 별도 부하 테스트는 실행하지 않았다.
- 목록 조회는 누적 완료 전체 대신 현재 기간 키 집합만 조회하도록 제한해 반복 미션 데이터 증가에 따른 조회량을 줄였다.

## 5. 남은 리스크와 후속 작업

- 기존 DAILY/WEEKLY 완료 및 보상 행은 migration에서 `ONCE`로 보존한다. 배포 직후 현재 새 기간에는 한 번 더 완료·보상할 수 있다.
- 이벤트 seed에는 실제 운영 일정이 없으므로 현재는 잠긴다. 검증된 일정은 관리자 기능 또는 별도 운영 migration으로 입력해야 한다.
- 기간 경계와 CHECK/UNIQUE migration은 H2 PostgreSQL mode에서 검증했다. 실제 배포 전 PostgreSQL staging migration 확인이 권장된다.
