# Issue #131 Validation

검증일: 2026-07-26

## 작업 요약

- 이슈: #131 `[FE] fix: Android 최소 SDK 불일치로 인한 빌드 실패 수정`
- 브랜치: `fix/131-android-min-sdk`
- 담당 영역: Android 빌드 설정, 프론트엔드 기술 문서
- 제외 범위: `health` 패키지 다운그레이드, Flutter/Gradle/Kotlin 도구 체인 변경, iOS 및 Kakao SDK 변경
- 목표: `health` 13.3.1이 요구하는 Android API 26을 앱 최소 SDK로 적용해 일반 Flutter Android 빌드를 복구한다.

## 변경 파일

- `frontend/android/app/build.gradle`: `minSdkVersion`을 26으로 고정했다.
- `agents_docs/02_tech_stack.md`: Android 최소 지원 버전과 설정 근거를 API 26(Android 8.0), `health` 13.3.1 기준으로 정정했다.

## 공유 파일 / 계약 변경

- 공유 위험 파일: `agents_docs/02_tech_stack.md`
- API 계약 변경: 없음
- DB migration: 없음
- 환경 변수: 없음
- 외부 API: 없음

## 검증

- 실행: `flutter build apk --debug`
- 결과: 성공. 임시 Gradle 우회 설정 없이 `frontend/build/app/outputs/flutter-apk/app-debug.apk` 생성.
- 실행: `flutter analyze --no-fatal-infos`
- 결과: 성공. `No issues found`.
- 실행: `flutter test`
- 결과: 성공. 137개 테스트 전체 통과.
- 실행: API 36 Android 에뮬레이터에 APK 설치 후 `com.gamjamubwatna.frontend/.MainActivity` 실행
- 결과: 설치 성공, 앱의 온보딩 첫 화면 표시, `FATAL EXCEPTION` 없음.
- 실행하지 못한 명령: 없음
- 이유: 해당 없음

## 산출물

- 검증 기록: `artifacts/validation/issue-131/VALIDATION.md`
- 화면/API 캡처: `artifacts/validation/issue-131/android-launch.png`
- 기타: 없음

## 남은 리스크

- 최소 SDK 상향으로 Android 7.x(API 25 이하)는 더 이상 지원하지 않는다.
- 빌드 시 Flutter의 Built-in Kotlin 전환 및 일부 플러그인의 Kotlin Gradle Plugin 사용에 대한 향후 호환성 경고가 출력된다. 현재 빌드 결과에는 영향을 주지 않으며 별도 도구 체인 정비 이슈가 필요하다.
- 에뮬레이터 검증은 앱 기동 범위다. Kakao Maps 네이티브 렌더링은 기존 기술 문서에 적힌 대로 ARM64 실제 Android 기기에서 최종 확인해야 한다.

## 다음 작업

- 이어서 실행할 명령: `flutter build apk --debug`
- 확인해야 할 파일: `frontend/android/app/build.gradle`, `agents_docs/02_tech_stack.md`
- 조율이 필요한 사람 또는 이슈: Android 7.x 지원 종료를 릴리스 정책에 반영하고, Kotlin 마이그레이션 경고는 별도 이슈로 분리한다.
