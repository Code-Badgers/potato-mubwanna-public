import 'dart:math' as math;

import 'package:flutter/widgets.dart';

const _semiMajorAxis = 6378137.0;
const _inverseFlattening = 298.257222101;
const _centralLatitude = 38.0;
const _centralLongitude = 127.5;
const _scaleFactor = 0.9996;
const _falseEasting = 1000000.0;
const _falseNorthing = 2000000.0;

// Largest Gangwon-do mainland polygon bounds in the SGIS EPSG:5179 source.
const _gangwonMinEasting = 964581.424899999;
const _gangwonMaxEasting = 1165534.3555;
const _gangwonMinNorthing = 1892879.7358;
const _gangwonMaxNorthing = 2068443.9536;

Offset projectToGangwonMap({
  required double latitude,
  required double longitude,
}) {
  final projected = projectToKorea2000(
    latitude: latitude,
    longitude: longitude,
  );
  return Offset(
    (projected.dx - _gangwonMinEasting) /
        (_gangwonMaxEasting - _gangwonMinEasting),
    (_gangwonMaxNorthing - projected.dy) /
        (_gangwonMaxNorthing - _gangwonMinNorthing),
  );
}

Offset projectToKorea2000({
  required double latitude,
  required double longitude,
}) {
  const flattening = 1 / _inverseFlattening;
  const eccentricitySquared = 2 * flattening - flattening * flattening;
  const secondEccentricitySquared =
      eccentricitySquared / (1 - eccentricitySquared);
  final latitudeRadians = _toRadians(latitude);
  final longitudeRadians = _toRadians(longitude);
  final centralLatitudeRadians = _toRadians(_centralLatitude);
  final centralLongitudeRadians = _toRadians(_centralLongitude);
  final sinLatitude = math.sin(latitudeRadians);
  final cosLatitude = math.cos(latitudeRadians);
  final tanLatitude = math.tan(latitudeRadians);
  final radius = _semiMajorAxis /
      math.sqrt(1 - eccentricitySquared * sinLatitude * sinLatitude);
  final tangentSquared = tanLatitude * tanLatitude;
  final correction = secondEccentricitySquared * cosLatitude * cosLatitude;
  final longitudeDelta =
      (longitudeRadians - centralLongitudeRadians) * cosLatitude;

  final easting = _falseEasting +
      _scaleFactor *
          radius *
          (longitudeDelta +
              (1 - tangentSquared + correction) *
                  math.pow(longitudeDelta, 3) /
                  6 +
              (5 -
                      18 * tangentSquared +
                      tangentSquared * tangentSquared +
                      72 * correction -
                      58 * secondEccentricitySquared) *
                  math.pow(longitudeDelta, 5) /
                  120);
  final northing = _falseNorthing +
      _scaleFactor *
          (_meridionalArc(latitudeRadians, eccentricitySquared) -
              _meridionalArc(
                centralLatitudeRadians,
                eccentricitySquared,
              ) +
              radius *
                  tanLatitude *
                  (longitudeDelta * longitudeDelta / 2 +
                      (5 -
                              tangentSquared +
                              9 * correction +
                              4 * correction * correction) *
                          math.pow(longitudeDelta, 4) /
                          24 +
                      (61 -
                              58 * tangentSquared +
                              tangentSquared * tangentSquared +
                              600 * correction -
                              330 * secondEccentricitySquared) *
                          math.pow(longitudeDelta, 6) /
                          720));

  return Offset(easting, northing);
}

double _meridionalArc(double latitude, double eccentricitySquared) {
  final eccentricityFourth = eccentricitySquared * eccentricitySquared;
  final eccentricitySixth = eccentricityFourth * eccentricitySquared;
  return _semiMajorAxis *
      ((1 -
                  eccentricitySquared / 4 -
                  3 * eccentricityFourth / 64 -
                  5 * eccentricitySixth / 256) *
              latitude -
          (3 * eccentricitySquared / 8 +
                  3 * eccentricityFourth / 32 +
                  45 * eccentricitySixth / 1024) *
              math.sin(2 * latitude) +
          (15 * eccentricityFourth / 256 + 45 * eccentricitySixth / 1024) *
              math.sin(4 * latitude) -
          35 * eccentricitySixth / 3072 * math.sin(6 * latitude));
}

double _toRadians(double degrees) => degrees * math.pi / 180;
