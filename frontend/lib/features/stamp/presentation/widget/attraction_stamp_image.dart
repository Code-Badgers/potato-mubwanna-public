import 'package:flutter/material.dart';

const attractionStampAssets = <String, String>{
  '남이섬': 'assets/stamps/nami_island.png',
  '소양강 스카이워크': 'assets/stamps/soyang_skywalk.png',
  '뮤지엄 산': 'assets/stamps/museum_san.png',
  '안목해변': 'assets/stamps/anmok_beach.png',
  '경포대': 'assets/stamps/gyeongpodae.png',
  '묵호등대': 'assets/stamps/mukho_lighthouse.png',
  '논골담길': 'assets/stamps/nongoldam_road.png',
  '황지연못': 'assets/stamps/hwangji_pond.png',
  '속초관광수산시장': 'assets/stamps/sokcho_market.png',
  '영금정': 'assets/stamps/yeonggeumjeong.png',
  '환선굴': 'assets/stamps/hwanseon_cave.png',
  '장호항': 'assets/stamps/jangho_port.png',
  '수타사': 'assets/stamps/sutasa.png',
  '비발디파크': 'assets/stamps/vivaldi_park.png',
  '횡성호수길': 'assets/stamps/hoengseong_lake_trail.png',
  '청령포': 'assets/stamps/cheongnyeongpo.png',
  '장릉': 'assets/stamps/jangneung.png',
  '대관령 양떼목장': 'assets/stamps/daegwallyeong_sheep_ranch.png',
  '이효석문학관': 'assets/stamps/lee_hyoseok_museum.png',
  '정선 5일장': 'assets/stamps/jeongseon_market.png',
  '고석정': 'assets/stamps/goseokjeong.png',
  '산천어축제장': 'assets/stamps/sancheoneo_festival.png',
  '박수근미술관': 'assets/stamps/park_sookeun_museum.png',
  '두타연': 'assets/stamps/dutayeon.png',
  '원대리 자작나무숲': 'assets/stamps/wondaeri_birch_forest.png',
  '통일전망대': 'assets/stamps/unification_observatory.png',
  '화진포': 'assets/stamps/hwajinpo.png',
  '서피비치': 'assets/stamps/surfyy_beach.png',
  '낙산사': 'assets/stamps/naksansa.png',
};

String? attractionStampAssetFor(String spotName) {
  return attractionStampAssets[spotName.trim()];
}

class AttractionStampImage extends StatelessWidget {
  const AttractionStampImage({
    required this.spotName,
    required this.size,
    required this.fallback,
    this.semanticLabel,
    super.key,
  });

  final String spotName;
  final double size;
  final Widget fallback;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final assetPath = attractionStampAssetFor(spotName);
    if (assetPath == null) {
      return fallback;
    }

    return Image.asset(
      assetPath,
      key: ValueKey('attraction-stamp-$spotName'),
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: semanticLabel ?? '$spotName 스탬프',
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}
