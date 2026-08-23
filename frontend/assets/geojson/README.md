# Rallybook context boundaries

`gangwon_adjacent_provinces.geojson` contains non-interactive land context
around Gangwon-do. The stamp tour uses these outlines only as faint geographic
context so Gangwon-do does not look like an isolated island on the blue map
background.

- Source file: user-provided `TL_SCCO_CTPRVN.json`
- Additional north land source: Natural Earth `ne_10m_admin_0_countries`
- Included features: North Korea, Gyeonggi-do, Chungcheongbuk-do,
  Gyeongsangbuk-do
- Coordinate reference system: WGS84 longitude/latitude
- Transformation: province polygons are projected to the same Korea 2000
  coordinate system as the stamp tour map, lightly simplified, and normalized
  against the Gangwon-do mainland bounding box.
- Clipping: selected source polygons are not pre-cropped to the visible card.
  Flutter renders the full selected features and lets the map card viewport clip
  the portions outside the rounded card.

The Flutter coordinate constants in
`lib/features/stamp/presentation/model/gangwon_context_region.dart` are
generated from the same source. Gangwon-do remains the only interactive layer;
all other regions are rendered as non-interactive background context.
