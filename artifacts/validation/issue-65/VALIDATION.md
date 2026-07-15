# Issue 65 Validation

## 작업 요약

- 이슈: #65 지도 마커 선택 시 장소 카드 갱신 오류 수정
- 브랜치: `fix/65-map-marker-card-selection`
- 담당 영역: Flutter 지도 선택 상태, Web/iOS/Android 카카오맵 선택 이벤트
- 목표: 다른 지도 마커를 누르면 하단 카드가 해당 장소 정보로 즉시 변경되게 한다.

## 원인과 해결

### 플랫폼별 선택 ID 전달 방식 불일치

- Android는 Kakao SDK의 `labelId`에서 `potato-` 접두어를 제거해 스팟 ID를 복원하고 있었다.
- iOS와 Web은 원시 문자열을 전달해 플랫폼별 이벤트 payload 계약이 명시되지 않았다.
- SDK가 label ID를 변경하거나 다른 타입으로 전달하면 Flutter의 `MapSpot.id`와 일치하지 않아 첫 장소 카드가 유지될 수 있었다.

해결:

- 세 플랫폼 모두 `spotSelected` 이벤트에 `{spotId: 원본 ID}` payload를 전달하도록 통일했다.
- Android는 마커 생성 시 `labelId -> spotId` 역매핑을 저장하고 클릭 시 원본 ID를 전달한다.
- Flutter는 새 Map payload와 기존 String payload를 모두 해석해 이전 앱 빌드와의 호환성을 유지한다.
- 지도 선택 콜백을 테스트할 수 있는 지도 빌더 주입 지점을 추가했다.

### Web CustomEvent 브라우저 객체 타입 불일치

- 문제: `CustomEvent.detail`의 네이티브 JavaScript 객체는 Dart 런타임에서 항상 `js.JsObject`로 판별되지 않는다.
- 영향: raw JS 객체가 Map 패턴과 일치하지 않아 Web 마커 선택 ID가 `null`로 처리될 수 있었다.
- 해결: String과 Dart Map은 그대로 사용하고, 나머지 객체는 `JsObject.fromBrowserObject`로 감싼 뒤 `spotId`를 추출한다. 변환 실패 이벤트는 무시한다.

## 변경 파일

- `frontend/lib/features/map/presentation/screen/map_screen.dart`: 지도 선택 콜백 기반 카드 갱신 테스트 지점 추가
- `frontend/lib/features/map/presentation/widget/map_spot_selection_message.dart`: 플랫폼 선택 payload 해석
- `frontend/lib/features/map/presentation/widget/kakao_map_view_native.dart`: 네이티브 payload 처리
- `frontend/lib/features/map/presentation/widget/kakao_map_view_web.dart`: Web CustomEvent payload 처리
- `frontend/android/app/src/main/kotlin/com/gamjamubwatna/frontend/NativeKakaoMapView.kt`: Android 원본 스팟 ID 역매핑
- `frontend/ios/Runner/NativeKakaoMapView.swift`: iOS 선택 payload 통일
- `frontend/test/features/map/`: 카드 갱신 및 payload 호환 테스트

## 검증

### 지도 선택 테스트

```bash
flutter test \
  test/features/map/map_screen_test.dart \
  test/features/map/map_spot_selection_message_test.dart \
  --reporter expanded
```

- 결과: 7 tests passed
- 두 번째 마커를 누른 뒤 카드가 `정선 5일장`에서 `감자 카페`로 변경되는 것을 검증했다.
- Map payload, 구형 String payload, 빈 ID 거부를 검증했다.

### 정적 분석

```bash
flutter analyze
```

- 결과: `No issues found`

### 전체 Flutter 테스트

```bash
flutter test --reporter compact
```

- 결과: 78 tests passed

### iOS 시뮬레이터 빌드

```bash
flutter build ios --simulator --debug --no-pub
```

- 결과: `Built build/ios/iphonesimulator/Runner.app`
- Swift 선택 이벤트 변경 컴파일 통과

### Android 디버그 빌드

```bash
flutter build apk --debug --no-pub
```

- 결과: `Built build/app/outputs/flutter-apk/app-debug.apk`
- Kotlin label ID 역매핑 변경 컴파일 통과

### Web 디버그 빌드

```bash
flutter build web --debug --no-pub \
  --dart-define=KAKAO_JAVASCRIPT_KEY=test-key
```

- 결과: `Built build/web`
- `JsObject.fromBrowserObject` 기반 Web 선택 payload 변환 컴파일 통과
- 빌드에는 실제 키가 아닌 컴파일 검증용 값만 사용했다.

## 확인된 경고

- `flutter_secure_storage`가 아직 iOS Swift Package Manager를 지원하지 않는다는 기존 경고가 있다.
- Android 프로젝트와 Kakao Flutter SDK가 Kotlin Gradle Plugin을 적용하며 향후 Flutter에서 Built-in Kotlin 이전이 필요하다는 기존 경고가 있다.
- WebAssembly dry run에서 `flutter_secure_storage_web`, `geolocator_web`의 `dart:html` 호환 경고가 있다.
- 이 경고들은 현재 빌드 실패 원인이 아니며 #65 범위 밖이다.

## 남은 리스크

- 실제 Kakao API 키와 백엔드 스팟 데이터가 연결된 실기기 탭 검증은 사용자 로컬 실행에서 최종 확인이 필요하다.
- 상단 필터나 하단 시트가 물리적으로 덮는 영역의 마커는 해당 UI를 먼저 이동해야 선택할 수 있다.

## 다음 확인 절차

1. iOS 또는 Android 앱을 새로 빌드해 설치한다.
2. 서로 다른 감자 핀을 차례로 선택한다.
3. 카드의 장소명, 카테고리, 주소가 선택한 핀과 일치하는지 확인한다.
