# Issue #382 관리자 접근 제어 기반 검증

## 작업 요약

- 이슈: https://github.com/Code-Badgers/potato-mubwanna/issues/382
- 브랜치: `feat/382-admin-access-control`
- 담당 영역: JWT 관리자 authority 부여, `/admin/**` 접근 제어, 환경 변수와 API 계약
- 제외 범위: 관리자 CRUD API, 관리자 화면, 별도 관리자 로그인, DB role migration
- 목표: 기존 카카오 로그인 사용자의 ID를 서버 allowlist와 비교해 관리자 API 기반을 안전하게 보호한다.

## 변경 파일

- `backend/src/main/java/com/gamjamubwatna/auth/infrastructure/AdminUserIdPolicy.java`: 쉼표 구분 관리자 사용자 ID를 정규화하고 조회한다.
- `backend/src/main/java/com/gamjamubwatna/auth/infrastructure/JwtAuthenticationFilter.java`: allowlist 사용자에게 `ROLE_USER`, `ROLE_ADMIN`을 함께 부여한다.
- `backend/src/main/java/com/gamjamubwatna/global/config/SecurityConfig.java`: `/admin/**`에 ADMIN 역할을 요구하고 403 JSON 응답을 정의한다.
- `backend/src/main/resources/application.yml`, `backend/.env.example`: `ADMIN_USER_IDS` 설정을 추가한다.
- `agents_docs/07_api_specification.md`: 관리자 인증과 401/403 계약을 명시한다.
- `backend/src/test/java/com/gamjamubwatna/auth/infrastructure/AdminUserIdPolicyTest.java`: allowlist 파싱과 기본 거부를 검증한다.
- `backend/src/test/java/com/gamjamubwatna/global/config/AdminAccessControlTest.java`: 미인증 401, 일반 사용자 403, 관리자 200을 검증한다.

## 공유 파일 / 계약 변경

- 공유 위험 파일: 공통 인증 필터, SecurityConfig, application.yml, API 명세를 관리자 접근 제어 범위로만 수정했다.
- API 계약: 외부 `/api/admin/**` 경로는 유효한 access token과 ADMIN 역할을 모두 요구한다.
- DB migration: 없음.
- 환경 변수: `ADMIN_USER_IDS` 추가. 실제 값은 저장소와 문서에 기록하지 않는다.
- 외부 API: 없음.

## 진행 중 발생한 문제와 해결

1. 최초 구현은 `AdminUserIdPolicy`를 Spring Bean으로 주입했다.
2. 국소 관리자 테스트는 통과했지만, 전체 테스트에서 다수의 `@WebMvcTest`가 새 Bean을 로드하지 않아 `NoSuchBeanDefinitionException`으로 실패했다.
3. 모든 컨트롤러 테스트에 mock을 추가하면 변경 범위가 커지므로, JWT 필터가 설정 문자열을 받아 package-private 정책 객체를 직접 구성하도록 수정했다.
4. 실패했던 대표 controller slice 테스트를 국소 재실행한 뒤 전체 테스트를 다시 실행했다.

## 검증

- 실행: `.\gradlew.bat test --tests "com.gamjamubwatna.auth.infrastructure.AdminUserIdPolicyTest" --tests "com.gamjamubwatna.global.config.AdminAccessControlTest" --tests "com.gamjamubwatna.auth.api.AuthControllerTest"`
- 결과: 성공.
- 실행: 최초 `.\gradlew.bat test`
- 결과: 실패 후 중단. 신규 정책 Bean이 controller slice에 없었던 것이 원인이며 위 방식으로 해결했다.
- 실행: `.\gradlew.bat test --tests "com.gamjamubwatna.auth.infrastructure.AdminUserIdPolicyTest" --tests "com.gamjamubwatna.global.config.AdminAccessControlTest" --tests "com.gamjamubwatna.auth.api.AuthControllerTest" --tests "com.gamjamubwatna.audio.api.AudioGuideControllerTest" --tests "com.gamjamubwatna.coupon.api.CouponControllerTest"`
- 결과: 성공.
- 실행: `.\gradlew.bat test`
- 결과: 428개 테스트 통과, 실패·오류·건너뜀 0개.
- 실행: `.\gradlew.bat build`
- 결과: 성공.
- 실행: `git diff --check`
- 결과: 공백 오류 없음. Windows checkout의 LF/CRLF 안내만 출력됨.

## 산출물

- 검증 기록: `artifacts/validation/issue-382/VALIDATION.md`
- 화면/API 캡처: 실제 Admin CRUD endpoint가 아직 없어 자동화된 MockMvc 계약 테스트로 대체했다.

## 남은 리스크

- 운영 환경에서 `ADMIN_USER_IDS`를 비워두면 모든 관리자 접근이 거부된다.
- 실제 관리자 앱 사용자 ID를 확인해 배포 환경 변수에 등록하고 서버를 재시작해야 한다.
- 이번 이슈는 공통 접근 제어 기반만 제공하며 실제 공지 관리 API와 화면은 후속 이슈다.

## 다음 작업

- 관리자 공지 목록·작성·수정·게시 상태 변경 API를 별도 이슈로 구현한다.
- 이후 Flutter 앱에 관리자 전용 공지 관리 화면을 추가한다.
