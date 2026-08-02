# Issue #186 Validation

## 이슈

- GitHub Issue: `#186 [BE] chore: 감자 스팟 수동 큐레이션 시드 정리`
- Branch: `chore/186-curated-spot-seeds`
- 작업일: 2026-08-02

## PAAR 기록

### Problem

TourAPI와 Kakao Local API 기반 자동 수집은 지도 MVP를 구성하기에는 충분하지만, 공모전 데모에서 보여주고 싶은 카테고리 폭이 부족했다. 기존 수동 큐레이션 시드는 `정선 5일장`, `남이섬`, `감자밭` 3개뿐이라 맛집, 길거리 간식, 농촌 체험, 바 & 페어링, 로컬푸드 직매장 같은 감자 여행 경험을 한눈에 보여주기 어려웠다.

### Analysis

기존 마이그레이션을 수정하면 이미 적용된 개발 DB와 충돌할 수 있으므로 새 Flyway 마이그레이션을 추가하는 방식이 가장 안전하다고 판단했다. 또한 현재 테스트 DB에는 Kakao Local 샘플 스팟도 함께 들어오므로, 테스트에서 전체 활성 스팟 수를 고정값으로 검증하면 데이터 수집 시드가 늘어날 때마다 깨진다. 따라서 `content_id`가 `CURATED:`로 시작하는 수동 큐레이션 데이터만 분리해 검증하도록 기준을 바꿨다.

### Action

- `V22__seed_additional_curated_potato_spots.sql` 추가
- 감자 수동 큐레이션 스팟 5개 추가
  - 감자적1번지: `POTATO_RESTAURANT`
  - 강릉 길감자: `POTATO_SNACK`
  - 바회마을: `POTATO_EXPERIENCE`
  - 감자아일랜드 춘천: `POTATO_BREWERY`
  - 대관령원예농협 바우파머스: `POTATO_SHOP`
- 중복 방지를 위해 `content_id` 또는 `name + address` 기준 `WHERE NOT EXISTS` 조건 적용
- `TouristSpotMigrationTest`를 큐레이션 데이터 subset 기준으로 수정
- 공개 `/spots` API에서 추가 스팟과 신규 카테고리가 노출되는지 검증

### Result

- `./gradlew test --tests com.gamjamubwatna.spot.domain.TouristSpotMigrationTest` 통과
- 최초 검증에서는 전체 스팟 개수를 8개로 고정해 실패했다. 원인은 H2 테스트 DB에도 기존 Kakao Local fixture가 함께 들어와 전체 활성 스팟이 65개였기 때문이다.
- 테스트를 `CURATED:` content id 기준으로 수정한 뒤 통과했다.
- k6 성능 테스트는 진행하지 않았다. 이번 작업은 런타임 API 로직 변경이 아니라 seed migration과 검증 테스트 보강이므로, 성능 수치보다 마이그레이션 안정성이 더 중요한 범위라고 판단했다.

## 참고한 공개 정보

- 감자적1번지: 강릉 감자전/감자옹심이 후보 및 주소 확인
  - https://ban-life.com/content/view?id=13433
- 바회마을: 고랭지 감자/고구마 캐기 체험 후보 및 주소 확인
  - https://bhvillage.org/activity/act04.php
- 감자아일랜드: 감자 기반 로컬 맥주/바 & 페어링 후보 확인
  - https://www.chuncheon.go.kr/tour/destination/all-tour/detail/?tourId=325
- 대관령원예농협 바우파머스: 로컬푸드 직매장 후보 및 주소 확인
  - https://nhlocalfood.com/store/?bmain=view&uid=37

## 남은 보완

- 강릉 길감자는 공개 검색 결과 기반으로 데모 큐레이션에 포함했다. 운영 데이터로 쓰기 전 공식 채널 또는 현장 확인이 필요하다.
- 좌표는 지도 데모용으로 수동 지정했다. 운영 전 Kakao Local 좌표 또는 현장 좌표로 재검수해야 한다.
- 추후 관리자 도구가 생기면 SQL seed가 아니라 관리 테이블/어드민 화면에서 큐레이션 데이터를 관리하는 편이 좋다.
