import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/potato/domain/potato_collection.dart';
import 'package:potato_mubwanna/features/spot/domain/visit_verification.dart';

void main() {
  test('each acquisition route has distinct guidance without an invented place', () {
    const labels = ['키워서 수확', '미션 보상', '방문 인증 보상', '스탬프 수집 보상', '이벤트 보상'];
    for (var i = 0; i < PotatoAcquisitionType.values.length; i++) {
      final type = PotatoAcquisitionType.values[i];
      final item = PotatoCollectionItem.fromJson({'acquisitionType': type.name.toUpperCase()});
      expect(item.acquisitionType.label, labels[i]);
      expect(item.acquisitionGuidance, '${labels[i]}\n${type.hint}');
      expect(item.acquired, isFalse);
    }
  });

  test('server condition is preserved for both locked and acquired cards', () {
    for (final acquired in [false, true]) {
      final item = PotatoCollectionItem.fromJson({
        'acquisitionType': 'MISSION', 'acquired': acquired,
        'acquisitionHint': '박수근미술관 미션 완료',
      });
      expect(item.acquisitionGuidance, '미션 보상\n박수근미술관 미션 완료');
    }
  });

  test('reward messages distinguish route and never announce duplicate rewards', () {
    for (final type in ['GROWTH', 'MISSION', 'VISIT', 'STAMP', 'EVENT']) {
      final fresh = VisitAcquiredPotato.fromJson({'acquisitionType': type});
      expect(fresh.acquisitionMessage.contains('수확'), type == 'GROWTH');
      final owned = VisitAcquiredPotato.fromJson({'acquisitionType': type, 'alreadyOwned': true});
      expect(owned.acquisitionMessage, '이미 보유한 감자예요');
    }
    expect(VisitAcquiredPotato.fromJson({'acquisitionType': 'UNKNOWN'}).acquisitionMessage,
      '새로운 감자를 받았어요!');
  });
}
