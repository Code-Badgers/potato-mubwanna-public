# Issue #75 Validation

## Goal

- 감자 도감 백엔드 1차 기반을 구축한다.
- 감자, 희귀도, 획득 상태, 성장 정보를 저장할 데이터 모델을 정의한다.
- 전체 감자 카탈로그 조회 API와 내 감자 도감 조회 API를 구현한다.

## Scope

- Backend only
- `GET /potatoes`
- `GET /potatoes/me`
- Flyway migration for `potatoes`, `user_potatoes`
- Seed data for MVP potato catalog

## Changes

- Added `V11__create_potatoes.sql`
  - `potatoes`
  - `user_potatoes`
  - catalog seed data
  - lookup indexes
- Added potato domain model
  - `Potato`
  - `UserPotato`
  - `PotatoRarity`
  - repositories
- Added potato query API
  - catalog response
  - my collection response with acquired/growth/representative fields
- Updated `agents_docs/07_api_specification.md` with concrete potato response contracts.

## Validation Commands

```bash
cd backend
./gradlew test --tests com.gamjamubwatna.potato.domain.PotatoMigrationTest
./gradlew test --tests 'com.gamjamubwatna.potato.*'
./gradlew test
```

## Results

- `./gradlew test --tests com.gamjamubwatna.potato.domain.PotatoMigrationTest`: PASS
- `./gradlew test --tests 'com.gamjamubwatna.potato.*'`: PASS
- `./gradlew test`: PASS

## Problems And Fixes

- Initial migration used `V9__create_potatoes.sql`.
- Current `main` already had `V9__create_coupons.sql` and `V10__connect_mission_coupon_rewards.sql`.
- Flyway failed with `Found more than one migration with version 9`.
- Fixed by renaming the potato migration to `V11__create_potatoes.sql`.

- Initial controller test expected `GET /potatoes` to work without authentication.
- Current Spring Security test setup returns `401` for unauthenticated requests.
- Fixed the test to match current project security behavior by sending `user("user:1")`.

- PR review pointed out redundant `user_potatoes(user_id)` index, fragile `display_order` uniqueness, and wrapper types on non-null numeric/boolean fields.
- Removed the redundant index, removed `display_order` database/JPA uniqueness, and changed non-null numeric/boolean entity/DTO fields to primitive types.

## Remaining Risks

- Representative potato change API is not included in #75.
- Potato detail API and growth command API are not implemented in this backend slice.
- Visit/stamp/mission reward flows do not yet create `user_potatoes`; acquisition integration should be handled in a follow-up issue.
- `image_url` is nullable because potato artwork assets will be provided later.

## Follow-Up

- Add `GET /potatoes/{potatoId}` for the detail screen.
- Add representative potato update API.
- Connect visit/stamp/mission completion to `user_potatoes` acquisition.
- Add frontend potato collection screens after the backend contract is merged.
