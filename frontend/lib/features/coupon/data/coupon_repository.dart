import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../domain/coupon.dart';

class CouponRepository {
  const CouponRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<CouponSummary>> fetchCoupons() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.myCoupons);
    final result = ApiResponse<List<CouponSummary>>.fromJson(
      response.data ?? const <String, dynamic>{},
      (json) {
        final data = json as Map<String, dynamic>? ?? const <String, dynamic>{};
        final values = data['coupons'] as List<dynamic>? ?? const [];
        return values
            .whereType<Map<String, dynamic>>()
            .map(CouponSummary.fromJson)
            .toList(growable: false);
      },
    );
    return _requireData(result, statusCode: response.statusCode);
  }

  Future<CouponDetail> fetchCoupon(int userCouponId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.couponDetail(userCouponId),
    );
    final result = ApiResponse<CouponDetail>.fromJson(
      response.data ?? const <String, dynamic>{},
      (json) => CouponDetail.fromJson(
        json as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
    );
    return _requireData(result, statusCode: response.statusCode);
  }

  Future<CouponQr> fetchCouponQr(int userCouponId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.couponQr(userCouponId),
    );
    final result = ApiResponse<CouponQr>.fromJson(
      response.data ?? const <String, dynamic>{},
      (json) => CouponQr.fromJson(
        json as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
    );
    return _requireData(result, statusCode: response.statusCode);
  }

  Future<CouponDetail> useCoupon(int userCouponId, String payload) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.couponUse(userCouponId),
      data: {'payload': payload},
    );
    final result = ApiResponse<CouponDetail>.fromJson(
      response.data ?? const <String, dynamic>{},
      (json) => CouponDetail.fromJson(
        json as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
    );
    return _requireData(result, statusCode: response.statusCode);
  }

  T _requireData<T>(ApiResponse<T> response, {required int? statusCode}) {
    if (!response.success || response.data == null) {
      throw ApiException(
        message:
            response.message.isEmpty ? '쿠폰을 불러오지 못했습니다.' : response.message,
        code: response.code,
        statusCode: statusCode,
      );
    }
    return response.data!;
  }
}
