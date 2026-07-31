# Issue #188 Validation

## 작업 요약

- 이슈: #188 `[FE] feat: 지도 길찾기와 추천 동선 실행 연결`
- 브랜치: `feat/188-map-navigation`
- 기능 ID: `SPOT-005`
- 목표: 지도 화면의 `길찾기`와 `이 동선 따라가기` 버튼을 카카오맵 외부 길찾기로 연결한다.
- 제외 범위: 백엔드 API, 추천 동선 계산 정책, 카카오 지도 SDK 렌더링, 네이티브 카카오내비 SDK

## 변경 파일

- `frontend/lib/features/map/application/kakao_map_navigation.dart`
  - 단일 목적지와 자동차 추천 동선 URL을 생성한다.
  - 카카오맵 제한에 맞춰 출발지, 경유지 최대 5개, 목적지까지 총 7개 지점을 전달한다.
  - `url_launcher`로 외부 앱 또는 브라우저를 실행한다.
- `frontend/lib/features/map/presentation/screen/map_screen.dart`
  - 두 길찾기 버튼을 실제 실행 콜백에 연결한다.
  - 실행 실패와 7개 초과 동선을 사용자에게 스낵바로 안내한다.
- `frontend/test/features/map/kakao_map_navigation_test.dart`
  - URL 인코딩, 경유지 순서, 지점 수 제한, 잘못된 입력을 검증한다.
- `frontend/test/features/map/map_screen_test.dart`
  - 단일 목적지, 추천 동선, 외부 실행 실패 화면 동작을 검증한다.
- `frontend/pubspec.yaml`, `frontend/pubspec.lock`
  - 공식 Flutter 플러그인 `url_launcher` 6.3.2를 추가한다.
- `artifacts/validation/issue-188/map_navigation_preview.dart`
  - 외부 키와 백엔드 상태를 고정한 실제 `MapScreen` 실행 검증 진입점이다.

## 공유 파일 / 계약 변경

- 공유 위험 파일: `frontend/pubspec.yaml`
  - 사유: HTTPS 카카오맵 URL을 플랫폼 외부 앱 또는 브라우저에서 열기 위한 공식 플러그인 추가
  - 영향: Android, iOS, Web을 포함한 Flutter 플러그인 의존성 및 자동 등록 정보 갱신
- API 계약 변경: 없음
- DB migration: 없음
- 비밀값 및 환경 변수 추가: 없음

## 구현 근거

- 카카오 지도 공식 가이드의 `/link/to/{이름},{위도},{경도}` 형식을 단일 목적지에 사용했다.
- 추천 동선은 `/link/by/car/{출발지}/{경유지...}/{목적지}` 형식을 사용했다.
- 카카오 공식 제한인 경유지 최대 5개에 맞춰 한 번에 최대 7개 지점을 연다.
- 참고: https://apis.map.kakao.com/web/guide/#routeurl
- 외부 URL 실행은 Flutter 공식 패키지를 사용했다.
- 참고: https://pub.dev/packages/url_launcher

## 자동화 검증

| 명령 | 결과 |
| --- | --- |
| `flutter test --no-pub test/features/map/kakao_map_navigation_test.dart test/features/map/map_screen_test.dart` | 성공, 지도 관련 16개 테스트 통과 |
| `flutter analyze --no-pub` | 성공, `No issues found` |
| `flutter test --no-pub` | 성공, 전체 203개 테스트 통과 |
| `flutter build web --no-pub --no-wasm-dry-run --target=../artifacts/validation/issue-188/map_navigation_preview.dart` | 성공 |
| `flutter build apk --debug --no-pub` | 성공, `build/app/outputs/flutter-apk/app-debug.apk` 생성 |

## 실제 앱 실행 검증

- 정적 웹 빌드를 `http://127.0.0.1:4188/`에서 실행했다.
- 모바일 `390x844`에서 선택 스팟의 `길찾기`를 눌렀다.
  - 카카오맵이 `정선 5일장`을 목적지로 해석한 자동차 길찾기 화면을 열었다.
- 추천 동선 패널을 스크롤한 뒤 `이 동선 따라가기`를 눌렀다.
  - 카카오맵이 `정선 5일장 -> 감자 체험장 -> 감자 카페` 순서의 자동차 경로를 열었다.
- 데스크톱 `1248x720`과 모바일에서 버튼, 하단 시트, 추천 동선 목록의 겹침과 오버플로가 없었다.
- 모바일 및 데스크톱 브라우저 console warning/error는 0건이었다.
- Android 디버그 APK 빌드로 `url_launcher`의 네이티브 플러그인 등록과 Android 컴파일을 확인했다.

## 발생 문제와 해결

1. 첫 검증용 웹 빌드는 `CustomPainter`가 사용하는 `PointMode` import 누락으로 실패했다.
2. 검증 진입점에 `dart:ui`의 `PointMode` import를 명시하고 다시 빌드해 성공했다.
3. 기능 코드와 지도 자동화 테스트는 첫 실행부터 통과했으며, 실패 범위는 검증용 배경 그림에 한정됐다.

## 산출물

- `artifacts/validation/issue-188/map-navigation-mobile.jpg`
- `artifacts/validation/issue-188/map-recommended-route-mobile.jpg`
- `artifacts/validation/issue-188/map-navigation-desktop.jpg`

## 남은 리스크

- 이번 실행 검증은 모바일 웹에서 카카오맵으로 이동하는 흐름이다. Android와 iOS에서 설치된 카카오맵 앱으로 직접 전환되는지는 실기기 확인이 남아 있다.
- 추천 동선이 7개를 초과하면 카카오맵 제한에 따라 앞 7개 지점만 전달하고 앱에서 이를 안내한다.
- 검증 진입점은 고정된 스팟 데이터와 지도 배경을 사용했다. 실제 카카오 지도 SDK의 키 설정과 마커 렌더링은 기존 지도 설정 및 별도 운영 검증 범위다.
- Android 빌드에는 기존 Kotlin Gradle Plugin 미래 호환성 경고가 남아 있다. 이 경고는 기존 #133/#134 Built-in Kotlin 전환 작업 범위다.

## 다음 작업

- 이어서 실행할 명령: `git diff && git status --short`
- 실기기 확인 항목: Android 및 iOS에서 `길찾기`를 눌렀을 때 카카오맵 앱 또는 모바일 웹으로 정상 전환되는지 확인
- 조율 대상: Team B 지도 담당자에게 추천 동선 자동차 모드와 최대 7개 지점 정책 리뷰 요청
