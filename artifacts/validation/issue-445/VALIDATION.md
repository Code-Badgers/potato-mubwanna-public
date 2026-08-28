# Issue #445 validation

## 작업 요약

- 이슈: #445 페이지별 Coach Mark 상호작용 및 화면 전환 흐름 개선
- 브랜치: `fix/445-coach-mark-guided-flow`
- 담당 영역: Flutter Coach Mark, 지도/감자밭 화면 전환 연결, 관련 테스트
- 제외 범위: Backend/API, 기존 지도·스탬프·미션 완료 로직, 사용자 데이터 계약
- 목표: 페이지별 Coach Mark가 실제 대상 위젯을 강조하고, 중요한 화면 전환은 사용자가 직접 수행한 뒤 다음 단계로 이어지도록 정리

## 변경 파일

- `frontend/lib/features/feature_tour/presentation/feature_tour_definitions.dart`: 감자밭 정보 보기와 대표 감자 변경을 실제 navigation result 단계로 변경
- `frontend/lib/features/feature_tour/presentation/feature_tour_overlay.dart`: 상호작용 대상과 시각적 Spotlight 대상을 분리하고 Coach Mark 카드를 압축
- `frontend/lib/features/potato/presentation/screen/potato_collection_screen.dart`: 감자밭의 모달/대표 감자 선택 완료를 Coach Mark navigation result와 연결하고 성장 패널 대상은 제거
- `frontend/lib/features/stamp/presentation/screen/stamp_book_screen.dart`: 겹치는 스탬프 마커를 지도 좌표 기준으로 판정하도록 정리
- `frontend/test/features/feature_tour/feature_tour_test.dart`: 지도 카드 Spotlight, 감자밭 단계, 패스포트 안내 문구, navigation result 흐름 검증 추가
- `frontend/test/features/stamp/stamp_book_screen_test.dart`: 지도 좌표 탭과 가까운 마커 선택 회귀 테스트 추가

## 공유 파일 / 계약 변경

- 공유 위험 파일: 없음
- API 계약 변경: 없음
- DB migration: 없음
- 환경 변수: 없음
- 외부 API: 없음

## 검증

- 실행: `flutter analyze`
- 결과: 통과, `No issues found`
- 실행: `flutter test test/features/feature_tour/feature_tour_test.dart`
- 결과: 통과, Coach Mark 관련 테스트 8개
- 실행: `flutter test`
- 결과: 통과, 전체 테스트 337개
- 실행하지 못한 명령: 없음

## 산출물

- 검증 기록: 본 문서
- 화면/API 캡처: 없음

## 남은 리스크

- 실제 iPhone/Android 화면에서 각 페이지의 첫 진입 시 target 위치와 Coach Mark 카드가 겹치지 않는지 확인 필요
- 지도 전체 보기에서 Kakao Map 마커와 선택 장소 카드가 실제 데이터 로딩 타이밍에도 함께 표시되는지 실기기 확인 필요
- 사용자가 정보를 확인하거나 대표 감자를 선택한 뒤 모달/선택 화면을 닫는 시점에 다음 단계가 이어지는지 실기기 확인 필요

## 다음 작업

- 이어서 실행할 명령: `cd frontend && flutter run -d <device>`
- 확인해야 할 파일: `frontend/lib/app/router/app_router.dart`, 지도/스탬프/패스포트/미션/마이페이지 화면
- 조율이 필요한 사람 또는 이슈: 없음
