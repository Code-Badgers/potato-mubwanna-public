import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import '../domain/favorite_spot.dart';
import '../domain/map_spot.dart';

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

  Future<List<FavoriteSpot>> fetchFavoriteSpots() async {
    final response =
        await _dio.get<Map<String, dynamic>>(ApiPaths.favoriteSpots);
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
