import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/network/api_exception.dart';
import 'package:potato_mubwanna/features/coupon/data/coupon_repository.dart';
import 'package:potato_mubwanna/features/coupon/domain/coupon.dart';

void main() {
  test('fetches coupon list and owned coupon detail', () async {
    final requestedPaths = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPaths.add(options.path);
            handler.resolve(
              Response<Map<String, Object?>>(
                requestOptions: options,
                statusCode: 200,
                data: options.path == '/coupons/me'
                    ? _couponListResponse
                    : _couponDetailResponse,
              ),
            );
          },
        ),
      );
    final repository = CouponRepository(dio: dio);

    final coupons = await repository.fetchCoupons();
    final detail = await repository.fetchCoupon(1);

    expect(requestedPaths, ['/coupons/me', '/coupons/1']);
    expect(coupons, hasLength(2));
    expect(coupons.first.status, CouponStatus.available);
    expect(coupons.last.status, CouponStatus.expired);
    expect(detail.userCouponId, 1);
    expect(detail.usagePlace, '감자마을 제휴점');
    expect(detail.issuedAt, DateTime.parse('2026-07-01T00:00:00Z'));
  });

  test('throws ApiException when coupon response fails', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response<Map<String, Object?>>(
                requestOptions: options,
                statusCode: 200,
                data: const {
                  'success': false,
                  'message': '쿠폰을 불러오지 못했습니다.',
                  'data': null,
                },
              ),
            );
          },
        ),
      );

    expect(
      () => CouponRepository(dio: dio).fetchCoupons(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          '쿠폰을 불러오지 못했습니다.',
        ),
      ),
    );
  });

  test('rejects malformed optional coupon dates', () {
    expect(
      () => CouponDetail.fromJson({
        ...(_couponDetailResponse['data']! as Map<String, Object?>),
        'usedAt': 'not-a-date',
      }),
      throwsFormatException,
    );
  });

  test('fetches QR payload and uses the owned coupon', () async {
    final requestedPaths = <String>[];
    Object? requestBody;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPaths.add(options.path);
            requestBody = options.data;
            handler.resolve(
              Response<Map<String, Object?>>(
                requestOptions: options,
                statusCode: 200,
                data: options.path.endsWith('/qr')
                    ? _couponQrResponse
                    : _usedCouponDetailResponse,
              ),
            );
          },
        ),
      );
    final repository = CouponRepository(dio: dio);

    final qr = await repository.fetchCouponQr(1);
    final used = await repository.useCoupon(1, qr.payload);

    expect(requestedPaths, ['/coupons/1/qr', '/coupons/1/use']);
    expect(requestBody, {'payload': 'signed-payload'});
    expect(qr.expiresAt, DateTime.parse('2026-07-15T00:05:00Z'));
    expect(used.status, CouponStatus.used);
    expect(used.usedAt, DateTime.parse('2026-07-15T00:00:00Z'));
  });
}

const _couponListResponse = <String, Object?>{
  'success': true,
  'message': '요청이 성공했습니다.',
  'data': {
    'coupons': [
      {
        'userCouponId': 1,
        'name': '감자빵 1개 교환권',
        'description': '제휴 매장에서 사용할 수 있습니다.',
        'benefitAmount': 5000,
        'status': 'AVAILABLE',
        'expiresAt': '2026-12-31T23:59:59Z',
      },
      {
        'userCouponId': 2,
        'name': '지난 쿠폰',
        'description': '사용 기간이 지났습니다.',
        'benefitAmount': 3000,
        'status': 'EXPIRED',
        'expiresAt': '2026-06-30T23:59:59Z',
      },
    ],
  },
};

const _couponDetailResponse = <String, Object?>{
  'success': true,
  'message': '요청이 성공했습니다.',
  'data': {
    'userCouponId': 1,
    'name': '감자빵 1개 교환권',
    'description': '제휴 매장에서 사용할 수 있습니다.',
    'benefitAmount': 5000,
    'status': 'AVAILABLE',
    'expiresAt': '2026-12-31T23:59:59Z',
    'usagePlace': '감자마을 제휴점',
    'issuedAt': '2026-07-01T00:00:00Z',
    'usedAt': null,
  },
};

const _couponQrResponse = <String, Object?>{
  'success': true,
  'message': '요청이 성공했습니다.',
  'data': {
    'userCouponId': 1,
    'payload': 'signed-payload',
    'expiresAt': '2026-07-15T00:05:00Z',
  },
};

const _usedCouponDetailResponse = <String, Object?>{
  'success': true,
  'message': '요청이 성공했습니다.',
  'data': {
    'userCouponId': 1,
    'name': '감자빵 1개 교환권',
    'description': '제휴 매장에서 사용할 수 있습니다.',
    'benefitAmount': 5000,
    'status': 'USED',
    'expiresAt': '2026-12-31T23:59:59Z',
    'usagePlace': '감자마을 제휴점',
    'issuedAt': '2026-07-01T00:00:00Z',
    'usedAt': '2026-07-15T00:00:00Z',
  },
};
