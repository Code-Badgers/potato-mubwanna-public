# Issue #85 웹 지도 최초 진입 초기화 오류 검증

## 검증 범위

- 웹에서 지도 화면으로 직접 진입했을 때 Kakao Map이 첫 시도에 표시되는지 확인
- 같은 주소를 새로고침해도 별도 탭 이동 없이 지도가 다시 표시되는지 확인
- DOM 레이아웃이 늦게 확정되는 동안 초기화를 재시도하고, 위젯 해제 시 대기를 중단하는지 확인
- 기존 지도 화면 테스트와 Flutter 전체 회귀 테스트 확인

## 원인과 수정

`HtmlElementView`가 생성된 뒤 고정 80ms만 기다리고 지도 요소의 크기를 검사했다. Flutter 웹의 첫 진입에서는 DOM 배치가 그보다 늦어질 수 있어, 실제 크기는 이후 `1248 x 636`으로 확정되는데도 `0 x 0` 상태에서 초기화 실패가 확정됐다.

지도 요소의 너비와 높이가 모두 양수가 될 때까지 50ms 간격으로 최대 40회 확인하도록 변경했다. 위젯이 먼저 해제되면 즉시 대기를 중단하며, 제한 시간 안에 레이아웃이 확정되지 않을 때만 기존 오류 안내를 표시한다.

## 자동 검증

### 지도 레이아웃 집중 테스트

```powershell
cd frontend
flutter test test\features\map\map_layout_waiter_test.dart test\features\map\map_screen_test.dart
```

결과: `6 tests passed`

- 두 번의 0 크기 이후 양수 크기가 생기면 초기화 가능한 상태를 반환하는지 검증
- 위젯이 해제된 상태에서는 남은 재시도를 중단하는지 검증
- 기존 지도 화면의 로딩, 오류, 관광지 선택 흐름 회귀 확인

### 정적 분석

```powershell
cd frontend
flutter analyze
```

결과: `No issues found`

### Flutter 전체 회귀 테스트

```powershell
cd frontend
flutter test
```

결과: `92 tests passed`

### 웹 빌드

```powershell
cd frontend
flutter build web `
  --dart-define=KAKAO_JAVASCRIPT_KEY=<runtime-key> `
  --dart-define=API_BASE_URL=http://localhost:8080/api
```

결과: `Built build\web`, 빌드 성공

기존 의존성의 WebAssembly 호환성 안내와 `CupertinoIcons` 글꼴 안내가 출력됐지만 빌드 실패나 이번 변경의 오류는 없었다.

## Gemini 리뷰 반영

- 초기화 post-frame callback이 실행되기 전에 위젯이 해제될 수 있으므로 메서드 시작 시 `mounted`를 확인하도록 보완했다.
- Kakao SDK 비동기 대기 중 위젯이 해제된 뒤 예외가 발생할 수 있으므로 오류 안내를 표시하기 전에도 `mounted`를 확인한다.
- 반영 후 지도 집중 테스트 6건, 정적 분석, Flutter 전체 테스트 92건을 다시 실행해 모두 통과했다.

## 실제 런타임 검증

- 로컬 PostgreSQL과 Redis, Spring Boot API를 실행하고 `정선 5일장` 테스트 관광지를 준비했다.
- 승인된 Kakao JavaScript 키는 실행 프로세스 인자로만 전달했으며 파일이나 검증 기록에 저장하지 않았다.
- Chrome에서 `http://localhost:54631/#/main/map`으로 직접 진입했다.
- 첫 진입에서 지도 요소가 `1248 x 636`으로 초기화되고 Kakao 지도와 `정선 5일장` 카드가 표시됐다.
- 같은 주소를 다시 로드한 뒤에도 지도 요소가 `1248 x 636`으로 초기화됐다.
- 두 경우 모두 지도 SDK가 로드됐고 `지도 화면을 준비하지 못했습니다` 오류는 표시되지 않았다.
- 기존에 필요했던 다른 탭 이동 후 복귀 과정 없이 정상 동작했다.

## 변경 파일

- `frontend/lib/features/map/presentation/widget/kakao_map_view_web.dart`
- `frontend/lib/features/map/presentation/widget/map_layout_waiter.dart`
- `frontend/test/features/map/map_layout_waiter_test.dart`
- `artifacts/validation/issue-85/VALIDATION.md`

## 제외 범위

- Kakao 지도 SDK 로더와 키 관리 방식 변경
- 지도 디자인, 마커, 필터 또는 관광지 카드 기능 변경
- iOS와 Android 네이티브 지도 구현 변경
