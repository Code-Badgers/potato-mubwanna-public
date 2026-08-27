# Issue #439 검증 기록

## 목표

Android Studio에서 별도 `--dart-define` 없이 실행해도 배포 API의 장소 이미지와
영업정보를 사용하도록 앱의 API 실행 기본값을 고정하고, 이미지 로딩 실패 원인을
비밀값 없이 확인할 수 있게 한다.

## 확인된 원인

- Flutter의 `String.fromEnvironment`는 빌드 시점 값이며 `frontend/.env`를 자동으로
  읽지 않는다.
- 기존 기본 API 주소는 `http://localhost:8080/api`였다. Android 에뮬레이터에서 이
  주소는 개발 컴퓨터가 아니라 에뮬레이터 자신을 가리킨다.
- 운영 `/api/spots` 응답은 89개 장소 중 77개에 `imageUrl`, 75개에 `imageUrls`,
  56개에 business opening hours를 반환한다.
- 운영 상세 응답도 이미지·연락처·영업시간을 반환한다. 예를 들어 `평창무이예술관`
  상세 응답에는 이미지 3장, 주소, 전화번호, 평점, 요일별 영업시간이 포함된다.
- 일부 장소는 원천 데이터가 없어 이미지가 없는 것이 정상이며, 이 경우 앱
  placeholder를 유지한다.

## 변경 내용

- `AppEnvironment.apiBaseUrl`의 미주입 기본값을 운영 HTTPS API로 변경했다.
- 로컬 백엔드는 `--dart-define=API_BASE_URL=http://localhost:8080/api`로 계속 선택할
  수 있도록 README에 실행 방법을 기록했다.
- debug 모드에서 실제 API base의 scheme/host/path만 출력한다. query와 credential은
  기록하지 않는다.
- 지도 이미지 요청이 실패할 때 URL 전체 대신 host와 오류 타입만 출력한다.

## 검증

- 운영 health endpoint: HTTP 200, 정상 상태 확인
- 운영 spots endpoint: HTTP 200, 장소/이미지/영업정보 집계 확인
- 운영 spot detail endpoint: HTTP 200, 이미지·주소·연락처·영업시간 응답 확인
- Google 이미지 URL: HTTP 200, `image/jpeg` 응답 확인
- 자동 검증: `flutter analyze` 통과 (`No issues found!`)
- 자동 검증: 전체 `flutter test` 통과 (328개 테스트)
- Android 검증: `flutter build apk --debug` 통과 (`build/app/outputs/flutter-apk/app-debug.apk`)

## 남은 리스크

- 현재 환경에는 Android 에뮬레이터와 `adb`가 연결되어 있지 않아 Android Studio
  화면을 직접 재현하지 못했다.
- 따라서 실제 Android Studio 실행 로그에서 `[network] API base:
  https://potato-mubwanna.duckdns.org/api`가 출력되는지와 실기기 이미지 렌더링은
  사용자의 Android 환경에서 한 번 더 확인해야 한다.
- 외부 이미지가 없는 장소는 운영 API에서도 `imageUrl`이 없으므로 placeholder가
  표시된다.
- 실제 기기에서는 운영 API를 사용하려면 앱을 완전히 중지 후 다시 실행해야 하며,
  이전 실행의 local build artifact가 남아 있으면 재빌드가 필요하다.
