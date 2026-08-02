import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/potato/presentation/potato_asset.dart';

void main() {
  test('maps direct potato code to local asset path', () {
    expect(
      potatoLocalAssetPath('POTATO_GONDRE_JEONGSEON'),
      'assets/potatoes/potato_gondre_jeongseon.png',
    );
  });

  test('maps reward-only potato codes to available fallback assets', () {
    expect(
      potatoLocalAssetPath('POTATO_COMMON_SEED'),
      'assets/potatoes/potato_haji_seed.png',
    );
    expect(
      potatoLocalAssetPath('POTATO_GOLDEN_HONGCHEON'),
      'assets/potatoes/potato_golden_gangwon.png',
    );
    expect(
      potatoLocalAssetPath('POTATO_HOBAN_CHUNCHEON'),
      'assets/potatoes/potato_haji_gangneung.png',
    );
    expect(
      potatoLocalAssetPath('POTATO_RARE_SEED'),
      'assets/potatoes/potato_jaju_seed.png',
    );
  });
}
