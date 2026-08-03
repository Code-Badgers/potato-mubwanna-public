# Issue #231 validation

## 작업 요약

- 이슈: #231 `[FE] fix: 동시 401 요청의 refresh token 갱신 단일화`
- 브랜치: `fix/231-concurrent-auth-refresh`
- 담당 영역: 공통 인증 interceptor의 access token 만료 복구
- 제외 범위: UI, 라우터, 로그인·온보딩 화면, 백엔드 토큰 정책, API 계약
- 목표: 여러 보호 API가 동시에 401을 받아도 refresh token을 한 번만 회전하고 모든 요청을 복구한다.

## 변경 파일

- `frontend/lib/core/network/auth_interceptor.dart`: 진행 중 refresh Future를 공유하고, 다른 요청이 이미 회전한 access token을 후발 401 요청이 재사용한다.
- `frontend/test/core/network/auth_interceptor_test.dart`: 동시·지연 401, refresh 실패, 재시도 차단을 실제 로컬 HTTP 요청으로 검증한다.

## 공유 파일 / 계약 변경

- 공유 위험 파일: `frontend/lib/core/network/auth_interceptor.dart`
- 조율: open PR #209의 변경 파일을 확인했으며 `auth_interceptor.dart` 및 새 테스트와 겹치지 않는다. #209가 수정하는 `token_storage.dart`, `auth_controller.dart`는 변경하지 않았다.
- API 계약 변경: 없음
- DB migration: 없음
- 환경 변수: 없음
- 외부 API: 없음

## 검증

- 최초 재현: 수정 전 동시 보호 요청 2건 중 1건이 원래 401로 실패해 테스트가 실패했다.
- 실행: `flutter test test/core/network/auth_interceptor_test.dart`
- 결과: 동시 성공, 지연 401, refresh 실패, auth/retry 제외 4개 테스트 통과
- 실행: 같은 동시성 테스트 파일 5회 반복
- 결과: 5회 모두 통과
- 실행: `flutter test test/features/auth test/app/router/session_startup_route_gate_test.dart`
- 결과: 인증·초기 세션 관련 30개 테스트 통과
- 실행: `flutter analyze`
- 결과: 이슈 없음
- 실행: `flutter test`
- 결과: 전체 230개 테스트 통과
- 실행하지 못한 명령: 없음
- 이유: 해당 없음

## 산출물

- 검증 기록: 이 문서
- 화면/API 캡처: UI 변경이 없어 없음
- 기타: 로컬 `HttpServer`가 실제 백엔드와 같은 refresh token 1회 회전 조건을 재현한다.

## 남은 리스크

- refresh 실패 후 로그인 화면 전환은 기존 전역 인증 정책 범위이며 이번 이슈에서 변경하지 않았다.
- multipart/stream request body 재시도 가능 여부는 기존 interceptor 동작과 동일하며 이번 동시성 범위가 아니다.

## 다음 작업

- 이어서 실행할 명령: 최신 `origin/main` 확인 후 커밋·push·PR 생성
- 확인해야 할 파일: `frontend/lib/core/network/auth_interceptor.dart`, `frontend/test/core/network/auth_interceptor_test.dart`
- 조율이 필요한 사람 또는 이슈: 전체 테스트 통과 후 PR을 올리고 사용자에게 머지 요청
