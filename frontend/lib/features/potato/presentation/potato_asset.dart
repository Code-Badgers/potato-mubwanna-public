const potatoDefaultAssetPath =
    'assets/characters/potatoes/default_beginner_potato.png';

const potatoGrowthStageAssetPaths = <int, String>{
  1: 'assets/characters/potatoes/growth/potato_growth_stage_1_baby.png',
  2: 'assets/characters/potatoes/growth/potato_growth_stage_2_young.png',
  3: 'assets/characters/potatoes/growth/potato_growth_stage_3_chubby.png',
};

const _potatoAssetByCode = <String, String>{
  'POTATO_DEFAULT_BEGINNER': 'default_beginner_potato',
  'POTATO_HAJI_SEED': 'variety_sumi',
  'POTATO_COMMON_SEED': 'food_rest_stop_whole_potato',
  'POTATO_GONDRE_JEONGSEON': 'food_potato_ongsimi',
  'POTATO_HAJI_GANGNEUNG': 'food_gangneung_potato_bread',
  'POTATO_HOBAN_CHUNCHEON': 'food_gangneung_potato_bread',
  'POTATO_JAJU_SEED': 'variety_dubaek',
  'POTATO_RARE_SEED': 'food_tornado_potato',
  'POTATO_GOLDEN_GANGWON': 'variety_daepung',
  'POTATO_GOLDEN_HONGCHEON': 'food_potato_pancake',
  'POTATO_HANWOO_SEED': 'variety_daeji',
  'POTATO_JAJAK_INJE': 'food_potato_beombeok',
  'POTATO_LEGEND_PYEONGCHANG': 'variety_yeokgang',
  'POTATO_LEGEND_YANGGU': 'variety_daeseo_atlantic',
  'POTATO_PEACE_COSUNG': 'variety_chubaek',
  'POTATO_DURUMI_SEED': 'variety_chudong',
};

const _availablePotatoAssetNames = <String>{
  'default_beginner_potato',
  'food_rest_stop_whole_potato',
  'food_gangneung_potato_bread',
  'food_potato_pancake',
  'food_potato_ongsimi',
  'food_tornado_potato',
  'food_potato_beombeok',
  'food_potato_chip',
  'food_potato_rice_cake',
  'food_potato_croquette',
  'food_potato_soup',
  'variety_sumi',
  'variety_dubaek',
  'variety_daeseo_atlantic',
  'variety_jopung',
  'variety_daeji',
  'variety_bangul',
  'variety_chubaek',
  'variety_chudong',
  'variety_yeokgang',
  'variety_daepung',
};

String potatoLocalAssetPath(String code) {
  final normalizedCode = code.trim().toUpperCase();
  final directAssetName = normalizedCode.toLowerCase();
  final assetName = _potatoAssetByCode[normalizedCode] ??
      (_availablePotatoAssetNames.contains(directAssetName)
          ? directAssetName
          : null);
  if (assetName == null) {
    return potatoDefaultAssetPath;
  }
  return 'assets/characters/potatoes/$assetName.png';
}

String potatoGrowthStageAssetPath({
  required int stage,
  required String finalPotatoCode,
}) {
  if (stage >= 4) {
    return potatoLocalAssetPath(finalPotatoCode);
  }
  return potatoGrowthStageAssetPaths[stage] ?? potatoGrowthStageAssetPaths[1]!;
}
