# Stamp tour landmass context

`gangwon_adjacent_provinces.geojson` contains a non-interactive Korean
peninsula landmass context around Gangwon-do. It also includes a Gyeonggi-do
polygon from the province boundary source so the west side of the stamp map is
filled with real adjacent map geometry instead of an arbitrary color patch.

- Source files: Natural Earth `ne_10m_admin_0_countries`, user-provided
  `TL_SCCO_CTPRVN.json`
- Included features: Korean peninsula north and south landmass, Gyeonggi-do
- Coordinate reference system: WGS84 longitude/latitude
- Transformation: country landmass polygons are projected to the same Korea
  2000 coordinate system as the stamp tour map, lightly simplified, and
  normalized against the Gangwon-do mainland bounding box.
- Clipping: selected landmass polygons are not pre-cropped to the visible card.
  Flutter renders the full selected features as one background landmass and lets
  the map card viewport clip the portions outside the rounded card.

The Flutter coordinate constants in
`lib/features/stamp/presentation/model/gangwon_context_region.dart` are
generated from the same sources. Gangwon-do remains the only interactive layer;
the peninsula landmass and Gyeonggi-do detail are rendered as a single
non-interactive background with no visible internal administrative boundaries.
