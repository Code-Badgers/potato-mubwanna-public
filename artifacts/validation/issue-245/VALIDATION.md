# Issue #245 검증 기록

## 작업 요약

- 이슈: #245
- 브랜치: `fix/245-android-map-marker-selection`
- 담당 영역: Android 네이티브 카카오맵 마커 선택 이벤트
- 제외 범위: 지도/카드 UI, iOS 구현, API/DB 계약
- 목표: Android에서 다른 마커를 누르면 하단 카드가 선택한 장소로 갱신되도록 복원

## 변경 파일

- `frontend/android/app/src/main/kotlin/com/gamjamubwatna/frontend/NativeKakaoMapView.kt`: 기본 `LabelLayer`의 클릭 이벤트를 활성화

## 공유 파일 / 계약 변경

- 공유 위험 파일: 없음
- API 계약 변경: 없음
- DB migration: 없음
- 환경 변수: 기존 `KAKAO_NATIVE_APP_KEY`, `KAKAO_JAVASCRIPT_KEY`, `API_BASE_URL` 사용
- 외부 API: Kakao Maps SDK for Android 2.12.11

## 검증

- 실행: Android ARM64 에뮬레이터에 debug APK 설치 후 실제 카카오맵 마커 두 개를 순서대로 탭
- 결과: 초기 `대관령원예농협 바우파머스` 카드에서 첫 마커 선택 시 `강릉 길감자`, 두 번째 마커 선택 시 `감자적1번지`로 갱신
- 실행: Flutter 지도 선택 관련 위젯/파서/렌더 데이터 테스트
- 결과: 20개 테스트 통과
- 실행: `flutter analyze`, 전체 `flutter test`, Android ARM64 debug APK 빌드/설치
- 결과: 정적 분석 이슈 없음, 전체 232개 테스트 통과, APK 빌드 및 에뮬레이터 설치 성공
- 실패했던 시도: 에뮬레이터 스크린샷 표시 크기(921×2048)를 ADB 물리 해상도(1080×2400)로 오인해 최초 자동 탭 좌표가 마커에서 벗어남
- 해결: ADB 물리 좌표로 환산해 마커 클릭 이벤트와 카드 갱신을 재검증

## 산출물

- `01-initial-selection.png`: 초기 선택 카드
- `02-first-marker-selected.png`: 첫 마커 선택 후 카드
- `03-second-marker-selected.png`: 두 번째 마커 선택 후 카드

## 남은 리스크

- 실제 Android 기기별 터치 영역은 최종 실기기 QA에서 한 번 더 확인한다.

## 다음 작업

- #244의 공식 관광지 좌표 및 랠리북 노출 검증을 이어서 진행한다.
- 확인해야 할 파일: 관광지 seed/import 코드, 랠리북 데이터 소스, 지도 spot 응답 매핑
- 조율이 필요한 이슈: #244
