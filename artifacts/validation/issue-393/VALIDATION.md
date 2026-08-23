# Issue 393 Validation

## 작업 요약

- 이슈: #393
- 브랜치: `fix/393-jeongseon-audio-guide`
- 담당 영역: 정선 관광지 중복 데이터, Odii 오디오 별칭 매칭, 관광지 상세 오디오 UI
- 제외 범위: 전체 관광지 자체 음성 제작, 전역 부분 일치, Odii 외 음원 저장소
- 목표: 공식 `정선 5일장`을 단일 관광지로 사용하고, 검증된 별칭으로 오디오를 안전하게 연결한다.

## 진행 과정

1. `정선아리랑시장`과 공식 TourAPI 콘텐츠 `정선 5일장(132003)`이 모두 활성 상태인 것을 확인했다.
2. 즐겨찾기, 방문, 오디오 캐시, 혼잡도, 메뉴, 미션 증빙, 스탬프 참조의 외래키와 유니크 제약을 확인했다.
3. V40 migration에서 중복 관계를 공식 관광지 ID로 옮긴 뒤 중복 행을 비활성화했다.
4. 오디오 전역 부분 일치를 완화하지 않고 공식 콘텐츠 ID `132003`에만 `정선아리랑시장` 별칭을 등록했다.
5. 공식 이름 검색 결과가 없을 때만 검증된 별칭으로 Odii를 한 번 더 검색하도록 했다.
6. 상세 화면 제목을 `관광 해설 오디오`로 바꾸고 `한국관광공사 오디(Odii) 제공`을 표시했다.

## 발생한 문제와 해결

- 문제: 중복 관광지를 단순 비활성화하면 기존 사용자 관계가 옛 ID에 남는다.
  - 해결: 유니크 충돌 관계를 먼저 정리한 후 모든 관련 FK를 공식 관광지 ID로 이동했다.
- 문제: 전역 부분 일치를 허용하면 고성 통일전망대가 파주 오디오를 받는 기존 오류가 재발할 수 있다.
  - 해결: 공식 TourAPI 콘텐츠 ID별 allowlist 별칭만 정확/지역 한정 매칭에 사용했다.
- 문제: 첫 미리보기 빌드에서 임시 파일의 `audioGuideProvider` import가 누락됐다.
  - 해결: import를 추가해 다시 실행했고 모바일 화면 캡처를 완료한 뒤 임시 파일을 삭제했다.
- 문제: 브라우저 캡처의 `path` 옵션이 파일을 생성하지 않았다.
  - 해결: 반환된 PNG bytes를 검증 폴더에 직접 저장했다.

## 변경 파일 요약

- `backend/src/main/resources/db/migration/V40__merge_jeongseon_market_duplicate.sql`: 중복 관광지 관계 병합 및 비활성화
- `backend/src/main/java/com/gamjamubwatna/audio/application/AudioGuideService.java`: 콘텐츠 ID 기반 검증 별칭 및 재검색
- `backend/src/test/java/com/gamjamubwatna/audio/application/AudioGuideServiceTest.java`: 별칭 성공/재검색/미검증 거부 회귀 테스트
- `backend/src/test/java/com/gamjamubwatna/spot/domain/JeongseonSpotMergeMigrationTest.java`: V39 데이터에서 V40 관계 이동 검증
- `backend/src/test/java/com/gamjamubwatna/spot/domain/TouristSpotMigrationTest.java`: 지도 API 중복 미노출 검증
- `frontend/lib/features/spot/presentation/screen/spot_detail_screen.dart`: 오디오 제목과 제공 주체 문구
- `frontend/test/features/spot/spot_detail_screen_test.dart`: 화면 문구 회귀 테스트
- `agents_docs/10_uxui_guideline.md`: UI 가이드 명칭 동기화

## 공유 파일 / 계약 변경

- 공유 위험 파일: 신규 Flyway migration, `agents_docs/10_uxui_guideline.md`
- API 계약 변경: 없음. endpoint와 request/response는 유지한다.
- DB migration: V40 신규 추가. 기존 migration은 수정하지 않았다.
- 환경 변수: 추가/변경 없음. 실제 오디오 조회에는 기존 `ODII_API_SERVICE_KEY`가 필요하다.
- 외부 API: 기존 한국관광공사 Odii API를 사용한다.

## 검증

- `backend\\gradlew.bat test --tests "com.gamjamubwatna.audio.application.AudioGuideServiceTest" --tests "com.gamjamubwatna.spot.domain.JeongseonSpotMergeMigrationTest" --tests "com.gamjamubwatna.spot.domain.TouristSpotMigrationTest"`
  - 결과: 성공
- `backend\\gradlew.bat build`
  - 결과: 성공, 전체 452 tests
- `flutter test test/features/spot/spot_detail_screen_test.dart`
  - 결과: 성공, 13 tests
- `flutter analyze`
  - 결과: 성공, No issues found
- `flutter test`
  - 결과: 성공, 310 tests
- `flutter build web`
  - 결과: 성공
  - 기존 Wasm 호환성과 CupertinoIcons 폰트 경고만 출력됨
- `git diff --check`
  - 결과: 성공, 공백 오류 없음
- 모바일 브라우저 검증: 430x932
  - 결과: 제목, 출처, 플레이어, 하단 버튼의 겹침/잘림 없음

## 산출물

- `artifacts/validation/issue-393/spot-audio-mobile.png`: 관광지 상세 오디오 모바일 화면
- `artifacts/validation/issue-393/VALIDATION.md`: 본 검증 기록

## 남은 리스크

- 로컬에 `ODII_API_SERVICE_KEY`가 없어 실제 Odii 운영 응답 재생까지는 확인하지 못했다.
- Odii가 향후 공식 콘텐츠의 제목을 다시 변경하면 해당 콘텐츠 ID의 검증 별칭을 추가해야 한다.
- V40은 공식 콘텐츠 ID `132003`과 기존 curated 콘텐츠 ID가 존재하는 DB에서만 병합하며, 둘 중 하나가 없으면 안전하게 아무 행도 변경하지 않는다.

## 다음 작업

- 배포 환경에서 V40 적용 후 `/api/spots`에 `정선아리랑시장`이 없는지 확인한다.
- `ODII_API_SERVICE_KEY`가 설정된 환경에서 정선 상세 오디오를 1회 재생 확인한다.
