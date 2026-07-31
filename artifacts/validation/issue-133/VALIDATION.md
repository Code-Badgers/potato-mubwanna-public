# Issue #133 Validation

## 작업 요약

- 이슈: #133 `[FE] chore: Android 앱 모듈 Built-in Kotlin 전환`
- 브랜치: `refactor/133-android-built-in-kotlin`
- 기준 브랜치: `origin/main` (`5eaabb2d5ed74241cd8da0250908c16130262399`)
- 목표: Android 앱 모듈을 Built-in Kotlin으로 전환하고 최신 `main`의 전체 Flutter 기능 및 API 36 실행 호환성을 재검증한다.
- 제외 범위: 외부 Flutter 플러그인 업그레이드, AGP new DSL 전환, API/DB/iOS/Dart 기능 변경

## 변경 파일

- `frontend/android/app/build.gradle`: 앱 모듈에 `com.android.built-in-kotlin`을 적용하고 Kotlin/JVM 17 compiler DSL을 사용한다.
- `frontend/android/settings.gradle`: AGP와 같은 Built-in Kotlin 버전을 선언하고 외부 플러그인용 KGP를 유지한다.
- `frontend/android/gradle.properties`: 외부 플러그인을 위한 전역 호환 모드를 유지한다.
- `agents_docs/02_tech_stack.md`: 단계적 Built-in Kotlin 전환 정책을 기록한다.

## 자동 검증

| 명령 | 결과 |
| --- | --- |
| `flutter pub get` | 성공 |
| `flutter analyze --no-fatal-infos --no-pub` | 성공, `No issues found` |
| `flutter test --no-pub` | 성공, 전체 203개 테스트 통과 |
| `flutter build apk --debug --no-pub` | 성공, `build/app/outputs/flutter-apk/app-debug.apk` 생성 |
| `adb install -r .../app-debug.apk` | 성공, API 36 에뮬레이터 설치 |
| `adb shell am start -W -n com.gamjamubwatna.frontend/.MainActivity` | 성공, 콜드 스타트 완료 |
| 앱 PID 대상 `adb logcat -d --pid=... '*:E'` | `FATAL EXCEPTION` 없음. Android의 비치명적 `ashmem` 폐기 안내만 확인 |

## 빌드 경고 판정

- 기존 앱 모듈 대상 `Your Android app project ... applies the Kotlin Gradle Plugin` 경고는 더 이상 출력되지 않는다.
- `device_info_plus`, `health`, `kakao_flutter_sdk_auth`, `kakao_flutter_sdk_common`, `mobile_scanner`는 아직 KGP를 적용해 Flutter의 외부 플러그인 경고가 남는다.
- Flutter 3.44.1의 KGP 탐지 훅이 Built-in Kotlin 모듈에서 레거시 `kotlin-android` 적용을 시도하며 `KGP was not found on the classpath` 안내를 출력하지만, 앱 컴파일과 APK 생성에는 영향을 주지 않았다.
- 일부 외부 플러그인의 Java 8 source/target 폐기 예정 경고가 남으며 이번 앱 모듈 전환 범위에는 포함하지 않는다.

## 실제 실행 검증

- 기기: `potato_pixel_7_api36` (`emulator-5554`)
- 앱 시작 화면이 정상 렌더링됐다.
- 시작 화면을 탭한 뒤 온보딩의 `지도로 감자 스팟 찾기` 단계로 정상 전환됐다.
- 화면 잘림, 겹침, 빈 화면, 앱 종료 또는 치명적 예외를 확인하지 못했다.

## 산출물

- `artifacts/validation/issue-133/app-launch-api36.png`
- `artifacts/validation/issue-133/after-start-api36.png`

## 잔여 리스크

- 외부 플러그인의 Built-in Kotlin 지원 버전이 제공되면 의존성을 올리고 `android.builtInKotlin=false` 호환 모드를 제거해야 한다.
- iOS 빌드와 실기기 검증은 Windows 환경에서 수행하지 않았다.

## 다음 작업

- PR #134에서 최신 `main` 병합 결과와 검증 로그를 확인하고 병합한다.
- 외부 플러그인 KGP 경고는 별도 의존성 호환성 이슈로 추적한다.
