import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/potato/data/pending_potato_growth_store.dart';
import 'package:potato_mubwanna/features/potato/domain/potato_collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('takes a stored background growth result only once', () async {
    const store = SharedPreferencesPendingPotatoGrowthStore();
    const growthResult = PotatoGrowthResult(
      potatoId: '2',
      potatoName: '곤드레감자',
      previousLevel: 2,
      currentLevel: 3,
      leveledUp: true,
      fullyGrown: false,
    );

    await store.save(growthResult);

    final firstRead = await store.take();
    final secondRead = await store.take();

    expect(firstRead?.potatoId, growthResult.potatoId);
    expect(firstRead?.previousLevel, growthResult.previousLevel);
    expect(firstRead?.currentLevel, growthResult.currentLevel);
    expect(firstRead?.leveledUp, isTrue);
    expect(secondRead, isNull);
  });
}
