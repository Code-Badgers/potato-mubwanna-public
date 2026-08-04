# Issue #257 검증 기록

## 확인 범위

- 공식 랠리북 관광지 29곳과 스탬프 PNG가 1:1로 연결되는지 확인
- 같은 시군의 다른 관광지를 선택했을 때 선택 카드의 관광지명과 스탬프가 함께 바뀌는지 확인
- 신규 방문 인증 성공 시 스탬프 압인 애니메이션과 `heavyImpact` 햅틱이 한 번 실행되는지 확인
- 등록되지 않았거나 자산을 읽지 못한 관광지는 기존 아이콘으로 대체되는지 확인
- Android API 36 에뮬레이터에서 디버그 APK 빌드·설치·기동 확인

## 실행 결과

```text
flutter test test/features/stamp/attraction_stamp_image_test.dart \
  test/features/stamp/stamp_book_screen_test.dart \
  test/features/spot/spot_detail_screen_test.dart
결과: 21 tests passed

flutter analyze <변경된 Dart 파일과 테스트 6개>
결과: No issues found

flutter analyze
결과: No issues found

flutter test
결과: 243 tests passed

flutter run -d emulator-5554 --debug --no-resident --no-pub ...
결과: app-debug.apk 빌드, 설치, 앱 기동 성공
```

첫 테스트에서는 `Tween`의 정수 리터럴 때문에 `Animatable<num>` 추론 오류가 1회 발생했습니다. `Tween<double>`과 `1.0`으로 타입을 명시한 뒤 재실행하여 통과했습니다.

Android 빌드 중 기존 플러그인의 Built-in Kotlin 전환 경고가 발생했지만 빌드와 설치에는 영향을 주지 않았습니다. 이 이슈에서는 의존성 버전을 변경하지 않았습니다.

## 산출물

- `stamp_contact_sheet.png`: 29개 관광지 스탬프 전체 확인표
- `stamp_base_source.png`: 이미지 생성으로 만든 공통 도장 원본
- `generate_stamp_assets.py`: 투명 배경 제거와 한글 관광지명 합성 스크립트
- `android-app.png`: Android API 36 에뮬레이터 앱 기동 화면

## 실기기 한계

실제 관광지 반경 내 방문 인증은 인증 계정과 현장 위치가 필요하므로 에뮬레이터에서 재현하지 않았습니다. 대신 위젯 테스트에서 신규 발급 결과를 주입해 관광지별 이미지 표시, 압인 애니메이션, 햅틱 1회 호출을 검증했습니다.
