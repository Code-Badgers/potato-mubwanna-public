# Issue #249 검증 기록

## 작업 요약

- 이슈: #249
- 브랜치: `feat/249-rallybook-adjacent-geojson`
- 담당 영역: 랠리북 강원도 지도 주변 인접 시도 배경
- 제외 범위: 18개 시군 선택 동작, 스탬프 획득 로직, 관광지 데이터 수정
- 목표: 강원도 서쪽·남쪽에 경기·충북·경북 경계를 옅게 표시해 지리적 맥락 복원

## 변경 파일

- `frontend/assets/geojson/gangwon_adjacent_provinces.geojson`: SGIS 기반 인접 3도 본토 경계
- `frontend/assets/geojson/README.md`: 데이터 출처·변환·라이선스 기록
- `frontend/assets/geojson/LICENSE.statgarten-maps`: 원본 데이터 저장소 MIT 고지
- `frontend/tool/generate_rallybook_context_map.py`: 원본 경계를 단순화하고 Flutter 좌표로 생성
- `frontend/lib/features/stamp/presentation/model/gangwon_context_region.dart`: 생성된 지도 좌표
- `frontend/lib/features/stamp/presentation/screen/stamp_book_screen.dart`: 강원도 아래에 인접 3도 배경 레이어 렌더링
- `frontend/test/features/stamp/gangwon_context_region_test.dart`: 포함 지역과 상대 배치 검증
- `frontend/pubspec.yaml`: GeoJSON 자산 등록

## 공유 파일 / 계약 변경

- 공유 위험 파일: `frontend/pubspec.yaml`, 랠리북 화면
- API 계약 변경: 없음
- DB migration: 없음
- 환경 변수: Android 검증 시 기존 `API_BASE_URL`, `KAKAO_NATIVE_APP_KEY` 사용, 값은 기록하지 않음
- 외부 API: SGIS Open API 경계를 배포하는 `statgarten/maps`의 고정 revision 사용

## 검증

- 실행: 생성 스크립트 Python 문법 검사 및 동일 입력 2회 생성 해시 비교
- 결과: 문법 검사 통과, GeoJSON·Dart 출력 모두 결정적 생성 확인
- 실행: `flutter test test/features/stamp/gangwon_context_region_test.dart test/features/stamp/stamp_book_screen_test.dart`
- 결과: 관련 10개 테스트 통과
- 실행: `flutter analyze`
- 결과: 이슈 없음
- 실행: `flutter test`
- 결과: 전체 234개 테스트 통과
- 실행: ARM64 Android debug APK 빌드·설치 후 로컬 백엔드 연결 및 랠리북 화면 확인
- 결과: 빌드·설치 성공, 경기·충북·경북 윤곽이 강원도 서쪽·남쪽에 옅게 이어져 표시됨
- 실패했던 시도: 전체 검사 첫 두 호출은 짧게 설정된 명령 제한 시간으로 종료됨
- 해결: 충분한 제한 시간으로 동일한 전체 검사를 다시 실행해 성공 확인
- 실행하지 못한 명령: 없음

## 산출물

- 검증 기록: 이 파일
- 화면/API 캡처: `03-rallybook.png`
- 기타: 원본 revision 및 라이선스는 `frontend/assets/geojson/README.md`에 고정

## 남은 리스크

- 2020년 SGIS 경계 데이터의 `강원도` 명칭을 기준으로 좌표를 정렬했으며, 특별자치도 전환에 따른 행정 명칭만 달라지고 도 경계 배경 목적에는 영향이 없다.
- Android 빌드는 성공했지만 현재 플러그인의 Kotlin Gradle Plugin 적용 방식에 대한 Flutter의 향후 호환성 경고가 기존과 동일하게 출력된다.

## 다음 작업

- 이어서 실행할 명령: `flutter test test/features/stamp/stamp_book_screen_test.dart`
- 확인해야 할 파일: `frontend/lib/features/stamp/presentation/screen/stamp_book_screen.dart`
- 조율이 필요한 사람 또는 이슈: 상위 작업 #244
