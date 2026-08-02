# Potato Collection Images

감자 도감 이미지는 이 폴더에 PNG 파일로 추가한다.

## Naming

- 파일명은 백엔드 `potatoes.code` 값을 소문자로 바꾼 이름을 사용한다.
- 예: `POTATO_SUMI_SEED` -> `potato_sumi_seed.png`

## Required Placeholder

- `potato_unknown.png`: 미획득 감자 슬롯에 사용하는 잠금 이미지

## Current Assets

- `potato_haji_gangneung.png`: 기본 여행자 컨셉의 하지감자
- `potato_gondre_jeongseon.png`: 정선 곤드레 장터 컨셉의 곤드레감자
- `potato_golden_gangwon.png`: 보상/희귀 출현 컨셉의 황금감자
- `potato_legend_pyeongchang.png`: 고랭지 탐험가 컨셉의 전설감자
- `potato_peace_cosung.png`: 고성 평화 여행 컨셉의 평화감자
- `potato_haji_seed.png`: 연한 크림색 씨앗 컨셉의 하지감자 보상
- `potato_jaju_seed.png`: 보라색 품종과 동굴 탐험 컨셉의 자주감자
- `potato_durumi_seed.png`: 철원 두루미 깃털 컨셉의 두루미감자
- `potato_hanwoo_seed.png`: 러셋 브라운 색감과 요리 체험 컨셉의 한우감자
- `potato_jajak_inje.png`: 자작나무 질감과 숲길 산책 컨셉의 자작감자
- `potato_legend_yanggu.png`: 짙은 보라색과 숨은 계곡 전설 컨셉의 양구 전설감자
- `potato_unknown.png`: 미획득 슬롯용 잠금 감자

## Temporary Code Mapping

아래 코드는 백엔드 감자 카탈로그에는 존재하지만 아직 전용 캐릭터 이미지가 없다.
프론트는 도감 레이아웃이 깨지지 않도록 임시로 가장 가까운 기존 이미지를 재사용한다.
전용 이미지가 추가되면 `potato_asset.dart`의 alias만 제거하거나 실제 파일명으로 교체한다.

- `POTATO_COMMON_SEED` -> `potato_haji_seed.png`
- `POTATO_GOLDEN_HONGCHEON` -> `potato_golden_gangwon.png`
- `POTATO_HOBAN_CHUNCHEON` -> `potato_haji_gangneung.png`
- `POTATO_RARE_SEED` -> `potato_jaju_seed.png`

## Image Guide

- 투명 배경 PNG 권장
- 정사각형 비율 권장
- UI 안에서 자동으로 `BoxFit.contain`으로 맞춘다.
- 온보딩 이미지와 같은 따뜻한 수채화풍, 둥근 감자 몸, 진한 갈색 외곽선, 부드러운 하이라이트를 유지한다.
- 감자별 차이는 몸 비율보다 소품, 스카프, 잎, 보상 장식처럼 작은 실루엣 요소로 구분한다.
- 품종 다양성을 보여주기 위해 노랑 계열만 쓰지 않고 크림색, 자주색, 러셋 브라운, 자작나무 아이보리, 인디고 보라색 감자를 함께 사용한다.
