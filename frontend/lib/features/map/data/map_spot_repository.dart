import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import '../domain/favorite_spot.dart';
import '../domain/favorite_spot_route.dart';
import '../domain/map_spot.dart';
import '../domain/spot_recommendation.dart';

class MapSpotRepository {
  const MapSpotRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<MapSpot>> fetchSpots() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.spots);
    final body = response.data;
    final data = body?['data'];
    if (data is! List) {
      return const [];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(MapSpot.fromJson)
        .where((spot) => spot.latitude != 0 && spot.longitude != 0)
        .toList();
  }

  Future<List<SpotRecommendation>> fetchSpotRecommendations(
    String spotId,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.spotRecommendations(spotId),
    );
    final data = response.data?['data'];
    if (data is! List) {
      return const [];
    }

    final recommendations = data
        .whereType<Map<String, dynamic>>()
        .map(SpotRecommendation.fromJson)
        .where(
          (recommendation) =>
              recommendation.spotId.isNotEmpty &&
              recommendation.hasValidCoordinates,
        )
        .toList();
    recommendations.sort((a, b) => a.externalRank.compareTo(b.externalRank));
    return recommendations;
  }

  Future<List<FavoriteSpot>> fetchFavoriteSpots() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.favoriteSpots,
    );
    final body = response.data;
    final data = body?['data'];
    if (data is! List) {
      return const [];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(FavoriteSpot.fromJson)
        .toList();
  }

  Future<FavoriteSpotRoute> fetchFavoriteSpotRoute() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.favoriteSpotRoute,
    );
    return FavoriteSpotRoute.fromJson(
      response.data?['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<FavoriteSpotRoute> updateFavoriteSpotOrder(
    List<String> spotIds,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      ApiPaths.favoriteSpotOrder,
      data: {
        'spotIds': spotIds.map(int.parse).toList(),
      },
    );
    return FavoriteSpotRoute.fromJson(
      response.data?['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<FavoriteSpotToggleResult> addFavoriteSpot(String spotId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.favoriteSpots}/$spotId',
    );
    return FavoriteSpotToggleResult.fromJson(
      response.data?['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<FavoriteSpotToggleResult> removeFavoriteSpot(String spotId) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '${ApiPaths.favoriteSpots}/$spotId',
    );
    return FavoriteSpotToggleResult.fromJson(
      response.data?['data'] as Map<String, dynamic>? ?? const {},
    );
  }
}
