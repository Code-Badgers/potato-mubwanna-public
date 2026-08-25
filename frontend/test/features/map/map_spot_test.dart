import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/map/domain/map_spot.dart';

void main() {
  test('parses verified menu prices from the spot list response', () {
    final spot = MapSpot.fromJson({
      'id': 3,
      'name': '감자밭',
      'category': 'POTATO_CAFE',
      'latitude': 37.9256574,
      'longitude': 127.7500695,
      'address': '강원특별자치도 춘천시',
      'cityName': '춘천시',
      'imageUrl': ' https://example.com/spot.jpg ',
      'imageUrls': [
        ' https://example.com/spot.jpg ',
        'https://example.com/google-photo.jpg',
      ],
      'congestionLevel': 'NORMAL',
      'stampEnabled': true,
      'phone': '033-000-0000',
      'website': 'https://example.com',
      'rating': 4.3,
      'businessOpeningHours': {
        'openNow': true,
        'todayText': '화요일: 오전 11:00~오후 8:00',
        'weekdayDescriptions': [
          '화요일: 오전 11:00~오후 8:00',
        ],
      },
      'menuItems': [
        {
          'name': '감자빵',
          'priceWon': 3300,
          'priceNote': null,
          'verifiedOn': '2026-08-03',
        },
        {
          'name': '수제맥주',
          'priceWon': null,
          'priceNote': '변동가격',
          'verifiedOn': '2026-08-03',
        },
      ],
    });

    expect(spot.menuItems, hasLength(2));
    expect(spot.imageUrl, 'https://example.com/spot.jpg');
    expect(spot.imageUrls, [
      'https://example.com/spot.jpg',
      'https://example.com/google-photo.jpg',
    ]);
    expect(spot.effectiveImageUrls, [
      'https://example.com/spot.jpg',
      'https://example.com/google-photo.jpg',
    ]);
    expect(spot.phone, '033-000-0000');
    expect(spot.website, 'https://example.com');
    expect(spot.rating, 4.3);
    expect(spot.businessOpeningHours?.openNow, isTrue);
    expect(spot.todayOpeningText, '화요일: 오전 11:00~오후 8:00');
    expect(spot.menuItems[0].priceLabel, '3,300원');
    expect(spot.menuItems[0].verifiedOnLabel, '2026.08.03');
    expect(spot.menuItems[1].priceLabel, '변동가격');
  });

  test('drops incomplete menu entries instead of showing invented prices', () {
    final spot = MapSpot.fromJson({
      'id': 1,
      'menuItems': [
        {
          'name': '가격 미확인 메뉴',
          'priceWon': null,
          'priceNote': null,
          'verifiedOn': '2026-08-03',
        },
      ],
    });

    expect(spot.menuItems, isEmpty);
    expect(spot.imageUrl, isNull);
  });
}
