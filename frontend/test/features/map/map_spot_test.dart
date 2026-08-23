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
      'congestionLevel': 'NORMAL',
      'stampEnabled': true,
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
