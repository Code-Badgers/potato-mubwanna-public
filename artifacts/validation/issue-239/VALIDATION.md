# Issue #239 validation

## 작업 요약

- 이슈: `#239 [FE] fix: Android 에뮬레이터 Kakao Map ARM64 실행 자동화`
- 브랜치: `fix/239-android-arm64-map-emulator`
- 담당 영역: Windows Android 에뮬레이터에서 Kakao Map을 표시하는 로컬 실행 절차
- 제외 범위: 화면 UI, 지도 기능 코드, API/DB 계약, SDK·Flutter·Gradle 버전 변경
- 목표: Kakao Map 네이티브 라이브러리가 없는 x86_64 앱 설치로 지도가 비어 보이는 문제를 피하고, ARM64 앱 설치와 로컬 백엔드 연결을 한 번에 재현한다.

## 원인과 해결

- 확인된 원인: 기존 에뮬레이터 설치 앱의 주 ABI는 `x86_64`였지만 Kakao Map 네이티브 라이브러리 `libK3fAndroid.so`는 APK의 ARM ABI 디렉터리에만 있었다.
- 해결: 디버그 APK를 빌드한 뒤 `adb install --abi arm64-v8a`로 설치 ABI를 고정한다.
- 로컬 API 주소가 `localhost` 계열이면 `adb reverse`를 자동으로 설정해 에뮬레이터에서 호스트 백엔드에 접근하게 한다.
- 환경 변수는 `.env`에서 읽되 값은 출력하거나 저장소에 기록하지 않는다.

## 변경 파일

- `frontend/tool/run_android_arm64_emulator.ps1`: 환경·기기 확인, APK 빌드, ARM64 강제 설치, localhost 포트 연결, 앱 시작 자동화
- `frontend/README.md`: Windows Android 에뮬레이터 Kakao Map 실행법과 주의사항 추가
- `artifacts/validation/issue-239/android-arm64-map.png`: 지도 타일·핀·하단 카드 표시 캡처
- `artifacts/validation/issue-239/VALIDATION.md`: 원인, 검증 결과, 리스크 기록

## 공유 파일 / 계약 변경

- 공유 위험 파일: 없음
- API 계약 변경: 없음
- DB migration: 없음
- 환경 변수: 기존 `API_BASE_URL`, `KAKAO_NATIVE_APP_KEY`를 사용하며 값 변경 없음
- 외부 API: Kakao Map 기존 연동을 그대로 사용

## 검증

- PowerShell 구문 검사: 오류 0건
- 존재하지 않는 기기 ID 입력: 예상한 기기 검증 오류로 중단됨
- 실행 스크립트 전체 실행: 디버그 빌드, ARM64 강제 설치, localhost 포트 연결, 앱 시작 성공
- 설치 패키지 확인: `primaryCpuAbi=arm64-v8a`
- 로컬 포트 연결 확인: 호스트와 에뮬레이터의 `tcp:8080` 연결 확인
- 로컬 백엔드 상태 확인: `/api/actuator/health` 응답 `UP`
- Kakao Map 런타임 확인: 네이티브 라이브러리 로드, 지도 인증 성공 응답, 렌더 성공 콜백 확인
- 화면 확인: 지도 타일, 감자 핀 8개, 선택 카드 표시 확인
- `flutter analyze`: 통과, 이슈 0건
- `flutter test`: 통과, 총 226개
- Android ARM64 디버그 빌드: 통과

## 실패했던 시도

- 첫 자동 실행에서는 ARM64 설치와 앱 시작은 성공했지만 `adb reverse`가 없어 로컬 지도 데이터를 불러오지 못했다. 스크립트에 localhost 포트 자동 연결을 추가한 뒤 다시 실행해 해결했다.
- 첫 화면 캡처 복사에서는 대상 폴더가 없어 실패했다. 검증 폴더를 만든 뒤 다시 복사해 산출물을 남겼다.

## 산출물

- 검증 기록: `artifacts/validation/issue-239/VALIDATION.md`
- 화면 캡처: `artifacts/validation/issue-239/android-arm64-map.png`

## 남은 리스크

- 에뮬레이터가 ARM64 실행 또는 네이티브 브리지를 지원해야 한다.
- 번역 실행 환경에서는 지도 렌더링 성능이 실제 ARM64 기기보다 느릴 수 있다.
- 일반적인 x86_64 `flutter run`으로 앱을 다시 설치하면 빈 지도 현상이 재발할 수 있어 제공 스크립트를 사용해야 한다.
- 이 실행 방식은 빌드·설치 후 앱을 시작하므로 Flutter hot reload를 제공하지 않는다.
- 기존 Kotlin/Java 호환성 경고는 남아 있으나 이번 문제와 무관하며 빌드에는 영향을 주지 않았다.

## 다음 작업

- 이어서 실행할 명령: `powershell -ExecutionPolicy Bypass -File .\\tool\\run_android_arm64_emulator.ps1`
- 확인해야 할 파일: `frontend/tool/run_android_arm64_emulator.ps1`, `frontend/README.md`
- 조율이 필요한 사람 또는 이슈: PR 검토 후 머지, 이후 `#238` 푸시 토큰 수명주기 작업 재개
