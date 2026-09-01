import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/stamp/presentation/widget/attraction_stamp_image.dart';

void main() {
  test('maps every official rallybook attraction to a unique stamp asset', () {
    const officialAttractions = <String>{
      '남이섬',
      '소양강 스카이워크',
      '뮤지엄 산',
      '안목해변',
      '경포대',
      '묵호등대',
      '논골담길',
      '황지연못',
      '속초관광수산시장',
      '영금정',
      '환선굴',
      '장호항',
      '수타사',
      '비발디파크',
      '횡성호수길',
      '청령포',
      '장릉',
      '대관령 양떼목장',
      '이효석문학관',
      '정선 5일장',
      '고석정',
      '산천어축제장',
      '박수근미술관',
      '두타연',
      '원대리 자작나무숲',
      '통일전망대',
      '화진포',
      '서피비치',
      '낙산사',
    };

    expect(attractionStampAssets.keys.toSet(), officialAttractions);
    expect(attractionStampAssets.values.toSet(), hasLength(29));
    expect(attractionStampAssetFor(' 남이섬 '), endsWith('nami_island_stamp.png'));
    expect(attractionStampAssetFor('등록되지 않은 관광지'), isNull);
  });
}
