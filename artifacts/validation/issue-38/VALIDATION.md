# Issue 38 Validation

## 작업 목표

- Team B 담당 범위의 점순이 미션 MVP 화면을 구현한다.
- `artifacts/local-runtime/점순이 미션.txt`의 미션 제목, 타입, 조건, 보상, 대사를 기반으로 앱 내부 미션 콘텐츠 구조를 만든다.
- `agents_docs/design_references/미션` 이미지는 레이아웃 참고용으로만 사용하고, 점순이 캐릭터, 감자 캐릭터, 배경 이미지는 제외한다.

## 진행 과정

1. 최신 `main`에서 `feat/38-mission` 브랜치를 생성했다.
2. GitHub Issue #38을 만들고 작업 범위와 제외 범위를 기록했다.
3. 미션 도메인 모델, mock repository, Riverpod provider를 추가했다.
4. 기존 placeholder 미션 화면을 미션 목록, 필터, 상세, 완료 보상 모달로 교체했다.
5. 미션 화면 widget test를 추가했다.
6. 추가 이미지 요청 사항은 `artifacts/local-runtime/mission_asset_requests.md`에 로컬 기록으로 남겼다.

## 발생한 문제와 해결

- `gh`가 PATH에 잡히지 않아 이슈 생성이 처음 실패했다. `/usr/local/bin/gh` 직접 경로로 실행해 Issue #38을 생성했다.
- `flutter test`를 `flutter analyze`와 병렬 실행했을 때 Flutter startup lock과 ephemeral 파일 삭제 충돌이 발생했다. 순차 실행으로 재검증했다.
- Widget test가 첫 뷰포트 밖의 미션 카드를 바로 찾으면서 실패했다. 실제 스크롤 가능한 화면 구조에 맞게 `scrollUntilVisible`을 사용하도록 수정했다.
- Playwright 패키지는 있었지만 브라우저 바이너리가 설치되어 있지 않아 첫 캡처 시도가 실패했다. 시스템 Chrome 실행 파일을 지정해 캡처했다.
- Flutter Web은 텍스트를 DOM으로 직접 노출하지 않아 Playwright `getByText` 클릭이 실패했다. 모바일 뷰포트 좌표 클릭으로 상세/보상 화면을 캡처했다.
- PR 리뷰에서 완료된 미션도 다시 완료 버튼을 누를 수 있다는 지적이 있었다. `MissionStatus.completed` 상태는 완료 액션을 비활성화하고 버튼 문구를 `완료된 미션`으로 보여주도록 수정했다.

## 변경 파일 요약

- `frontend/lib/features/mission/domain/mission_challenge.dart`: 미션 그룹, 타입, 상태, 보상 타입, 미션 도메인 모델 추가
- `frontend/lib/features/mission/data/mission_repository.dart`: 점순이 txt 기반 MVP 미션 mock 데이터 추가
- `frontend/lib/features/mission/application/mission_controller.dart`: Riverpod provider 추가
- `frontend/lib/features/mission/presentation/screen/mission_screen.dart`: 미션 목록, 필터, 상세, 보상 모달 UI 구현
- `frontend/test/features/mission/mission_screen_test.dart`: 목록/필터/상세/보상 모달 widget test 추가
- `artifacts/local-runtime/mission_asset_requests.md`: 커밋 제외 로컬 이미지 요청 기록
- `frontend/lib/features/mission/presentation/screen/mission_screen.dart`: 완료 미션 액션 비활성화
- `frontend/test/features/mission/mission_screen_test.dart`: 완료 미션 중복 보상 방지 테스트 추가

## 검증

- `cd frontend && /Users/mac/Documents/flutter/bin/dart format lib/features/mission test/features/mission`: 성공
- `cd frontend && /Users/mac/Documents/flutter/bin/flutter analyze`: 성공
- `cd frontend && /Users/mac/Documents/flutter/bin/flutter test test/features/mission/mission_screen_test.dart`: 성공
- `cd frontend && /Users/mac/Documents/flutter/bin/flutter build web --no-wasm-dry-run`: 성공
- `python3 -m http.server 54638 --bind 127.0.0.1`: 성공
- Playwright + 시스템 Chrome으로 `http://127.0.0.1:54638/#/main/missions` 화면 캡처: 성공
- `cd frontend && /Users/mac/Documents/flutter/bin/flutter analyze`: 성공. 완료 미션 비활성화 리뷰 반영 후 재검증했다.
- `cd frontend && /Users/mac/Documents/flutter/bin/flutter test test/features/mission/mission_screen_test.dart`: 성공. 완료 미션 버튼 비활성화 회귀 테스트를 포함한다.
- `cd frontend && /Users/mac/Documents/flutter/bin/flutter build web --no-wasm-dry-run`: 성공. 리뷰 반영 후 Web build를 재생성했다.
- Playwright + 시스템 Chrome으로 완료 미션 비활성화 화면 캡처: 성공

## 캡처

- `artifacts/validation/issue-38/mission-list-web.png`
- `artifacts/validation/issue-38/mission-detail-web.png`
- `artifacts/validation/issue-38/mission-reward-web.png`
- `artifacts/validation/issue-38/mission-list-review-fix-web.png`
- `artifacts/validation/issue-38/mission-daily-filter-web.png`
- `artifacts/validation/issue-38/mission-completed-disabled-web.png`

## 남은 리스크

- 현재 미션 데이터는 프론트 mock repository 기반이다. 백엔드 API, DB migration, 실제 완료 상태 저장은 후속 작업이 필요하다.
- QR, OCR, GPS, 걸음 수 인증은 실제 센서/권한/API 연동 전의 UI 흐름만 구현했다.
- 미션 완료 모달은 로컬 상태를 영구 저장하지 않는다. API 연동 후 완료 상태와 보상 지급 결과를 서버 응답 기준으로 바꿔야 한다.
- 작업 시작 전부터 수정 상태였던 iOS Xcode 메타파일 2개는 이번 이슈와 무관하여 커밋하지 않는다.
