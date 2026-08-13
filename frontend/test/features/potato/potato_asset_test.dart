import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/potato/presentation/potato_asset.dart';

void main() {
  test('maps direct potato code to local asset path', () {
    expect(
      potatoLocalAssetPath('POTATO_GONDRE_JEONGSEON'),
      'assets/characters/potatoes/food_potato_ongsimi.png',
    );
  });

  test('maps reward-only potato codes to available fallback assets', () {
    expect(
      potatoLocalAssetPath('POTATO_COMMON_SEED'),
      'assets/characters/potatoes/variety_sumi.png',
    );
    expect(
      potatoLocalAssetPath('POTATO_GOLDEN_HONGCHEON'),
      'assets/characters/potatoes/variety_daepung.png',
    );
    expect(
      potatoLocalAssetPath('POTATO_HOBAN_CHUNCHEON'),
      'assets/characters/potatoes/food_gangneung_potato_bread.png',
    );
    expect(
      potatoLocalAssetPath('POTATO_RARE_SEED'),
      'assets/characters/potatoes/variety_chubaek.png',
    );
  });

  test('falls back to beginner potato for unknown code', () {
    expect(
      potatoLocalAssetPath('UNKNOWN_POTATO'),
      potatoDefaultAssetPath,
    );
  });

  test('maps new character asset codes directly when backend adopts them', () {
    expect(
      potatoLocalAssetPath('FOOD_POTATO_BEOMBEOK'),
      'assets/characters/potatoes/food_potato_beombeok.png',
    );
    expect(
      potatoLocalAssetPath('VARIETY_DAESEO_ATLANTIC'),
      'assets/characters/potatoes/variety_daeseo_atlantic.png',
    );
  });
}
