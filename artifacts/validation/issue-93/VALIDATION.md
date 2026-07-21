# Issue 93 Validation

## 작업 요약

- 이슈: #93 `[FE] 보상함 보상 히스토리 실데이터 연동`
- 브랜치: `feat/93-reward-history-ui`
- 담당 영역: Team A 프론트엔드 보상함
- 제외 범위: 백엔드 API/DB, 보상 지급 정책, Team B 감자 기능
- 목표: `GET /api/rewards/history` 응답을 보상함에서 최신순으로 표시하고 로딩, 빈 상태, 오류 재시도, 세션 변경을 안전하게 처리한다.

## 진행 과정

1. 기존 원격 브랜치의 모델, 저장소, Riverpod provider, 보상함 UI와 테스트를 검토했다.
2. 브랜치가 최신 `main`보다 4커밋 뒤에 있어 `origin/main`을 rebase했다.
3. `frontend/lib/core/constants/api_paths.dart`에 추가된 감자 성장 경로와 `rewardHistory` 경로가 함께 유지되는 것을 확인했다.
4. 보상 히스토리 저장소, 세션 캐시, 화면 상태 테스트를 실행했다.
5. 검증용 provider preview를 Chrome 430x932 뷰포트에서 실행하고 보상 내역 탭을 캡처했다.

## 변경 파일 요약

- `frontend/lib/core/constants/api_paths.dart`: `/rewards/history` 경로 추가.
- `frontend/lib/features/reward/domain/reward_history.dart`: 보상 유형, 지급 경로, 지급 시각 모델과 API 매핑 추가.
- `frontend/lib/features/reward/data/reward_history_repository.dart`: 인증된 사용자의 보상 히스토리 조회 구현.
- `frontend/lib/features/reward/application/reward_history_controller.dart`: 세션 변경 시 폐기되는 `autoDispose` provider 추가.
- `frontend/lib/features/coupon/presentation/screen/coupon_screen.dart`: 쿠폰과 보상 내역을 전환하는 segmented control, 목록, 로딩, 빈 상태, 오류 재시도 UI 추가.
- `frontend/test/features/reward/`: 저장소와 세션 캐시 테스트 추가.
- `frontend/test/features/coupon/coupon_screen_test.dart`: 보상 내역 렌더링, 접근성, 큰 글자, 로딩, 빈 상태, 오류 재시도 테스트 추가.
- `artifacts/validation/issue-93/reward_history_preview.dart`: 모바일 웹 검증용 provider preview.
- `artifacts/validation/issue-93/reward-history-mobile.png`: 보상 내역 탭 모바일 캡처.

## 검증 결과

| 명령 / 검증 | 결과 |
| --- | --- |
| `flutter pub get` | PASS |
| `flutter test --no-pub test/features/reward test/features/coupon/coupon_screen_test.dart` | PASS, 16 tests |
| `flutter analyze --no-pub` | PASS, no issues |
| `flutter test --no-pub` | PASS, 115 tests |
| `flutter build web --profile --no-pub` | PASS, `frontend/build/web` 생성 |
| `flutter run -d web-server --web-hostname 127.0.0.1 --web-port 18393 --target ..\artifacts\validation\issue-93\reward_history_preview.dart` | PASS |
| Chrome 430x932에서 `보상 내역` 탭 선택 | PASS, 카드와 레이블의 잘림/겹침 없음 |

## 발생한 문제와 해결

- 번들 Playwright에 전용 Chromium 실행 파일이 없어 최초 자동 캡처가 실패했다.
  - 해결: 별도 브라우저를 다운로드하지 않고 설치된 Chrome 실행 파일을 Playwright에 지정해 검증했다.
- 기존 브랜치와 최신 `main`이 모두 `api_paths.dart`를 수정하고 있었다.
  - 해결: rebase 결과 충돌 없이 감자 성장 API 경로와 보상 히스토리 경로가 모두 유지되는 것을 확인했다.
- Web profile build에서 Cupertino icon font와 WebAssembly 호환성 경고가 출력됐다.
  - 결과: 기존 의존성 구성에서 발생하는 비차단 경고이며 JavaScript Web build는 성공했다.

## 화면 검증

- `reward-history-mobile.png`
  - 430x932 뷰포트에서 `쿠폰 / 보상 내역` segmented control이 안정적으로 유지된다.
  - 쿠폰과 감자 보상의 유형, 지급 경로, 지급 시각이 한글로 표시된다.
  - 두 카드 사이 간격, 긴 보상명, 칩 레이아웃에서 잘림과 겹침이 없다.
- 큰 글자 2배, 로딩, 빈 상태, 오류 재시도는 widget test로 검증했다.

## 공유 파일 / 계약 변경

- 공유 위험 파일: `frontend/lib/core/constants/api_paths.dart`
- 변경 이유: 기존 계약 `GET /api/rewards/history`를 호출하는 경로 상수 1건 추가.
- API 계약 변경: 없음. `agents_docs/07_api_specification.md`의 기존 응답을 그대로 사용한다.
- DB migration, 환경 변수, 외부 API 변경: 없음.
- PR #101도 같은 경로 파일을 수정하므로 병합 순서에 따라 최신 `main` 반영 여부를 다시 확인한다.

## 남은 리스크

- 실제 백엔드 로그인 세션과 운영형 보상 데이터로 end-to-end 호출하지 못했다. 저장소 테스트와 인증 provider preview로 API 매핑과 화면 렌더링을 대체 검증했다.
- PR #101이 먼저 병합되면 `api_paths.dart`에 `potatoDailyActivity` 경로가 추가되므로 #93 브랜치에서 해당 변경을 다시 반영해야 한다.

## 다음 작업

- PR 생성 후 #101과 공유 파일 중복을 리뷰 중점사항에 명시한다.
- #101이 먼저 병합되면 최신 `main`을 다시 반영하고 전체 Flutter 검증을 재실행한다.
