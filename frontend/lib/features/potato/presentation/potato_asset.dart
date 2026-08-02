const _potatoAssetAliases = <String, String>{
  'POTATO_COMMON_SEED': 'POTATO_HAJI_SEED',
  'POTATO_GOLDEN_HONGCHEON': 'POTATO_GOLDEN_GANGWON',
  'POTATO_HOBAN_CHUNCHEON': 'POTATO_HAJI_GANGNEUNG',
  'POTATO_RARE_SEED': 'POTATO_JAJU_SEED',
};

String potatoLocalAssetPath(String code) {
  final normalizedCode = code.trim().toUpperCase();
  final assetCode = _potatoAssetAliases[normalizedCode] ?? normalizedCode;
  return 'assets/potatoes/${assetCode.toLowerCase()}.png';
}
