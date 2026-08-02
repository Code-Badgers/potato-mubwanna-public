# Issue 206 검증 기록

## 작업 범위

- 이슈: #206 `[BE] feat: 감자 도감 카탈로그 확장 및 미션 보상 코드 정렬`
- 브랜치: `feat/206-potato-catalog-rewards`
- 목적: 미션에서 `reward_type = 'POTATO'`로 지급하는 보상값이 `potatoes.code`와 일치하도록 감자 도감 카탈로그를 확장한다.

## PAAR

### Problem

미션 보상 중 일부는 감자 도감 코드가 아니라 `호반감자 조각`, `희귀 감자 씨앗` 같은 표시용 문구를 `reward_label`로 저장하고 있었다. 이 상태에서는 미션 완료 후 보상값을 감자 도감의 `potatoes.code`와 직접 연결하기 어렵고, 프론트엔드에서 획득 감자 이미지를 안정적으로 찾기 어렵다.

### Approach

기존 미션 데이터를 임시로 우회하지 않고, 보상으로 지급되는 감자를 모두 `potatoes` 카탈로그에 등록한 뒤 미션 보상 라벨을 감자 코드로 정렬하는 방향을 선택했다. 이렇게 하면 이후 미션 완료, 감자 획득, 감자 도감 표시 흐름이 같은 식별자를 공유한다.

### Action

- `V23__seed_potato_reward_catalog.sql`을 추가해 미션 보상용 감자 카탈로그를 확장했다.
- 기존 초기 미션의 표시용 보상 라벨을 `POTATO_HOBAN_CHUNCHEON`, `POTATO_RARE_SEED` 코드로 보정했다.
- 마이그레이션 테스트에서 활성 감자 카탈로그 순서를 검증하도록 기대값을 15종으로 갱신했다.
- `reward_type = 'POTATO'`인 모든 미션 보상 라벨이 실제 `potatoes.code`에 존재하는지 검증하는 테스트를 추가했다.

### Result

- `./gradlew test --tests com.gamjamubwatna.potato.domain.PotatoMigrationTest` 통과
- `./gradlew test --tests 'com.gamjamubwatna.potato.*'` 통과

## 트러블슈팅

### 미션 보상값 불일치

처음에는 추가 미션 보상 코드만 누락된 것으로 보고 카탈로그를 13종까지 확장했다. 테스트를 돌리니 `호반감자 조각`, `희귀 감자 씨앗`이 누락값으로 잡혔다. 원인은 `V5__create_missions.sql`의 초기 미션 2개가 코드가 아닌 표시용 문구를 보상값으로 가지고 있었기 때문이다.

해결은 테스트 조건을 완화하지 않고, 두 보상을 도감 코드로 전환했다. 덕분에 이후 같은 문제가 생기면 테스트가 다시 실패해 데이터 계약이 깨진 지점을 빠르게 확인할 수 있다.

## 남은 보완

- 프론트 감자 이미지 중 `POTATO_COMMON_SEED`, `POTATO_GOLDEN_HONGCHEON`, `POTATO_HOBAN_CHUNCHEON`, `POTATO_RARE_SEED` 전용 이미지가 아직 없다.
- 현재 프론트는 이미지가 없을 때 기본 감자 아이콘으로 대체할 수 있지만, 도감 완성도를 위해 후속 FE 이슈에서 이미지 매핑을 보강하는 것이 좋다.
- 이번 변경은 DB 시드와 정합성 테스트 중심이라 k6 성능 테스트 대상 API는 없다. 감자 도감 조회 API나 미션 완료 API를 변경하는 이슈에서 k6를 다시 기록하는 것이 적절하다.
