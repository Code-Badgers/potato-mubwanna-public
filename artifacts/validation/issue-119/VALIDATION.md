# Issue #119 검증 기록 - iOS/Android 추천 동선 Polyline 렌더링

## 작업 목표

- #117에서 웹에만 표시되던 추천 동선 Polyline을 iOS/Android 네이티브 Kakao 지도에서도 표시한다.
- Flutter `routePolyline` 데이터를 네이티브 platform view 생성 시점과 업데이트 시점 모두에 전달한다.
- 동선 좌표가 2개 미만이면 기존 선을 제거하고 지도 크래시 없이 빈 상태로 둔다.

## PAAR 기록

### Problem

- 기존 Flutter native map bridge는 `spots`만 네이티브로 넘겼다.
- #117에서 `routePolyline` 파라미터는 위젯 시그니처에만 존재했고, iOS/Android platform view에는 전달되지 않았다.
- 모바일 앱 기준으로는 웹 Polyline만으로 충분하지 않다. 사용자가 iOS/Android에서 내 동선을 확인할 때 지도 위에 실제 선이 보여야 한다.

### Action

- Dart native bridge에 `_routePolylinePayload`를 추가했다.
- platform view 생성 파라미터에 `routePolyline`을 포함했다.
- `didUpdateWidget`에서 `spots` 변경은 `updateSpots`, `routePolyline` 변경은 `updateRoutePolyline`로 분리해 네이티브 지도 전체 재생성을 피했다.
- Android는 설치된 Kakao Maps Android SDK의 `ShapeLayer`, `PolylineOptions`, `MapPoints.fromLatLng` API를 확인한 뒤 추천 동선 전용 layer에 Polyline을 렌더링했다.
- iOS는 설치된 `KakaoMapsSDK.swiftinterface`에서 `ShapeManager`, `ShapeLayer`, `MapPolylineShapeOptions`, `PolylineStyleSet` 시그니처를 확인한 뒤 추천 동선 전용 layer에 `MapPolylineShape`를 렌더링했다.
- route 전용 layer는 업데이트마다 비우고 다시 그리도록 했다. 이렇게 하면 즐겨찾기 동선이 변경되어도 이전 선이 남지 않는다.

### Analysis

- native view를 `ValueKey`로 재생성하는 방식은 지도 타일 재로딩과 flickering 위험이 있어 피했다.
- MethodChannel로 좌표 데이터만 갱신하면 지도 인스턴스는 유지되고, 마커/동선만 바뀐다.
- Android는 `ShapeLayerPass.Route`와 12px 노란 Polyline을 사용했다.
- iOS는 `ShapeLayerPassType.route`와 노란 body, 흰 stroke가 있는 PolylineStyleSet을 사용했다.
- iOS 전체 빌드 검증은 `device_info_plus`의 Xcode 26 호환 문제로 막혔다. 실패 위치는 이번 변경 파일이 아니라 pub cache의 `FPPDeviceInfoPlusPlugin.m`이다.

### Result

- Android native Kakao 지도에서 추천 동선 좌표가 2개 이상이면 노란 Polyline을 그릴 수 있게 되었다.
- iOS native Kakao 지도에서도 추천 동선 전용 shape layer와 style을 통해 Polyline을 그리도록 구현했다.
- Flutter 지도 테스트와 analyze는 통과했다.
- Android Kotlin 컴파일은 통과했다.
- iOS simulator build는 외부 플러그인 호환 문제로 실패했으며, 이 리스크를 후속 작업으로 남긴다.

## 변경 파일 요약

- `frontend/lib/features/map/presentation/widget/kakao_map_view_native.dart`
  - `routePolyline` payload 생성
  - 생성 파라미터와 `updateRoutePolyline` MethodChannel 호출 추가
- `frontend/android/app/src/main/kotlin/com/gamjamubwatna/frontend/NativeKakaoMapView.kt`
  - `routePolyline` 파싱 및 보관
  - Kakao Maps Android SDK Shape Polyline 렌더링 추가
- `frontend/ios/Runner/NativeKakaoMapView.swift`
  - `routePolyline` 파싱 및 보관
  - Kakao Maps iOS SDK MapPolylineShape 렌더링 추가

## 실행한 검증

```bash
cd frontend
/Users/mac/Documents/flutter/bin/flutter test test/features/map/map_screen_test.dart test/features/map/favorite_spot_route_test.dart
```

- 결과: 통과

```bash
cd frontend
/Users/mac/Documents/flutter/bin/flutter analyze
```

- 결과: `No issues found`

```bash
cd frontend/android
./gradlew :app:compileDebugKotlin
```

- 결과: 통과
- 참고: Android Gradle/Kotlin plugin deprecation 경고가 있었으나 컴파일 실패는 없었다.

```bash
cd frontend
PATH="/usr/local/lib/ruby/gems/4.0.0/bin:$PATH" /Users/mac/Documents/flutter/bin/flutter build ios --simulator --debug --no-codesign
```

- 결과: 실패
- 실패 원인: `device_info_plus-12.4.0`의 `FPPDeviceInfoPlusPlugin.m`에서 `NSProcessInfo`의 `isiOSAppOnVision` selector를 찾지 못함
- 판단: 이번 `NativeKakaoMapView.swift` 변경과 직접 관련 없는 Xcode 26/plugin 호환 문제

## 남은 리스크

- 실제 iOS simulator 화면에서 Polyline 표시 캡처는 `device_info_plus` 빌드 이슈 해결 후 추가 확인이 필요하다.
- 실제 Android 기기 또는 ARM 호환 에뮬레이터에서 Kakao native map SDK와 Polyline 표시를 수동 확인해야 한다.
- 현재 선은 추천 동선 waypoint를 직선으로 연결한다. 실제 도로 기반 경로는 Kakao Mobility 등 별도 길찾기 API가 필요하다.

## 후속 작업

- `device_info_plus` iOS/Xcode 26 호환 문제 해결 또는 패키지 버전 조정
- 실제 iOS/Android 화면 캡처를 `artifacts/validation/issue-119/`에 추가
- 추천 동선 따라가기 버튼에서 외부 지도/내비게이션 실행 연결
- 도로 기반 길찾기 API 도입 여부 결정
