# Issue #195 Validation

## 이슈

- GitHub Issue: `#195 [QA] test: Team B 핵심 루프 통합 QA`
- Branch: `test/195-team-b-core-loop-qa`
- 작업일: 2026-08-02

## QA 목표

Team B가 담당한 지도, 방문 인증, 감자 도감, 점순이 미션, 외부 스팟 데이터 흐름이 MVP 핵심 루프로 자연스럽게 이어지는지 확인한다.

검증할 핵심 루프:

1. 지도에서 감자 스팟을 찾는다.
2. 스팟 핀을 선택하고 장소 카드를 확인한다.
3. 방문 인증을 수행한다.
4. 스탬프와 감자를 획득한다.
5. 추천 장소 또는 점순이 미션으로 이어진다.
6. 미션 완료 또는 감자 성장 결과가 도감/보상 흐름에 반영된다.

## PAAR 기록

### Problem

기능별 이슈는 대부분 완료됐지만, 사용자가 실제로 앱을 사용할 때 여러 기능이 한 흐름으로 연결되는지는 별도 검증이 필요하다. 특히 지도 핀 선택, 위치 권한, 방문 인증 결과, 감자 획득, 미션 진입, 감자 도감 반영은 서로 다른 화면과 API가 연결되므로 단일 기능 테스트만으로는 품질을 보장하기 어렵다.

### Analysis

이번 QA는 새 기능 구현보다 회귀 방지와 통합 흐름 확인이 목적이다. 따라서 먼저 자동화 가능한 백엔드/프론트 테스트를 실행하고, 로컬 환경에서 실행이 어려운 실기기 항목은 명확한 체크리스트와 남은 리스크로 분리한다. 실패 항목이 나오면 숨기지 않고 재현 방법과 후속 이슈 후보를 기록한다.

### Action

- [x] 백엔드 전체 테스트 실행
- [x] 프론트 전체 테스트 실행
- [x] Flutter 정적 검사 실행
- [x] 지도/스팟 데이터 품질 회귀 테스트 확인
- [x] 방문 인증 API 회귀 테스트 확인
- [x] 감자 도감/성장 API 회귀 테스트 확인
- [x] 미션 인증 API 회귀 테스트 확인
- [x] Web build 확인
- [x] iOS simulator build 확인
- [x] Android debug APK build 확인

### Result

- 자동화 가능한 범위의 백엔드/프론트 회귀 검증은 통과했다.
- 실제 위치, Kakao 로그인, Kakao Map 네이티브 렌더링, HealthKit/Health Connect, QR 카메라 스캔은 실기기 환경에서 추가 확인이 필요하다.

## QA 매트릭스

### Backend

| 영역 | 확인 항목 | 결과 | 메모 |
| --- | --- | --- | --- |
| 지도 / 스팟 | 수동 큐레이션, TourAPI, Kakao Local 기반 스팟 테스트 | 통과 | 전체 백엔드 테스트에 포함 |
| 방문 인증 | 위치 거리 계산, 스탬프/감자 획득, 추천 장소 응답 | 통과 | 전체 백엔드 테스트에 포함 |
| 감자 도감 | 카탈로그, 내 도감, 대표 감자, 성장 요약 | 통과 | 전체 백엔드 테스트에 포함 |
| 점순이 미션 | 퀴즈, QR, 사진, 걷기 인증 정책 | 통과 | 전체 백엔드 테스트에 포함 |
| 보상 연결 | 미션 보상, 쿠폰 지급, 보상 히스토리 | 통과 | Team A 영역과 맞물리는 연결 지점도 전체 테스트로 확인 |

### Frontend

| 영역 | 확인 항목 | 결과 | 메모 |
| --- | --- | --- | --- |
| 지도 / 스팟 | 핀 렌더링, 필터, 핀 클릭 카드 갱신 | 통과 | widget/unit 테스트 기준 |
| 방문 인증 | 권한 안내, 성공/실패 바텀시트 | 통과 | widget 테스트 기준 |
| 감자 도감 | 대표 감자, 상세, 성장 피드백 | 통과 | widget/controller 테스트 기준 |
| 점순이 미션 | 미션 목록, 타입별 입력, 완료 상태 | 통과 | widget/controller 테스트 기준 |
| 플랫폼 | Web/iOS/Android 빌드 가능성 | 통과 | Web build, iOS simulator build, Android debug APK build 통과 |

## 실행 명령과 결과

### Backend

- `cd backend && ./gradlew test`
  - 성공
  - 358 tests, failures 0, errors 0, skipped 0
  - 지도/스팟, 방문 인증, 감자 도감/성장, 미션, 보상 연결 테스트가 함께 실행됐다.

### Frontend

- `cd frontend && /Users/mac/Documents/flutter/bin/flutter analyze --no-fatal-infos`
  - 성공
  - `No issues found`
  - PATH에 `flutter`가 없어 최초 `flutter analyze --no-fatal-infos`는 실행되지 않았다. 로컬 Flutter SDK 절대 경로를 사용해 해결했다.
- `cd frontend && /Users/mac/Documents/flutter/bin/flutter test --no-pub`
  - 성공
  - 211 tests 통과
- `cd frontend && /Users/mac/Documents/flutter/bin/flutter build web --no-pub --dart-define=KAKAO_JAVASCRIPT_KEY=dummy --dart-define=KAKAO_NATIVE_APP_KEY=dummy --dart-define=API_BASE_URL=http://localhost:8080`
  - 성공
  - `build/web` 생성
  - Wasm dry run에서 `flutter_secure_storage_web`, `geolocator_web`의 `dart:html` / `dart:js_util` 호환 경고가 발생했다. 현재 JS web build는 성공했지만 Wasm 전환 시 별도 대응이 필요하다.
- `cd frontend && /Users/mac/Documents/flutter/bin/flutter build apk --debug --no-pub --dart-define=KAKAO_JAVASCRIPT_KEY=dummy --dart-define=KAKAO_NATIVE_APP_KEY=dummy --dart-define=API_BASE_URL=http://10.0.2.2:8080`
  - 성공
  - `build/app/outputs/flutter-apk/app-debug.apk` 생성
  - Kotlin Gradle Plugin 적용 경고와 Java 8 target 경고가 남아 있다. 현재 debug APK 생성에는 영향이 없었다.
- `cd frontend && /Users/mac/Documents/flutter/bin/flutter build ios --simulator --no-pub --dart-define=KAKAO_JAVASCRIPT_KEY=dummy --dart-define=KAKAO_NATIVE_APP_KEY=dummy --dart-define=API_BASE_URL=http://localhost:8080`
  - 최초 실패: Xcode Swift Package Manager dependency resolve가 아직 완료되지 않은 상태였다.
  - `cd frontend/ios && xcodebuild -resolvePackageDependencies -workspace Runner.xcworkspace -scheme Runner -sdk iphonesimulator`
    - 성공
  - 재실행 후 성공
  - `build/ios/iphonesimulator/Runner.app` 생성
  - UIScene lifecycle 지원 필요 경고가 남아 있다.

## 산출물

- `VALIDATION.md`: 이 문서
- 추가 스크린샷: 이번 커밋에서는 생성하지 않았다. 이번 QA는 자동 테스트와 플랫폼 빌드 중심이며, 실제 Web/iOS/Android 화면 캡처는 환경 변수와 실행 디바이스가 준비된 후 별도 실기기 QA로 진행하는 것이 정확하다.

## 남은 리스크

- 실제 위치, HealthKit/Health Connect, Kakao 로그인, Kakao Map native SDK는 로컬 자동 테스트만으로 충분히 검증되지 않는다.
- iOS/Android 실기기 QA는 개발자 인증서, 환경 변수, 실제 권한 팝업 상태에 영향을 받는다.
- 외부 API 기반 데이터는 API 쿼터, 원천 데이터 변경, 좌표 품질에 따라 결과가 달라질 수 있다.
- Web Wasm build는 현재 일부 플러그인 호환 경고가 있다. 일반 JS web build는 성공했다.
- Android debug build는 성공했지만 일부 플러그인의 Kotlin Gradle Plugin 적용 방식과 Java 8 target 경고가 남아 있다.
- iOS simulator build는 성공했지만 향후 iOS 버전 대응을 위해 UIScene lifecycle migration이 필요하다.

## 후속 이슈 후보

- `[FE] test: iOS/Android 실기기 핵심 루프 화면 캡처 QA`
  - 실제 Kakao 키, API 서버, 위치 권한, QR 카메라, HealthKit/Health Connect를 연결해 화면 단위로 캡처한다.
- `[FE] chore: Flutter Web Wasm 호환성 경고 정리`
  - `flutter_secure_storage_web`, `geolocator_web` 등 Wasm dry run 경고의 영향도를 확인한다.
- `[FE] chore: Android Kotlin Gradle Plugin 경고 정리`
  - Flutter 최신 빌드 정책에서 실패로 승격될 수 있는 KGP 경고를 플러그인 버전 또는 Gradle 설정으로 정리한다.
- `[FE] chore: iOS UIScene lifecycle migration`
  - 향후 iOS 실행 요구사항 변경에 대비해 Runner의 lifecycle 구성을 점검한다.
