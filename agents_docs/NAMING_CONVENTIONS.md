# Naming Conventions

감자무봤나의 이름은 코드를 처음 보는 사람이 역할을 바로 추측할 수 있어야 합니다. 짧은 이름보다 정확한 이름을 우선합니다.

## 기본 원칙

- 이름은 **동작 + 대상 + 목적**이 드러나게 작성한다.
- `bootstrap`, `init`, `temp`, `misc`, `common`, `manager`처럼 역할이 흐릿한 단어를 단독으로 쓰지 않는다.
- 약어는 팀에서 이미 공유된 도메인 용어만 사용한다.
- 이름이 길어지더라도 PR 리뷰에서 설명이 덜 필요해지는 쪽을 선택한다.

## Flyway Migration

형식:

```text
V<version>__<verb>_<domain>_<purpose>.sql
```

예시:

```text
V2__create_tourist_spot_table.sql
V3__add_stamp_city_name_unique_index.sql
V4__seed_gangwon_potato_catalog.sql
```

피해야 할 예시:

```text
긴 날짜형 버전 + 모호한 설명
V1__init.sql
V2__update.sql
V3__misc.sql
```

이미 적용된 migration은 파일명, 내용, checksum을 바꾸지 않는다. 변경이 필요하면 새 migration을 추가한다. 로컬 개발 DB에서만 정리 목적의 rename이 필요하면 추후 생성 예정인 `docs/DATABASE_MIGRATIONS.md`의 reset/repair 절차를 따른다.

## Branch

형식:

```text
<type>/<issue-number>-<clear-task-name>
```

예시:

```text
docs/12-readme-runbook
feat/23-stamp-verify-api
fix/24-coupon-expiration-check
refactor/25-potato-reward-policy
```

## GitHub Issue Title

형식:

```text
[AREA] type: 작업 제목
```

예시:

```text
[BE] feat: 스탬프 방문 인증 API 구현
[FE] fix: 감자 도감 빈 상태 렌더링 수정
[DOCS] docs: 배포 검증 절차 정리
```

- `AREA`는 `BE`, `FE`, `DOCS`, `INFRA`처럼 변경 영역을 짧게 쓴다.
- `type`은 커밋 메시지 type과 맞춘다: `feat`, `fix`, `docs`, `test`, `refactor`, `chore`, `style`.
- 제목에는 에이전트 이름이나 임시 표현을 넣지 않는다.

## Commit Message

프론트엔드와 백엔드 작업만 대괄호 접두사를 붙인다. 그 외 문서, 설정, GitHub 템플릿, 공통 정책은 접두사 없이 작성한다.

형식:

```text
[FE] <type>(<scope>): <한국어 요약> (#<issue-number>)
[BE] <type>(<scope>): <한국어 요약> (#<issue-number>)
<type>(<scope>): <한국어 요약> (#<issue-number>)
```

예시:

```text
[FE] feat(map): 지도 스팟 필터 UI 구현 (#8)
[BE] feat(stamp): 방문 인증 API 구현 (#12)
docs(agent): Codex 협업 운영 문서 추가 (#14)
chore(github): PR 템플릿 검증 항목 정리 (#15)
```

- `scope`는 기능 또는 변경 영역을 짧게 쓴다: `map`, `stamp`, `auth`, `coupon`, `agent`, `github`.
- 하나의 작업에서 프론트와 백엔드를 모두 크게 바꾸면 가능한 한 커밋을 나눈다.
- 커밋 제목에는 에이전트 이름이나 임시 표현을 넣지 않는다.

## Variables And Functions

- boolean은 질문처럼 읽히게 한다: `isStampAcquired`, `hasAvailableCoupon`.
- 함수는 동작을 포함한다: `calculateVisitDistance`, `issueStampReward`.
- 컬렉션은 복수형을 쓴다: `touristSpots`, `userCoupons`.
- DTO는 방향을 드러낸다: `VerifyStampRequest`, `TouristSpotResponse`.
