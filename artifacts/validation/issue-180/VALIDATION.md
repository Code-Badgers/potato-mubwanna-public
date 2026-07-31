# Issue #180 Validation

## 작업 요약

- 이슈: #180
- 브랜치: `fix/180-session-bootstrap-routing`
- 담당 영역: Flutter 앱 시작 라우팅, 인증 세션 복구, 온보딩 완료 상태
- 제외 범위: #133, #176, #182의 Android Built-in 및 실기기 방문/푸시 QA
- 목표: 앱 재시작 시 저장된 세션을 복구하고 인증 판정 전 보호 화면 진입을 막는다.

## 변경 파일

- `frontend/lib/features/auth/application/session_startup_coordinator.dart`: 최초 라우트 판정과 중복 세션 복구 방지
- `frontend/lib/features/auth/presentation/screen/session_startup_screen.dart`: 인증 판정 중 시작 화면
- `frontend/lib/features/onboarding/data/onboarding_status_store.dart`: 온보딩 완료 상태 저장
- `frontend/lib/app/router/app_router.dart`: 최초 진입점을 `/startup`으로 변경
- `frontend/lib/app/router/session_startup_route_gate.dart`: 최초 딥링크를 인증 판정 뒤까지 보류
- `frontend/lib/app/app.dart`: 종료 상태 푸시를 시작 조정자로 이동하고 미인증 푸시 라우팅 차단
- `frontend/lib/features/onboarding/presentation/screen/onboarding_screen.dart`: 온보딩 완료 기록
- `frontend/lib/features/auth/presentation/screen/login_screen.dart`: 로그인 또는 게스트 진행 시 완료 기록
- `frontend/test/`: 세션 복구, 라우팅, 중복 처리, 완료 기록 회귀 테스트

## 공유 파일 / 계약 변경

- 공유 위험 파일: `frontend/lib/app/app.dart`, `frontend/lib/app/router/app_router.dart`
- 변경 이유: 인증 판정과 종료 상태 푸시 처리보다 보호 화면이 먼저 열리지 않도록 최초 라우트를 직렬화해야 한다.
- API 계약 변경: 없음
- DB migration: 없음
- 환경 변수: 없음
- 외부 API: 기존 `/auth/refresh` 계약만 사용

## 검증

- 실행: `flutter analyze`
- 결과: 성공, 정적 분석 이슈 없음
- 실행: `flutter test`
- 결과: 성공, 194개 테스트 통과
- 실행: `flutter build web`
- 결과: 성공
- 실행: 로컬 웹 빌드 데스크톱 및 390x844 모바일 브라우저 확인
- 결과: 첫 방문 온보딩 전환 정상, 화면 오버플로 없음
- 실행하지 못한 명령: 실기기 Kakao/Firebase 인증 및 종료 상태 푸시
- 이유: 실제 앱 키, 사용자 계정, Firebase 프로젝트와 Android/iOS 기기가 필요한 외부 검증이다.

## 시나리오

| 시나리오 | 기대 결과 | 결과 |
| --- | --- | --- |
| 첫 방문, refresh token 없음 | 온보딩 | 통과 |
| 온보딩 완료, refresh token 없음 | 로그인 | 통과 |
| refresh token 갱신 성공 | 메인 지도 | 통과 |
| refresh token 갱신 실패 | 로컬 인증 토큰 삭제 후 로그인 | 통과 |
| 종료 상태 푸시 + 세션 복구 성공 | 인증 복구 후 푸시 목적지 | 통과 |
| 시작 처리 동시 호출 | refresh 1회 | 통과 |
| Kakao 웹 callback | 저장 세션보다 callback 로그인 우선 | 통과 |

## 산출물

- 검증 기록: `artifacts/validation/issue-180/VALIDATION.md`
- 화면/API 캡처: 브라우저 수동 확인, 저장 캡처 없음
- 기타: 없음

## 남은 리스크

- 실제 만료 refresh token, 네트워크 단절, Firebase 종료 상태 푸시 조합은 실기기 환경에서 최종 확인이 필요하다.
- 웹 빌드의 Wasm dry run은 기존 `flutter_secure_storage_web`, `geolocator_web` 호환성 경고를 출력하지만 JavaScript 웹 빌드는 성공했다.

## 다음 작업

- 이어서 실행할 명령: `flutter test && flutter build web`
- 확인해야 할 파일: `frontend/lib/features/auth/application/session_startup_coordinator.dart`
- 조율이 필요한 사람 또는 이슈: 실기기 푸시 검증 #176, 방문 인증 QA #182
