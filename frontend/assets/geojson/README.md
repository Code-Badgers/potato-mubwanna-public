# Rallybook context boundaries

`gangwon_adjacent_provinces.geojson` contains the mainland outlines of only
Gyeonggi-do, Chungcheongbuk-do, and Gyeongsangbuk-do. The rallybook uses these
outlines as a faint geographic context around Gangwon-do.

- Source: SGIS Open API boundary data distributed by
  [statgarten/maps](https://github.com/statgarten/maps)
- Source file: [`전국_시도_경계.json`](https://github.com/statgarten/maps/blob/d5f8ea3208f19a73a01f865847d20cc195ae91ba/json/%EC%A0%84%EA%B5%AD_%EC%8B%9C%EB%8F%84_%EA%B2%BD%EA%B3%84.json)
- Source revision: `d5f8ea3208f19a73a01f865847d20cc195ae91ba`
- License: MIT, Copyright (c) 2022 StatGarten. See
  [`LICENSE.statgarten-maps`](LICENSE.statgarten-maps).
- Transformation: largest mainland polygon per province, Douglas-Peucker
  simplification at 800 meters

The Flutter coordinate constants in
`lib/features/stamp/presentation/model/gangwon_context_region.dart` are
generated from this GeoJSON by `tool/generate_rallybook_context_map.py` and
normalized to the same Gangwon-do bounding box as the rallybook map.
