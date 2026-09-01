import 'package:flutter/material.dart';

const attractionStampAssets = <String, String>{
  '남이섬': 'assets/stamps/nami_island_stamp.png',
  '소양강 스카이워크': 'assets/stamps/soyang_skywalk_stamp.png',
  '뮤지엄 산': 'assets/stamps/museum_san_stamp.png',
  '안목해변': 'assets/stamps/anmok_beach_stamp.png',
  '경포대': 'assets/stamps/gyeongpodae_stamp.png',
  '묵호등대': 'assets/stamps/mukho_lighthouse_stamp.png',
  '논골담길': 'assets/stamps/nongoldam_road_stamp.png',
  '황지연못': 'assets/stamps/hwangji_pond_stamp.png',
  '속초관광수산시장': 'assets/stamps/sokcho_market_stamp.png',
  '영금정': 'assets/stamps/yeonggeumjeong_stamp.png',
  '환선굴': 'assets/stamps/hwanseon_cave_stamp.png',
  '장호항': 'assets/stamps/jangho_port_stamp.png',
  '수타사': 'assets/stamps/sutasa_stamp.png',
  '비발디파크': 'assets/stamps/vivaldi_park_stamp.png',
  '횡성호수길': 'assets/stamps/hoengseong_lake_trail_stamp.png',
  '청령포': 'assets/stamps/cheongnyeongpo_stamp.png',
  '장릉': 'assets/stamps/jangneung_stamp.png',
  '대관령 양떼목장': 'assets/stamps/daegwallyeong_sheep_ranch_stamp.png',
  '이효석문학관': 'assets/stamps/lee_hyoseok_museum_stamp.png',
  '정선 5일장': 'assets/stamps/jeongseon_market_stamp.png',
  '고석정': 'assets/stamps/goseokjeong_stamp.png',
  '산천어축제장': 'assets/stamps/sancheoneo_festival_stamp.png',
  '박수근미술관': 'assets/stamps/park_sookeun_museum_stamp.png',
  '두타연': 'assets/stamps/dutayeon_stamp.png',
  '원대리 자작나무숲': 'assets/stamps/wondaeri_birch_forest_stamp.png',
  '통일전망대': 'assets/stamps/unification_observatory_stamp.png',
  '화진포': 'assets/stamps/hwajinpo_stamp.png',
  '서피비치': 'assets/stamps/surfyy_beach_stamp.png',
  '낙산사': 'assets/stamps/naksansa_stamp.png',
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
