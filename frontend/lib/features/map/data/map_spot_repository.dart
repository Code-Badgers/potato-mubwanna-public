import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
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
}
