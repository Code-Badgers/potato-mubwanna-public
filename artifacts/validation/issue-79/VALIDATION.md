# Issue #79 검증 기록

## 작업 목표

- 감자 도감 탭을 실제 화면으로 구현한다.
- #75 백엔드 API 응답 계약에 맞춰 프론트 도메인 모델, Repository, Riverpod Provider를 준비한다.
- `감자도감_메인`, `감자도감_대표_감자_변경`, `감자_상세_설명` 레퍼런스 흐름을 Flutter UI로 옮긴다.
- 감자 이미지는 아직 제공되지 않았으므로 이미지 영역은 빈 슬롯으로 유지한다.

## 진행한 작업

- `PotatoCollection`, `PotatoCollectionItem`, `PotatoRarity` 모델 추가
- `PotatoRepository.fetchMyPotatoes()` 추가
- `potatoCollectionProvider` 추가
- 감자 도감 메인 화면 구현
  - 대표 감자 카드
  - 오늘의 감자걸음 카드
  - 희귀도 필터
  - 나의 감자 도감 그리드
  - 감자 상세 바텀시트
  - 대표 감자 변경 바텀시트
- 감자 도감 위젯 테스트 갱신
- 화면 캡처 생성

## 검증 명령

```bash
cd frontend
/Users/mac/Documents/flutter/bin/flutter analyze
/Users/mac/Documents/flutter/bin/flutter test test/features/potato/potato_collection_screen_test.dart
/Users/mac/Documents/flutter/bin/flutter test
/Users/mac/Documents/flutter/bin/flutter test --update-goldens test/potato_collection_screenshot_test.dart
```

## 검증 결과

- `flutter analyze`: 통과
- `flutter test test/features/potato/potato_collection_screen_test.dart`: 통과
- `flutter test`: 통과
- 화면 캡처: `artifacts/validation/issue-79/potato_collection_main.png`

## 화면 캡처

- `potato_collection_main.png`: Provider를 테스트에서 오버라이드해 감자 도감 메인 화면을 캡처했다.

## 성능 검증 기록

이번 PR은 감자 도감 신규 UI 구현이므로 다음 항목을 우선 확인했다.

- `flutter analyze`로 불필요한 rebuild/const 누락 힌트를 확인했다.
- 화면 구현 중 `prefer_const_constructors`, `prefer_const_literals_to_create_immutables`, `unnecessary_const` 경고를 정리했다.
- 감자 이미지는 실제 asset을 렌더링하지 않고 안정적인 고정 크기 슬롯으로 두어 이미지 로딩 비용과 레이아웃 흔들림을 막았다.
- 그리드는 `SliverGrid.builder`를 사용해 화면에 필요한 카드만 lazy build되도록 했다.

실제 FPS, CPU, Memory 측정은 iOS/Android 실행 환경이 준비된 뒤 Flutter DevTools Performance 또는 Android Studio Profiler로 이어서 측정하는 것이 적절하다. Lighthouse는 Flutter Web을 Chrome으로 배포/실행했을 때 보조 지표로만 사용한다.

## 트러블슈팅 PAAR

### 1. Flutter 명령어 PATH 문제

- Problem: `dart format` 실행 시 `zsh: command not found: dart`가 발생했다.
- Analysis: 현재 Codex 쉘 PATH에는 Flutter SDK가 등록되어 있지 않았고, 사용 중인 SDK는 `/Users/mac/Documents/flutter/bin` 아래에 있었다.
- Action: `/Users/mac/Documents/flutter/bin/dart`, `/Users/mac/Documents/flutter/bin/flutter` 절대 경로로 포맷, 분석, 테스트를 실행했다.
- Result: Flutter 3.44.1 / Dart 3.12.1 환경에서 정상적으로 `flutter analyze`, `flutter test`를 수행했다.

### 2. 새 화면 전환 후 기존 placeholder 테스트 실패

- Problem: 기존 테스트가 `감자 도감` placeholder 문구를 기대했지만, 화면이 `ConsumerStatefulWidget` 기반 실제 UI로 바뀌며 `No ProviderScope found`와 텍스트 기대값 실패가 발생했다.
- Analysis: 기존 테스트는 `MaterialApp(home: PotatoCollectionScreen())`만 pump하고 있었고, 새 화면은 Riverpod Provider와 감자 도감 데이터가 필요하다.
- Action: 테스트를 `ProviderScope`로 감싸고 `potatoCollectionProvider`를 오버라이드해 획득/미획득 감자 데이터를 주입했다. placeholder 기대값 대신 대표 감자, 오늘의 감자걸음, 도감 그리드, 상세 바텀시트 동작을 검증하도록 바꿨다.
- Result: 감자 도감 단위 테스트와 전체 Flutter 테스트가 모두 통과했다.

### 3. 화면 캡처와 실제 백엔드 의존성 분리

- Problem: 실제 앱 실행 캡처는 로그인 상태와 백엔드 API 응답에 의존하므로 로컬 환경에 따라 화면이 로그인 안내나 로딩 상태로만 보일 수 있다.
- Analysis: 이번 PR의 핵심은 UI 레이아웃 검증이므로, 백엔드와 로그인 상태를 반드시 띄우기보다 동일한 API 모델 데이터를 테스트에서 주입하는 방식이 더 안정적이다.
- Action: 임시 golden test를 만들어 `potatoCollectionProvider`를 오버라이드하고, `potato_collection_main.png`를 생성했다. 캡처 생성 후 임시 테스트 파일은 삭제했다.
- Result: 재현 가능한 감자 도감 메인 화면 캡처를 validation 산출물로 남겼다.

### 4. Flutter test 캡처의 한글 폰트 제한

- Problem: golden test로 생성한 캡처에서 일부 한글이 네모 글리프로 표시됐다.
- Analysis: Flutter test 기본 렌더러가 한글 글리프를 포함하지 않는 테스트 폰트를 사용한다. 시스템 한글 폰트를 `FontLoader`로 로드해 재생성을 시도했지만, 테스트가 완료되지 않아 중단했다.
- Action: 자동 캡처는 레이아웃 검증 산출물로 유지하고, 실제 기기/Chrome에서의 한글 렌더링 캡처는 후속 실행 검증 항목으로 분리했다.
- Result: 현재 산출물은 배치, 카드 구조, 스크롤 영역 확인용으로 사용한다. 실제 한글 렌더링은 Flutter 앱 실행 환경에서 추가 확인이 필요하다.

## 남은 리스크

- 대표 감자 변경은 아직 API가 없어 UI 선택 상태만 보여준다.
- 오늘 걸음 수는 실제 HealthKit/Health Connect 연동 전이므로 정적 표시값이다.
- 감자 이미지 asset이 없어 빈 슬롯으로 렌더링한다.
- 실제 iOS/Android 성능 프로파일링은 기기 또는 시뮬레이터 실행 환경에서 후속으로 수행해야 한다.

## 후속 작업

- 대표 감자 변경 API 연동
- 감자 상세 API 연동
- 실제 걸음 수 Provider 분리 및 HealthKit/Health Connect 연결
- 감자 이미지 asset 반영
- iOS/Android에서 DevTools Performance 또는 Android Studio Profiler 캡처 추가
