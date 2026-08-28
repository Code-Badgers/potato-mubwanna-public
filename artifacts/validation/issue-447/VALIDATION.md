# Issue #447 관광지 상세 정보·오디오 상태 검증

## 작업 요약

- 이슈: https://github.com/Code-Badgers/potato-mubwanna/issues/447
- 브랜치: `fix/447-spot-detail-content`
- 기준 커밋: `f7682c44bdca06484628d2d25c3d5a504bb7f794`
- 목표: 관광지 상세 API가 내려주는 운영 정보가 화면에 보이도록 하고, 오디오가 없는 관광지는 빈 오디오 안내 영역을 숨긴다.
- 제외 범위: Odii 원천 오디오 추가, 정선 관광지 별칭 데이터 수정, TourAPI 상세 설명 수집 로직 변경, API 계약 변경

## 변경 파일

- `frontend/lib/features/spot/domain/spot_detail.dart`: 기존 상세 API 응답의 설명, 영업 정보, 연락처, 홈페이지, 평점 필드를 파싱한다.
- `frontend/lib/features/spot/presentation/screen/spot_detail_screen.dart`: 관광지 정보 섹션을 표시하고 오디오 404는 섹션 전체를 숨긴다. 일시적인 오디오 서비스 오류는 재시도 UI를 유지한다.
- `frontend/test/features/spot/spot_detail_repository_test.dart`: 상세 필드 매핑을 검증한다.
- `frontend/test/features/spot/spot_detail_screen_test.dart`: 정보 표시, 오디오 제공·미제공·서비스 오류 상태를 검증한다.

## 공유 파일 / 계약 변경

- 공유 위험 파일: 없음.
- API 계약: 변경 없음. 기존 `GET /api/spots/{id}` 응답 필드만 사용한다.
- DB migration: 없음.
- 환경 변수: 새 항목 없음.

## 자동 검증

- `flutter test test/features/spot/spot_detail_repository_test.dart test/features/spot/spot_detail_screen_test.dart`
  - 결과: 15개 테스트 통과.
- `flutter test test/features/spot`
  - 결과: 17개 테스트 통과.
- `flutter analyze`
  - 결과: 이슈 없음.
- `flutter build apk --release --target-platform android-arm64 --dart-define-from-file=<임시 파일>`
  - 결과: 성공, `app-release.apk` 103.4MB.
  - 비고: 정식 서명키와 Firebase 운영 설정은 일회성 임시 파일로 주입했고 빌드 직후 삭제했다.
- `apksigner verify --print-certs app-release.apk`
  - 결과: 성공. SHA-256 `b5f5a6730ef76204ad1d36a2f59e4fe8224cfb5be963a937dca2ca412f5e68ec`.
- `git diff --check`
  - 결과: 공백 오류 없음.

## 실기기 검증

- 기기: Samsung Galaxy S23+ (`SM-S916N`), Android 16 / API 36
- 설치: 정식 서명 arm64 릴리스 APK를 `adb install -r`로 덮어 설치, 기존 앱 데이터 유지
- 운영 API 관광지 #2 남이섬
  - 관광지 정보 섹션에 영업 상태, 당일 영업시간, 평점 등 표시 확인.
  - Odii 오디오 카드 표시 확인.
  - 재생 후 00:04까지 진행되는 것을 확인.
- 운영 API 관광지 #10 뮤지엄 산
  - 홈페이지, 전화번호, 운영시간, 입장료, 휴무일 등 상세 정보 표시 확인.
  - 오디오 미제공 응답에서 `관광 해설 오디오` 제목과 오류 안내가 모두 나타나지 않음을 확인.

## 화면 증거

- `spot-2-information.png`: 남이섬 관광지 정보 섹션
- `spot-2-audio-playing.png`: 남이섬 Odii 오디오 재생 상태
- `spot-10-information.png`: 뮤지엄 산 관광지 정보 섹션
- `spot-10-no-audio.png`: 뮤지엄 산 상세 화면 하단, 오디오 미제공 섹션 숨김

## 남은 리스크

- 관광지 #10처럼 입장료 원문이 매우 길면 정보 카드가 길어지지만 내용은 잘림 없이 표시된다.
- 설명 필드가 비어 있는 관광지는 영업 정보만 표시된다. 설명 수집 품질 개선은 별도 백엔드 작업이다.
- 오디오 존재 여부는 Odii 매핑 결과에 의존하며, 원천 데이터가 추가되면 별도 앱 수정 없이 오디오 섹션이 다시 표시된다.

## 다음 작업

- 운영 관광지 별칭과 TourAPI 상세 설명 수집 품질을 별도 이슈로 관리한다.
- 원스토어 제출 전 체크리스트에서 QA-038, QA-039를 이번 실기기 검증 결과로 갱신한다.
