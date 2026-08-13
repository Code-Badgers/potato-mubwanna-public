const potatoDefaultAssetPath =
    'assets/characters/potatoes/default_beginner_potato.png';

const _potatoAssetByCode = <String, String>{
  'POTATO_HAJI_SEED': 'variety_sumi',
  'POTATO_COMMON_SEED': 'variety_sumi',
  'POTATO_GONDRE_JEONGSEON': 'food_potato_ongsimi',
  'POTATO_HAJI_GANGNEUNG': 'food_gangneung_potato_bread',
  'POTATO_HOBAN_CHUNCHEON': 'food_gangneung_potato_bread',
  'POTATO_JAJU_SEED': 'variety_chubaek',
  'POTATO_RARE_SEED': 'variety_chubaek',
  'POTATO_GOLDEN_GANGWON': 'variety_daepung',
  'POTATO_GOLDEN_HONGCHEON': 'variety_daepung',
  'POTATO_HANWOO_SEED': 'variety_daeji',
  'POTATO_JAJAK_INJE': 'variety_chudong',
  'POTATO_LEGEND_PYEONGCHANG': 'variety_yeokgang',
  'POTATO_LEGEND_YANGGU': 'variety_yeokgang',
  'POTATO_PEACE_COSUNG': 'variety_chubaek',
  'POTATO_DURUMI_SEED': 'variety_chudong',
};

String potatoLocalAssetPath(String code) {
  final normalizedCode = code.trim().toUpperCase();
  final assetName = _potatoAssetByCode[normalizedCode];
  if (assetName == null) {
    return potatoDefaultAssetPath;
  }
  return 'assets/characters/potatoes/$assetName.png';
}
