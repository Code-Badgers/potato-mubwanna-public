# Issue 63 Validation

## 작업 요약

- 이슈: #63 내 보상 히스토리 조회 API 구현
- 브랜치: `feat/63-reward-history-api`
- 담당 영역: Backend reward API/application/domain, API specification
- 제외 범위: 쿠폰 QR 상세, 감자 도감 지급 연동, 프론트엔드 보상함 UI, 필터와 페이지네이션
- 목표: 로그인 사용자가 지급받은 보상 이력을 최신순으로 조회할 수 있게 한다.

## 진행 과정

1. `GET /api/rewards/history`의 응답 필드와 인증 실패 조건을 API 문서에 먼저 정의했다.
2. 기존 `reward_histories` 엔티티와 조회 인덱스를 재사용하고 별도 migration은 추가하지 않았다.
3. 로그인 사용자의 존재를 확인한 뒤 `created_at` 내림차순 Repository 메서드로 이력을 조회하도록 읽기 전용 서비스를 구현했다.
4. 기존 JWT principal 형식인 `user:<id>`를 검증하고 잘못된 principal 또는 삭제된 사용자는 401로 응답하도록 구현했다.
5. 서비스와 컨트롤러 테스트로 정상 목록, 빈 목록, 삭제 사용자, 미인증 요청, 잘못된 principal을 검증했다.

## 발생한 문제와 해결

### API 문서 스테이징 거부

- 문제: `agents_docs`가 `.gitignore` 규칙에 포함되어 일반 `git add`가 거부됐다.
- 해결: #63 API 계약에 해당하는 `agents_docs/07_api_specification.md` 한 파일만 `git add -f`로 명시적으로 스테이징했다.
- 확인: 다른 `agents_docs` 파일이나 민감값은 커밋에 포함하지 않았다.

## 변경 파일 요약

- `agents_docs/07_api_specification.md`: 보상 히스토리 응답과 인증 규칙 정의
- `backend/src/main/java/com/gamjamubwatna/reward/api/RewardController.java`: 보상 히스토리 조회 endpoint와 인증 principal 검증
- `backend/src/main/java/com/gamjamubwatna/reward/api/RewardHistoryListResponse.java`: 목록 응답 DTO
- `backend/src/main/java/com/gamjamubwatna/reward/api/RewardHistoryResponse.java`: 이력 항목 응답 DTO
- `backend/src/main/java/com/gamjamubwatna/reward/application/RewardHistoryService.java`: 사용자 확인과 최신순 이력 조회
- `backend/src/main/java/com/gamjamubwatna/reward/application/RewardAuthenticationException.java`: 보상 조회 인증 예외
- `backend/src/main/java/com/gamjamubwatna/reward/domain/RewardHistory.java`: 응답 매핑용 ID getter
- `backend/src/test/java/com/gamjamubwatna/reward/`: 서비스와 컨트롤러 테스트

## 검증

### 보상 패키지 테스트

```bash
cd backend
./gradlew test --tests 'com.gamjamubwatna.reward.*'
```

- 결과: `BUILD SUCCESSFUL`
- 검증 항목: 정상 목록 응답, 빈 목록, 필드 직렬화, 미인증 401, 잘못된 principal 401, 삭제된 사용자 거부

### 백엔드 전체 테스트

```bash
cd backend
./gradlew test --console=plain
```

- 결과: `BUILD SUCCESSFUL in 11s`
- Gradle task: 4 actionable tasks, 4 up-to-date

## 공유 파일 / 계약 변경

- 공유 위험 파일: `agents_docs/07_api_specification.md`
- API 계약 변경: `GET /api/rewards/history` 응답 계약 구체화
- DB migration: 없음. #61의 `V8__create_reward_histories.sql` 재사용
- 환경 변수: 없음
- 외부 API: 없음

## 남은 리스크

- Docker PostgreSQL과 실제 JWT를 사용한 런타임 API 호출은 이번 검증에서 수행하지 않았다.
- 데이터가 많아질 경우 페이지네이션이 필요하지만 #63 범위에서는 최신순 전체 조회로 제한했다.
- 현재 보상 이력은 미션 보상 저장 흐름만 연결되어 있다. 스탬프·이벤트 보상 저장은 후속 작업이다.

## 다음 작업

- 프론트엔드 보상함에서 `GET /api/rewards/history`를 호출해 지급 내역을 표시한다.
- 스탬프 및 이벤트 보상 지급 시 `reward_histories` 저장을 연결한다.
- 운영 데이터 증가 전 커서 기반 페이지네이션을 별도 이슈로 검토한다.
