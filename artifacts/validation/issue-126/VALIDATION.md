# Issue #126 검증 기록

## 작업 요약

- 이슈: #126 외부 API 실응답과 Kakao 로그인 호환성 보정
- 브랜치: `fix/126-external-api-compatibility`
- 담당 영역: Odii 오디오 가이드, Web Kakao 로그인, Android Kakao Map 오류 방어
- 제외 범위: Kakao Developers 운영 콘솔 변경, 운영 도메인 등록, iOS/ARM64 실기기 검증
- 목표: 발급된 로컬 키를 사용한 실호출에서 확인된 응답/SDK/CPU 호환 문제를 보정한다.

## 진행 과정

1. Odii 실응답이 최상위 `response` 객체로 감싸져 있음을 확인하고 응답 모델을 보정했다.
2. 관광지명 표기 차이로 오디오를 찾지 못하는 사례를 제한적인 정규화와 포함 매칭으로 보정했다.
3. Kakao JavaScript SDK v2에서 제거된 팝업 로그인을 `Kakao.Auth.authorize()` 리다이렉트 방식으로 교체했다.
4. Web 콜백의 `state`를 브라우저 세션 값과 비교하고, 인가 코드는 Backend에서 Kakao access token으로 교환하도록 했다.
5. Kakao Map Android 라이브러리가 x86_64 에뮬레이터에서 ARM64 바이너리를 읽을 때 발생하는 `UnsatisfiedLinkError`를 지도 영역 fallback으로 전환했다.
6. 실제 브라우저와 Android x86_64 에뮬레이터에서 수정 결과를 확인했다.

## 발생한 문제와 해결

### Kakao Web 팝업 API 제거

- 기존 코드는 JavaScript SDK 2.7.5에서 `Kakao.Auth.login()`을 호출했지만 SDK v2에서는 지원되지 않았다.
- SDK를 2.8.1로 올리고 인가 코드 리다이렉트 흐름으로 변경했다.
- 브라우저 세션에 32-byte 랜덤 `state`와 redirect URI를 보관하고 콜백에서 일치 여부를 확인한다.
- Backend `POST /api/auth/kakao/code`가 REST API 키로 카카오 토큰 API를 호출한 뒤 기존 사용자/JWT 발급 흐름을 재사용한다.

### Android x86_64 Kakao Map 네이티브 라이브러리

- 에뮬레이터 로그에서 `libK3fAndroid.so is for EM_AARCH64 instead of EM_X86_64`를 재현했다.
- SDK 초기화와 `MapView` 생성을 `UnsatisfiedLinkError` 경계 안으로 옮겼다.
- 수정 후 동일 로그는 네이티브 로더 경고로 남지만 앱 PID가 유지되고 `FATAL EXCEPTION`은 발생하지 않았다.

### 로컬 Android 빌드 최소 SDK 불일치

- 현재 Windows Flutter 3.44.2의 기본 `minSdkVersion`은 24이지만 고정된 `health` 플러그인은 26 이상을 요구해 일반 `flutter build apk`가 manifest 병합에서 중단됐다.
- 지원 OS 정책을 이번 이슈에서 변경하지 않기 위해 소스의 `minSdkVersion`은 건드리지 않았다.
- 검증 시에만 `min-sdk-26.init.gradle`을 적용해 APK를 만들고 x86_64 에뮬레이터에 설치했다.

### 로컬 Web 포트 충돌

- 54631 포트가 NVIDIA 백그라운드 프로세스의 임시 연결과 겹쳐 테스트 서버 바인딩이 실패했다.
- 앱은 54632에서 실행하고 Kakao에 전달하는 redirect URI는 등록값인 `http://localhost:54631/`로 유지했다.

## 변경 파일 요약

- `backend/src/main/java/com/gamjamubwatna/audio/**`: Odii 실응답 wrapper와 관광지명 매칭 보정
- `backend/src/main/java/com/gamjamubwatna/auth/**`: Kakao 인가 코드 교환 endpoint와 client
- `frontend/lib/features/auth/**`: Web authorize/callback, Native access-token 결과 분리, Backend 코드 교환 연동
- `frontend/android/app/src/main/kotlin/com/gamjamubwatna/frontend/NativeKakaoMapView.kt`: x86_64 네이티브 오류 fallback
- `frontend/.env.example`: `KAKAO_LOGIN_REDIRECT_URI` 예시 추가

## 검증

### 외부 API 실호출

- Kakao Local: HTTP 200, 검색 결과 3건
- TourAPI: HTTP 200, 응답 코드 `0000`, 결과 29건
- Odii: HTTP 200, 최상위 `response` wrapper 확인
- 연관 관광지 API: HTTP 200, 결과 50건
- 실제 키 값은 검증 문서와 Git diff에 기록하지 않았다.

### Backend

```powershell
cd backend
.\gradlew.bat test --tests 'com.gamjamubwatna.audio.*'
.\gradlew.bat test --tests 'com.gamjamubwatna.auth.*'
.\gradlew.bat test
```

- Odii 집중 테스트 통과
- Kakao 인증 집중 테스트 통과
- 전체 249개 테스트 통과, failure/error/skip 0
- Kakao 토큰 client 테스트에서 form-urlencoded 필드와 access token 응답 매핑 확인

### Frontend

```powershell
cd frontend
flutter test test/features/auth
flutter test
flutter analyze --no-fatal-infos
flutter build web \
  --dart-define=KAKAO_JAVASCRIPT_KEY=<local-env> \
  --dart-define=KAKAO_LOGIN_REDIRECT_URI=http://localhost:54631/
```

- 인증 테스트 13개 통과
- 전체 137개 테스트 통과
- analyze: `No issues found`
- JavaScript Web build 성공
- 실제 브라우저에서 앱 로그인 화면 렌더링, SDK 2.8.1 authorize 요청, `response_type=code`, `state`, 등록 redirect URI, Kakao 계정 로그인 화면 진입을 확인했다.
- 사용자 계정 정보는 입력하지 않아 실제 계정 동의와 최종 JWT 발급은 수행하지 않았다.

### Android

```powershell
cd frontend/android
.\gradlew.bat :app:compileDebugKotlin
.\gradlew.bat -I ..\..\artifacts\validation\issue-126\min-sdk-26.init.gradle `
  -Ptarget-platform=android-x64 -Ptarget=lib/main.dart `
  -Pdart-defines=<base64-local-env> assembleDebug
```

- Kotlin compile 성공
- 검증용 minSdk 26 override를 적용한 debug APK assemble 성공
- `potato_api_36` x86_64 에뮬레이터 설치/실행 성공
- 지도 진입 후 ARM64 라이브러리 오류 안내 표시
- 앱 프로세스 유지, `FATAL EXCEPTION` 없음
- `android-map-fallback.png`: 실제 에뮬레이터 fallback 화면
- `android-relevant-log.txt`: 재현된 CPU 아키텍처 불일치 네이티브 로그

## 공유 파일 / 계약 변경

- API 계약: `POST /api/auth/kakao/code`
  - request: `authorizationCode`, `redirectUri`
  - response: 기존 `AuthLoginResponse`
- 기존 API: `POST /api/auth/kakao` 변경 없음
- DB migration: 없음
- 환경 변수:
  - Backend는 기존 `KAKAO_REST_API_KEY` 재사용
  - Frontend에 `KAKAO_LOGIN_REDIRECT_URI` 추가
- 외부 API: Kakao OAuth token endpoint, Kakao JavaScript SDK 2.8.1, Odii

## 남은 리스크

- Kakao Developers에 운영/개발 redirect URI를 환경별로 정확히 등록해야 한다.
- 실제 Kakao 계정 동의와 Backend JWT 발급까지의 종단 검증은 계정 로그인이 가능한 담당자가 한 번 수행해야 한다.
- Android ARM64 실기기와 iOS 실행은 현재 Windows 환경에서 확인하지 못했다.
- 프로젝트 `minSdkVersion` 24와 `health` 플러그인의 최소 26 요구사항은 별도 이슈에서 지원 OS 정책을 정한 뒤 해결해야 한다.
- x86_64에서는 지도 대신 안내가 표시되므로 실제 지도 기능 검증은 ARM64 기기가 필요하다.

## 다음 작업

- Kakao Developers에 `http://localhost:54631/` 및 배포 환경 redirect URI 등록 여부를 확인한다.
- 테스트 계정으로 Web 로그인 동의부터 서비스 JWT 저장까지 한 번 확인한다.
- Android 최소 지원 버전과 `health` 플러그인 버전을 별도 이슈로 조율한다.
