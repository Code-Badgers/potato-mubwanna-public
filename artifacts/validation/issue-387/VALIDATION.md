# Issue #387 관리자 사용자 ID 비교 검증

## 작업 요약

- 이슈: https://github.com/Code-Badgers/potato-mubwanna/issues/387
- 브랜치: `fix/387-admin-user-id-matching`
- 목표: `ADMIN_USER_IDS=42`와 실제 JWT subject `user:42`를 정확히 매칭한다.
- 제외 범위: 관리자 CRUD API, DB role migration, 환경 변수 이름 변경

## 변경 파일

- `AdminUserIdPolicy.java`: JWT subject의 `user:` 접두사와 양의 정수 ID를 검증한 뒤 숫자 allowlist와 비교한다.
- `AdminUserIdPolicyTest.java`: 실제 subject, 잘못된 subject, 잘못된 설정값을 검증한다.
- `AdminAccessControlTest.java`: 실제 로그인과 동일한 `user:<id>` access token으로 403/200 경계를 검증한다.

## 진행 과정

- 공지 관리 API 설계 중 `AuthService`가 JWT subject를 `user:<id>`로 발급하는 사실을 확인했다.
- 기존 정책 테스트는 숫자 subject를 사용해 운영 형식 불일치를 발견하지 못했다.
- 설정값은 숫자 application user ID만 허용하고, JWT subject는 `^user:([1-9]\\d*)$` 형식일 때만 관리자 후보로 인정하도록 수정했다.

## 검증

- `.\gradlew.bat test --tests "com.gamjamubwatna.auth.infrastructure.AdminUserIdPolicyTest" --tests "com.gamjamubwatna.global.config.AdminAccessControlTest"`: 통과
- `.\gradlew.bat test`: 433개 통과, 실패·오류·건너뜀 0개
- `.\gradlew.bat build`: 통과
- `git diff --check`: 공백 오류 없음. Windows LF/CRLF 안내만 출력됨.

## 남은 리스크

- 실제 운영 환경에서 관리자 application user ID를 `ADMIN_USER_IDS`에 설정하고 서버를 재시작해야 한다.
- 실제 공지 관리 API와 UI는 후속 이슈에서 구현한다.

## 다음 작업

- 관리자 공지 전체 목록·작성·수정·게시 상태 변경 API 구현
