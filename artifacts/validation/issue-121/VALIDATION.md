# Issue #121 검증 기록

## 작업 요약

- 이슈: #121 마이페이지 활동 요약 실데이터 연동
- 브랜치: `feat/121-mypage-activity-summary`
- 담당 영역: Team A 사용자 활동 요약 Backend API와 Flutter 마이페이지
- 제외 범위: 쿠폰 혜택 단위, 회원 탈퇴, 보상 이력 페이지네이션, 지도 파일
- 목표: 누적 걸음 수, 누적 스탬프 수, 보유 감자 수를 로그인 사용자의 실제 데이터로 표시한다.

## 진행 과정

1. `GET /api/users/me/activity-summary`의 request/response와 인증 규칙을 API 문서에 먼저 추가했다.
2. 기존 `user_daily_activities`, `user_stamps`, `user_potatoes`를 재사용해 DB migration 없이 집계하도록 구현했다.
3. 프로필 조회와 집계 책임을 섞지 않도록 `UserActivitySummaryService`를 별도로 추가했다.
4. Flutter에 활동 요약 모델, 저장소, 인증 세션 연동 provider를 추가했다.
5. 마이페이지의 `-` 세 개를 실제 값으로 교체하고 로딩·오류·재시도 상태를 추가했다.
6. 모바일 430x932, 데스크톱 1440x1000 화면에서 잘림·겹침과 브라우저 오류를 확인했다.

## 발생한 문제와 해결

### 로컬 Dart formatter의 광범위한 재포맷

- 로컬 Flutter SDK의 formatter가 기존 마이페이지와 테스트 파일의 줄바꿈을 대량 변경했다.
- 기능과 무관한 포맷 변경을 모두 되돌리고 필요한 코드만 다시 적용해 diff를 제한했다.

### Flutter Web DOM 접근성 트리 제한

- Flutter Web canvas는 브라우저 DOM snapshot에서 화면 텍스트를 충분히 노출하지 않았다.
- 실제 full-page screenshot과 위젯 테스트로 표시값과 레이아웃을 검증했고, 브라우저 warning/error 로그가 비어 있음을 확인했다.

### 로컬 통합 인프라 미실행

- PostgreSQL 기본 포트 `15432`, Redis `6379`가 닫혀 있었고 Docker daemon도 사용할 수 없었다.
- 실제 PostgreSQL HTTP 호출 대신 H2 기반 Spring 전체 테스트와 JWT 보안 통합 테스트를 실행했다.

## 변경 파일 요약

- `agents_docs/07_api_specification.md`: 활동 요약 API 계약
- `backend/src/main/java/com/gamjamubwatna/user/**`: 응답 DTO, 집계 서비스, endpoint
- `backend/src/main/java/com/gamjamubwatna/potato/domain/*Repository.java`: 누적 걸음과 보유 감자 집계
- `backend/src/test/java/com/gamjamubwatna/user/**`: 서비스, Controller, 인증 검증
- `frontend/lib/features/mypage/**`: 활동 요약 모델, 저장소, provider, 화면 상태
- `frontend/test/features/mypage/**`: 응답 매핑, 세션 변경, 정상·로딩·오류 화면 검증

## 검증

### Backend

```powershell
cd backend
.\gradlew.bat test --tests 'com.gamjamubwatna.user.*' --console=plain
.\gradlew.bat build --console=plain
```

- 사용자 관련 집중 테스트 통과
- 전체 테스트 243개 통과, 실패·오류·skip 0
- build 성공

### Frontend

```powershell
cd frontend
flutter test test\features\mypage
flutter analyze
flutter test
flutter build web --dart-define=API_BASE_URL=http://localhost:8080/api
```

- 마이페이지 관련 테스트 20개 통과
- 전체 테스트 134개 통과
- analyze: `No issues found`
- web build 성공
- 기존 `CupertinoIcons` font 및 WebAssembly 비호환 패키지 경고가 있으나 JavaScript web 산출물은 정상 생성됐다.

### 화면

- `mypage-activity-mobile.png`: 430x932 full-page
- `mypage-activity-desktop.png`: 1440x1000 full-page
- 누적 걸음 수 `256,842`, 스탬프 `12`, 감자 `7` 표시 확인
- 브라우저 warning/error 로그 없음

## 공유 파일 / 계약 변경

- 공유 위험 파일: `agents_docs/07_api_specification.md`
- API 계약: `GET /api/users/me/activity-summary` 추가
- DB migration: 없음
- 환경 변수: 없음
- 외부 API: 없음

## 남은 리스크

- 누적 걸음 수는 서버에 동기화된 `user_daily_activities.steps` 합계이므로, 아직 동기화되지 않은 기기 데이터는 포함하지 않는다.
- 같은 날짜에 여러 활동 출처가 저장되면 현재 합산한다. 다중 기기 중복 제거 정책이 필요해지면 별도 이슈로 정의해야 한다.
- 실제 PostgreSQL과 로그인 계정 기반 HTTP 검증은 Docker와 로컬 인프라가 준비된 환경에서 추가할 수 있다.

## 다음 작업

- 쿠폰 혜택 단위를 `금액/퍼센트/교환`으로 구분하는 Team A 후속 이슈를 진행한다.
- 회원 탈퇴는 개인정보와 연관 데이터 보존 정책을 먼저 확정한다.
