#!/usr/bin/env python3
"""Generate the rallybook context GeoJSON and Dart paths from SGIS boundaries."""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
from typing import Any


TARGET_PROVINCES = ("경기도", "충청북도", "경상북도")
SIMPLIFY_TOLERANCE_METER = 800.0
SOURCE_REVISION = "d5f8ea3208f19a73a01f865847d20cc195ae91ba"
SOURCE_URL = (
    "https://github.com/statgarten/maps/blob/"
    f"{SOURCE_REVISION}/json/%EC%A0%84%EA%B5%AD_%EC%8B%9C%EB%8F%84_%EA%B2%BD%EA%B3%84.json"
)


def signed_area(points: list[list[float]]) -> float:
    return sum(
        points[index][0] * points[(index + 1) % len(points)][1]
        - points[(index + 1) % len(points)][0] * points[index][1]
        for index in range(len(points))
    ) / 2


def point_to_segment_distance(
    point: list[float],
    start: list[float],
    end: list[float],
) -> float:
    delta_x = end[0] - start[0]
    delta_y = end[1] - start[1]
    if delta_x == 0 and delta_y == 0:
        return math.hypot(point[0] - start[0], point[1] - start[1])
    ratio = (
        (point[0] - start[0]) * delta_x
        + (point[1] - start[1]) * delta_y
    ) / (delta_x * delta_x + delta_y * delta_y)
    ratio = max(0.0, min(1.0, ratio))
    nearest_x = start[0] + ratio * delta_x
    nearest_y = start[1] + ratio * delta_y
    return math.hypot(point[0] - nearest_x, point[1] - nearest_y)


def simplify_polyline(
    points: list[list[float]],
    tolerance: float,
) -> list[list[float]]:
    if len(points) <= 2:
        return points
    distances = [
        point_to_segment_distance(point, points[0], points[-1])
        for point in points[1:-1]
    ]
    if not distances:
        return [points[0], points[-1]]
    max_distance = max(distances)
    if max_distance <= tolerance:
        return [points[0], points[-1]]
    split_index = distances.index(max_distance) + 1
    left = simplify_polyline(points[: split_index + 1], tolerance)
    right = simplify_polyline(points[split_index:], tolerance)
    return left[:-1] + right


def circular_path(
    points: list[list[float]],
    start_index: int,
    end_index: int,
) -> list[list[float]]:
    result = [points[start_index]]
    index = start_index
    while index != end_index:
        index = (index + 1) % len(points)
        result.append(points[index])
    return result


def simplify_ring(
    ring: list[list[float]],
    tolerance: float,
) -> list[list[float]]:
    points = ring[:-1] if ring[0] == ring[-1] else ring[:]
    west_index = min(range(len(points)), key=lambda index: points[index][0])
    opposite_index = max(
        range(len(points)),
        key=lambda index: (
            (points[index][0] - points[west_index][0]) ** 2
            + (points[index][1] - points[west_index][1]) ** 2
        ),
    )
    first_half = simplify_polyline(
        circular_path(points, west_index, opposite_index),
        tolerance,
    )
    second_half = simplify_polyline(
        circular_path(points, opposite_index, west_index),
        tolerance,
    )
    simplified = first_half[:-1] + second_half[:-1]
    return simplified + [simplified[0]]


def largest_polygon(feature: dict[str, Any]) -> list[list[list[float]]]:
    polygons = feature["geometry"]["coordinates"]
    return max(polygons, key=lambda polygon: abs(signed_area(polygon[0])))


def load_features(input_path: Path) -> dict[str, dict[str, Any]]:
    source = json.loads(input_path.read_text(encoding="utf-8"))
    return {
        feature["properties"]["title"]: feature
        for feature in source["features"]
    }


def gangwon_bounds(features: dict[str, dict[str, Any]]) -> tuple[float, ...]:
    gangwon = features.get("강원특별자치도") or features.get("강원도")
    if gangwon is None:
        raise ValueError("강원도 경계가 원본 GeoJSON에 없습니다.")
    outer_ring = largest_polygon(gangwon)[0]
    x_values = [point[0] for point in outer_ring]
    y_values = [point[1] for point in outer_ring]
    return min(x_values), max(x_values), min(y_values), max(y_values)


def normalized_ring(
    ring: list[list[float]],
    bounds: tuple[float, ...],
) -> list[tuple[float, float]]:
    min_x, max_x, min_y, max_y = bounds
    return [
        (
            round((point[0] - min_x) / (max_x - min_x), 5),
            round((max_y - point[1]) / (max_y - min_y), 5),
        )
        for point in ring
    ]


def build_context_features(
    features: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    result = []
    for province in TARGET_PROVINCES:
        polygon = largest_polygon(features[province])
        outer_ring = simplify_ring(polygon[0], SIMPLIFY_TOLERANCE_METER)
        result.append(
            {
                "type": "Feature",
                "properties": {"name": province},
                "geometry": {"type": "Polygon", "coordinates": [outer_ring]},
            }
        )
    return result


def write_geojson(output_path: Path, features: list[dict[str, Any]]) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    content = {
        "type": "FeatureCollection",
        "source": "SGIS Open API via statgarten/maps",
        "sourceUrl": SOURCE_URL,
        "sourceRevision": SOURCE_REVISION,
        "license": "MIT",
        "coordinateReferenceSystem": "SGIS projected coordinates (meter)",
        "simplifyToleranceMeter": SIMPLIFY_TOLERANCE_METER,
        "features": features,
    }
    output_path.write_text(
        json.dumps(content, ensure_ascii=False, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )


def write_dart(
    output_path: Path,
    features: list[dict[str, Any]],
    bounds: tuple[float, ...],
) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "// Generated by tool/generate_rallybook_context_map.py. Do not edit by hand.",
        "import 'package:flutter/widgets.dart';",
        "",
        "class GangwonContextRegion {",
        "  const GangwonContextRegion({",
        "    required this.name,",
        "    required this.polygon,",
        "  });",
        "",
        "  final String name;",
        "  final List<Offset> polygon;",
        "}",
        "",
        "const gangwonContextRegions = <GangwonContextRegion>[",
    ]
    for feature in features:
        name = feature["properties"]["name"]
        ring = normalized_ring(feature["geometry"]["coordinates"][0], bounds)
        lines.extend(
            [
                "  GangwonContextRegion(",
                f"    name: '{name}',",
                "    polygon: [",
            ]
        )
        lines.extend(f"      Offset({x:.5f}, {y:.5f})," for x, y in ring)
        lines.extend(["    ],", "  ),"])
    lines.append("];")
    output_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument(
        "--geojson-output",
        type=Path,
        default=Path("assets/geojson/gangwon_adjacent_provinces.geojson"),
    )
    parser.add_argument(
        "--dart-output",
        type=Path,
        default=Path(
            "lib/features/stamp/presentation/model/gangwon_context_region.dart"
        ),
    )
    arguments = parser.parse_args()

    features = load_features(arguments.input)
    bounds = gangwon_bounds(features)
    context_features = build_context_features(features)
    write_geojson(arguments.geojson_output, context_features)
    write_dart(arguments.dart_output, context_features, bounds)


if __name__ == "__main__":
    main()
