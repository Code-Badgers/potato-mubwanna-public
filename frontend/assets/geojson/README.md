# Stamp tour landmass context

`gangwon_adjacent_provinces.geojson` contains a non-interactive Korean
peninsula landmass context around Gangwon-do. The stamp tour uses this layer
only as faint geographic context so Gangwon-do does not look like an isolated
island on the blue map background.

- Source file: Natural Earth `ne_10m_admin_0_countries`
- Included features: Korean peninsula north and south landmass
- Coordinate reference system: WGS84 longitude/latitude
- Transformation: country landmass polygons are projected to the same Korea
  2000 coordinate system as the stamp tour map, lightly simplified, and
  normalized against the Gangwon-do mainland bounding box.
- Clipping: selected landmass polygons are not pre-cropped to the visible card.
  Flutter renders the full selected features as one background landmass and lets
  the map card viewport clip the portions outside the rounded card.

The Flutter coordinate constants in
`lib/features/stamp/presentation/model/gangwon_context_region.dart` are
generated from the same source. Gangwon-do remains the only interactive layer;
the peninsula landmass is rendered as a single non-interactive background with
no internal administrative boundaries.
