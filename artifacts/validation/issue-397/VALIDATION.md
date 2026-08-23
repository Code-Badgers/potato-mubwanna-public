# Issue #397 여행 기록 사진 확대 오버레이 검증

## 작업 목표

여행 기록 목록 구조는 유지하면서, 사진 프레임을 누르면 페이지 이동 대신 중앙에 폴라로이드/인스탁스 느낌의 확대 카드가 뜨도록 개선했다. 빈 상태에서는 기존의 부드러운 그라데이션 placeholder 프레임을 유지하되, `아직 여행 기록이 없어요` 안내 문구와 갤러리 아이콘은 제거했다.

## 변경 요약

- `TravelRecordScreen`의 사진 선택 동작을 장소 상세 이동에서 사진 확대 오버레이로 변경했다.
- `showGeneralDialog` 기반의 반투명 scrim, fade/scale transition, 닫기 버튼, 바깥 영역 탭 닫기를 추가했다.
- 확대 카드와 뒤쪽 보조 프레임을 추가해 선택한 사진에 집중되도록 구성했다.
- 목록/빈 프레임의 비율과 내부 여백을 인스탁스/폴라로이드에 가깝게 조정했다.
- 빈 상태의 갤러리 아이콘과 설명 문구는 제거하고 placeholder 앨범만 남겼다.
- 빈 placeholder 프레임도 탭 가능한 폴라로이드 카드로 바꾸고, 탭 시 그라데이션 placeholder가 확대 모달로 뜨도록 보강했다.

## 고민한 점

기존 화면은 여행 기록이 없을 때 설명 문구가 크고 정보성 안내 화면처럼 보였다. 사용자는 이미 상단 설명에서 사진이 모이는 흐름을 이해할 수 있으므로, 빈 상태는 “아직 채워질 앨범 자리”처럼 보이는 편이 더 감성적인 목표에 맞았다.

사진을 누를 때 기존에는 장소 상세로 이동했지만, 이번 요구사항은 사진 자체를 감상하는 경험이다. 그래서 새 route를 만들지 않고 modal overlay를 사용해 현재 여행 기록 화면의 맥락을 유지했다.

## 해결 방법

- 실제 사진과 fallback 사진은 기존 `_TravelRecordPhoto`를 그대로 재사용했다.
- placeholder는 `_EmptyTravelRecordPhoto`의 gradient를 유지했다.
- 확대 모달은 `_TravelRecordPreviewModal`, `_TravelRecordPreviewCard`, `_TravelRecordBackdropFrame`으로 분리했다.
- 빈 placeholder 확대는 실제 기록 오버레이와 동일한 scrim/scale 전환을 쓰되, 실제 사진 대신 `_TravelRecordPlaceholderImage`를 사용한다.
- 테스트에서는 실제 사진과 빈 placeholder를 각각 탭한 뒤 preview card가 나타나고 닫기 버튼으로 사라지는지 확인했다.

## 실행한 검증

```bash
cd frontend && flutter test --no-pub test/features/travel_record/travel_record_screen_test.dart
cd frontend && flutter test --no-pub test/features/mypage/my_page_screen_test.dart
cd frontend && flutter test --no-pub test/features/travel_record/travel_record_screen_test.dart test/features/mypage/my_page_screen_test.dart
cd frontend && flutter analyze
```

## 결과

- 여행 기록 전용 widget test 통과
- 빈 placeholder 프레임 클릭 및 확대 모달 닫기 test 통과
- 마이페이지에서 여행 기록으로 진입하는 test 통과
- Flutter analyze 통과

## 남은 리스크

- 실제 업로드 사진 비율이 매우 극단적인 경우 확대 카드의 crop 느낌은 실기기에서 추가 확인이 필요하다.
- 실제 사진 다운로드 지연/실패 시 fallback gradient가 의도대로 보이는지 네트워크 환경별 확인이 필요하다.
- 스크린샷 산출물은 이번 작업 환경에서 별도 시뮬레이터 캡처를 수행하지 못해 추가하지 않았다.
