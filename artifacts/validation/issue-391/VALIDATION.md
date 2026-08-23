# Issue #391 검증 기록

## 작업 요약

- 이슈: #391 `[FE] feat: 관리자 공지 관리 화면 및 권한별 진입 제어`
- 브랜치: `feat/391-admin-notice-screen`
- 담당 영역: Flutter 관리자 공지 조회·작성·수정·게시 상태 전환, 권한별 메뉴 노출
- 제외 범위: 공지 삭제·예약 게시, 미션·쿠폰·감자 관리자 CRUD, 백엔드·DB 변경
- 목표: 서버가 관리자 권한을 확인한 사용자만 앱에서 공지를 관리할 수 있게 한다.

## 변경 내용

- `GET /api/admin/notices` 성공을 관리자 진입 권한의 근거로 사용한다.
- 관리자에게만 마이페이지의 `관리자 공지 관리` 메뉴를 노출한다.
- 직접 `/admin/notices`를 열어도 `401/403`이면 권한 없음 화면을 표시한다.
- 전체·게시·숨김 공지 요약, 목록, 빈 상태, 네트워크 오류 상태를 구현했다.
- 기존 앱과 같은 민트·크림 톤, 공통 카드 반경·그림자, 초록 주요 버튼을 적용했다.
- 공지 작성·수정과 게시/숨김 전환을 관리자 API에 연결했다.

## 공유 파일 / 계약 변경

- 공유 위험 파일: `frontend/lib/app/router/app_router.dart`, `frontend/lib/features/mypage/presentation/screen/my_page_screen.dart`
- API 계약: 변경 없음. 기존 관리자 공지 API를 사용한다.
- DB migration: 없음.
- 환경 변수: 없음. 서버의 기존 `ADMIN_USER_IDS` 설정을 사용한다.
- 외부 API: 없음.

## 검증

- `flutter analyze`
  - 성공, `No issues found`.
- `flutter test test/features/admin_notice test/features/mypage/my_page_screen_test.dart`
  - 성공, 관련 테스트 18개 통과.
- `flutter test`
  - 성공, 프런트 전체 테스트 310개 통과.
- `flutter build web`
  - 성공, `build/web` 생성.
  - 기존 패키지의 WebAssembly 호환성 경고와 미사용 Cupertino 아이콘 폰트 경고만 발생했다.
- 430×932 브라우저 검증
  - 관리자 공지 목록, 요약 카드, 게시 스위치, 공지 작성 바텀시트의 오버플로 없음.
- `git diff --check`
  - 성공, 공백 오류 없음.

## 화면 캡처

- `admin-notice-list.png`: 공지 현황·목록·게시 상태 화면
- `admin-notice-editor.png`: 새 공지 작성 화면

## 진행 중 발생한 문제

- Flutter Web 첫 브라우저 탐색이 제한 시간 안에 응답하지 않았지만 탭과 앱 서버는 정상 생성되어 있었다.
  - 생성된 탭을 다시 사용해 렌더링·콘솔 오류·스크린샷을 확인했다.
- 로컬 `노션토큰.txt`를 읽어 Notion API에 기록하는 요청은 실행 정책에 차단됐다.
  - GitHub Issue #391과 이 검증 문서를 작업 기록 기준으로 남겼으며, Notion은 연결 가능한 환경에서 후속 동기화가 필요하다.

## 남은 리스크

- 운영 환경에서 `ADMIN_USER_IDS`에 실제 앱 사용자 ID가 설정되어 있어야 관리자 메뉴가 나타난다.
- 권한 확인을 관리자 공지 전체 조회와 함께 수행하므로 관리자 API가 일시 장애이면 관리자 메뉴도 잠시 숨겨진다.
- 실제 운영 관리자 계정으로 작성·수정·게시 전환하는 최종 스모크 테스트가 필요하다.

## 다음 작업

- PR 병합 후 운영/스테이징 서버의 `ADMIN_USER_IDS` 설정과 관리자 계정 ID를 확인한다.
- 실제 관리자 계정에서 마이페이지 메뉴 노출, 공지 등록, 일반 사용자 공지 반영을 확인한다.
- Notion 작업 페이지에 이슈 #391, PR, 검증 결과를 동기화한다.
