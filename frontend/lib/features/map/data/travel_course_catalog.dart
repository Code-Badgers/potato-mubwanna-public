import '../domain/map_spot.dart';

class TravelCourse {
  const TravelCourse({
    required this.id,
    required this.title,
    required this.categoryTitle,
    required this.description,
    required this.editorialIntro,
    required this.tags,
    required this.heroImageAsset,
    required this.heroImageUrl,
    required this.estimatedDuration,
    required this.focusLabel,
    required this.stops,
  });

  final String id;
  final String title;
  final String categoryTitle;
  final String description;
  final String editorialIntro;
  final List<String> tags;
  final String heroImageAsset;
  final String? heroImageUrl;
  final String estimatedDuration;
  final String focusLabel;
  final List<TravelCourseStop> stops;

  List<MapSpot> get spots => stops.map((stop) => stop.spot).toList();
}

class TravelCourseStop {
  const TravelCourseStop({
    required this.spot,
    required this.heading,
    required this.editorial,
    required this.featureLabel,
    required this.imageAsset,
    required this.transitionText,
  });

  final MapSpot spot;
  final String heading;
  final String editorial;
  final String featureLabel;
  final String imageAsset;
  final String transitionText;
}

class _TravelCourseDefinition {
  const _TravelCourseDefinition({
    required this.id,
    required this.title,
    required this.categoryTitle,
    required this.description,
    required this.editorialIntro,
    required this.tags,
    required this.heroImageAsset,
    required this.estimatedDuration,
    required this.focusLabel,
    required this.placeSpecs,
  });

  final String id;
  final String title;
  final String categoryTitle;
  final String description;
  final String editorialIntro;
  final List<String> tags;
  final String heroImageAsset;
  final String estimatedDuration;
  final String focusLabel;
  final List<_TravelCoursePlaceSpec> placeSpecs;

  TravelCourse resolve(List<MapSpot> spots) {
    final usedSpotIds = <String>{};
    final stops = <TravelCourseStop>[];

    for (final spec in placeSpecs) {
      final spot = spec.match(spots, usedSpotIds) ??
          _fallbackSpot(spots, spec.categories, usedSpotIds);
      if (spot == null) {
        continue;
      }
      usedSpotIds.add(spot.id);
      stops.add(
        TravelCourseStop(
          spot: spot,
          heading: spec.heading ?? spec.featureLabel,
          editorial: spec.editorial,
          featureLabel: spec.featureLabel,
          imageAsset: spec.imageAsset,
          transitionText: spec.transitionText,
        ),
      );
    }

    return TravelCourse(
      id: id,
      title: title,
      categoryTitle: categoryTitle,
      description: description,
      editorialIntro: editorialIntro,
      tags: tags,
      heroImageAsset: heroImageAsset,
      heroImageUrl: _resolveHeroImageUrl(spots, stops),
      estimatedDuration: estimatedDuration,
      focusLabel: focusLabel,
      stops: stops,
    );
  }

  String? _resolveHeroImageUrl(
    List<MapSpot> spots,
    List<TravelCourseStop> stops,
  ) {
    for (final spec in placeSpecs) {
      final imageUrl = _matchingImageUrl(
        spots,
        spec.categories,
        spec.nameKeywords,
      );
      if (imageUrl != null) {
        return imageUrl;
      }
    }
    for (final stop in stops) {
      final imageUrl = _validImageUrl(stop.spot.imageUrl);
      if (imageUrl != null) {
        return imageUrl;
      }
    }
    final courseCategories =
        placeSpecs.expand((spec) => spec.categories).toSet();
    return _matchingImageUrl(spots, courseCategories, const []);
  }

  String? _matchingImageUrl(
    List<MapSpot> spots,
    Set<String> categories,
    List<String> nameKeywords,
  ) {
    for (final spot in spots) {
      if (!categories.contains(spot.category)) {
        continue;
      }
      final text = '${spot.name} ${spot.address} ${spot.cityName}';
      final matchesName =
          nameKeywords.isEmpty || nameKeywords.any(text.contains);
      if (!matchesName) {
        continue;
      }
      final imageUrl = _validImageUrl(spot.imageUrl);
      if (imageUrl != null) {
        return imageUrl;
      }
    }
    return null;
  }

  String? _validImageUrl(String? imageUrl) {
    final trimmed = imageUrl?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  MapSpot? _fallbackSpot(
    List<MapSpot> spots,
    Set<String> categories,
    Set<String> usedSpotIds,
  ) {
    for (final spot in spots) {
      if (!usedSpotIds.contains(spot.id) &&
          categories.contains(spot.category)) {
        return spot;
      }
    }
    for (final spot in spots) {
      if (!usedSpotIds.contains(spot.id)) {
        return spot;
      }
    }
    return null;
  }
}

class _TravelCoursePlaceSpec {
  const _TravelCoursePlaceSpec({
    required this.nameKeywords,
    required this.categories,
    this.heading,
    required this.editorial,
    required this.featureLabel,
    required this.imageAsset,
    this.transitionText = '',
  });

  final List<String> nameKeywords;
  final Set<String> categories;
  final String? heading;
  final String editorial;
  final String featureLabel;
  final String imageAsset;
  final String transitionText;

  MapSpot? match(List<MapSpot> spots, Set<String> usedSpotIds) {
    for (final spot in spots) {
      if (usedSpotIds.contains(spot.id) ||
          !categories.contains(spot.category)) {
        continue;
      }
      final text = '${spot.name} ${spot.address} ${spot.cityName}';
      final matchesName =
          nameKeywords.isEmpty || nameKeywords.any(text.contains);
      if (matchesName) {
        return spot;
      }
    }
    return null;
  }
}

final _travelCourseCache = <String, List<TravelCourse>>{};

List<TravelCourse> buildTravelCourses(List<MapSpot> spots) {
  final cacheKey = _travelCourseCacheKey(spots);
  final cached = _travelCourseCache[cacheKey];
  if (cached != null) {
    return cached;
  }

  final courses = _travelCourseDefinitions
      .map((definition) => definition.resolve(spots))
      .toList(growable: false);

  if (_travelCourseCache.length >= 8) {
    _travelCourseCache.clear();
  }
  _travelCourseCache[cacheKey] = courses;
  return courses;
}

String _travelCourseCacheKey(List<MapSpot> spots) {
  if (spots.isEmpty) {
    return 'empty';
  }
  return spots
      .map(
        (spot) => [
          spot.id,
          spot.name,
          spot.category,
          spot.cityName,
          spot.imageUrl ?? '',
          spot.congestionLevel,
        ].join(':'),
      )
      .join('|');
}

const _foodCategories = {
  'POTATO_RESTAURANT',
  'POTATO_SNACK',
  'POTATO_CAFE',
  'POTATO_MARKET',
};

const _tourCategories = {
  'POTATO_TOUR',
  'POTATO_SHOP',
  'POTATO_EXPERIENCE',
  'POTATO_MARKET',
};

const _seaCategories = {
  'POTATO_CAFE',
  'POTATO_TOUR',
  'POTATO_SNACK',
};

const _travelCourseDefinitions = [
  _TravelCourseDefinition(
    id: 'potato_food',
    title: '오늘 감자로 배 채워볼까? 🥔',
    categoryTitle: '강원도 감자 먹거리 코스',
    description: '감자전부터 옹심이, 감자 디저트까지 배부르게 이어가요.',
    editorialIntro: '시장에서 바삭한 감자전을 먹고 따뜻한 옹심이로 마무리하는 하루',
    tags: ['감자전', '옹심이', '감자빵'],
    heroImageAsset:
        'assets/stamps/passport/spots/passport_spot_20_jeongseon_market.png',
    estimatedDuration: '약 4~6시간',
    focusLabel: '먹거리 중심',
    placeSpecs: [
      _TravelCoursePlaceSpec(
        nameKeywords: ['감자', '옹심이', '전'],
        categories: _foodCategories,
        heading: '첫 끼는 따뜻하게',
        editorial:
            '강원도 감자 여행은 든든한 한 끼에서 시작해요. 고소하고 따뜻한 맛을 먼저 채워두면 다음 걸음도 가벼워집니다.',
        featureLabel: '감자 요리',
        imageAsset:
            'assets/stamps/passport/spots/passport_spot_20_jeongseon_market.png',
        transitionText: '배를 든든히 채웠다면, 이제 골목의 온도를 느껴볼 차례예요.',
      ),
      _TravelCoursePlaceSpec(
        nameKeywords: ['시장', '5일장', '중앙시장'],
        categories: _foodCategories,
        editorial: '시장 골목에서는 걷는 속도도 조금 느려져요. 간식 하나 고르는 재미까지 여행의 일부로 남겨보세요.',
        featureLabel: '시장 먹거리',
        imageAsset:
            'assets/stamps/passport/spots/passport_spot_09_sokcho_market.png',
      ),
      _TravelCoursePlaceSpec(
        nameKeywords: ['감자빵', '카페', '빵'],
        categories: _foodCategories,
        editorial: '마지막은 달콤한 감자 디저트로 가볍게 쉬어가기 좋아요. 사진 한 장 남기기에도 부담 없는 코스예요.',
        featureLabel: '감자 디저트',
        imageAsset:
            'assets/stamps/passport/spots/passport_spot_05_anmok_beach.png',
      ),
    ],
  ),
  _TravelCourseDefinition(
    id: 'people_energy',
    title: '사람 구경도 여행이지! 👋',
    categoryTitle: '활기찬 강원 여행',
    description: '시장과 거리, 사람들이 모이는 곳을 기분 좋게 둘러봐요.',
    editorialIntro: '북적이는 시장과 해변 거리를 따라 강원도의 생기를 느끼는 코스',
    tags: ['시장', '핫플', '먹거리'],
    heroImageAsset:
        'assets/stamps/passport/spots/passport_spot_09_sokcho_market.png',
    estimatedDuration: '반나절~하루',
    focusLabel: '활기찬 장소',
    placeSpecs: [
      _TravelCoursePlaceSpec(
        nameKeywords: ['시장', '5일장', '중앙시장'],
        categories: _tourCategories,
        heading: '사람 냄새 나는 시작',
        editorial: '사람들이 모이는 곳에는 그 지역의 리듬이 있어요. 가볍게 둘러보며 강원도의 오늘을 만나보세요.',
        featureLabel: '시장 산책',
        imageAsset:
            'assets/stamps/passport/spots/passport_spot_09_sokcho_market.png',
        transitionText: '활기를 조금 담았다면, 바다 가까운 거리로 걸음을 옮겨봐요.',
      ),
      _TravelCoursePlaceSpec(
        nameKeywords: ['해변', '서피', '안목', '거리'],
        categories: _seaCategories,
        editorial: '바다 근처의 활기찬 거리는 그냥 걸어도 여행 기분이 납니다. 커피나 간식을 곁들이면 더 좋아요.',
        featureLabel: '해변 거리',
        imageAsset:
            'assets/stamps/passport/spots/passport_spot_29_surfyy_beach.png',
      ),
      _TravelCoursePlaceSpec(
        nameKeywords: ['체험', '축제', '파크'],
        categories: _tourCategories,
        editorial: '조금 더 움직이고 싶을 때 들르기 좋은 곳이에요. 여행의 텐션을 한 번 끌어올려줍니다.',
        featureLabel: '체험 명소',
        imageAsset:
            'assets/stamps/passport/spots/passport_spot_13_vivaldi_park.png',
      ),
    ],
  ),
  _TravelCourseDefinition(
    id: 'gangwon_hotplace',
    title: '강원도에서 요즘 제일 핫한 곳 🔥',
    categoryTitle: '강원 핫플 코스',
    description: '카페, 포토스팟, 인기 명소를 부담 없이 묶어봤어요.',
    editorialIntro: '사진 찍고 쉬고 다시 움직이기 좋은 강원 대표 핫플 코스',
    tags: ['핫플', '카페', '포토스팟'],
    heroImageAsset:
        'assets/stamps/passport/spots/passport_spot_03_museum_san.png',
    estimatedDuration: '약 5~7시간',
    focusLabel: '인기 명소',
    placeSpecs: [
      _TravelCoursePlaceSpec(
        nameKeywords: ['뮤지엄', '미술관', '아트'],
        categories: _tourCategories,
        heading: '공간이 먼저 말을 거는 곳',
        editorial: '공간 자체가 기억에 남는 곳이에요. 천천히 둘러보다 보면 여행 사진도 자연스럽게 채워집니다.',
        featureLabel: '문화 공간',
        imageAsset:
            'assets/stamps/passport/spots/passport_spot_03_museum_san.png',
        transitionText: '사진을 충분히 남겼다면, 잠깐 쉬어갈 수 있는 곳으로 이어가요.',
      ),
      _TravelCoursePlaceSpec(
        nameKeywords: ['카페', '감자빵', '안목'],
        categories: _foodCategories,
        editorial: '쉬어가는 시간이 여행의 중심이 될 때가 있어요. 창밖 풍경과 함께 잠깐 멈춰보세요.',
        featureLabel: '감성 카페',
        imageAsset:
            'assets/stamps/passport/spots/passport_spot_05_anmok_beach.png',
      ),
      _TravelCoursePlaceSpec(
        nameKeywords: ['서피', '해변', '경포'],
        categories: _seaCategories,
        editorial: '가볍게 걷고 사진 남기기 좋은 바다 쪽 코스예요. 날씨가 좋다면 더 오래 머물고 싶어집니다.',
        featureLabel: '바다 포토스팟',
        imageAsset:
            'assets/stamps/passport/spots/passport_spot_29_surfyy_beach.png',
      ),
    ],
  ),
  _TravelCourseDefinition(
    id: 'introvert',
    title: '사람 많은 곳은 조금 힘들어요 🌿',
    categoryTitle: '내향인을 위한 여유로운 강원 여행',
    description: '한적한 숲길과 조용한 자연을 중심으로 쉬어가요.',
    editorialIntro: '많이 말하지 않아도 좋은 곳들만 골라 천천히 걷는 여행',
    tags: ['한적함', '산책', '자연'],
    heroImageAsset:
        'assets/stamps/passport/spots/passport_spot_25_wondaeri_birch_forest.png',
    estimatedDuration: '약 4~6시간',
    focusLabel: '여유로운 산책',
    placeSpecs: [
      _TravelCoursePlaceSpec(
        nameKeywords: ['자작', '숲', '수타사'],
        categories: _tourCategories,
        heading: '말보다 바람이 좋은 날',
        editorial: '사람 많은 곳보다 나무 사이 바람이 더 반가운 날이 있죠. 조용히 걸으며 마음을 정리하기 좋아요.',
        featureLabel: '숲길 산책',
        imageAsset:
            'assets/stamps/passport/spots/passport_spot_25_wondaeri_birch_forest.png',
        transitionText: '조용한 숲길 뒤에는 물가를 따라 속도를 조금 더 낮춰봐요.',
      ),
      _TravelCoursePlaceSpec(
        nameKeywords: ['호수', '청령포', '두타연'],
        categories: _tourCategories,
        editorial: '물가를 따라 걷는 코스는 발걸음을 재촉하지 않아요. 잠깐 앉아 쉬기에도 좋은 분위기예요.',
        featureLabel: '물가 풍경',
        imageAsset:
            'assets/stamps/passport/spots/passport_spot_17_cheongnyeongpo.png',
      ),
      _TravelCoursePlaceSpec(
        nameKeywords: ['문학관', '미술관', '박물관'],
        categories: _tourCategories,
        editorial: '조용한 전시 공간은 여행의 속도를 낮춰줘요. 복잡한 일정 대신 한 곳을 오래 보는 날에 어울립니다.',
        featureLabel: '차분한 전시',
        imageAsset:
            'assets/stamps/passport/spots/passport_spot_19_lee_hyoseok_museum.png',
      ),
    ],
  ),
  _TravelCourseDefinition(
    id: 'east_sea',
    title: '오늘은 바다만 보고 싶어 🌊',
    categoryTitle: '동해 바다 여행',
    description: '해변과 항구, 오션뷰를 따라 바다만 보러 가는 코스예요.',
    editorialIntro: '동해 바람을 따라 움직이고, 마음에 드는 바다 앞에서 오래 머무는 하루',
    tags: ['바다', '해변', '오션뷰'],
    heroImageAsset:
        'assets/stamps/passport/spots/passport_spot_10_yeonggeumjeong.png',
    estimatedDuration: '반나절~하루',
    focusLabel: '바다 중심',
    placeSpecs: [
      _TravelCoursePlaceSpec(
        nameKeywords: ['안목', '해변', '카페'],
        categories: _seaCategories,
        heading: '커피보다 먼저 보이는 바다',
        editorial: '바다를 보며 쉬고 싶다면 첫 목적지로 좋아요. 커피 한 잔과 파도 소리만으로도 충분합니다.',
        featureLabel: '오션뷰 카페',
        imageAsset:
            'assets/stamps/passport/spots/passport_spot_05_anmok_beach.png',
        transitionText: '파도 소리를 들었다면, 조금 더 가까운 해안 풍경으로 이동해요.',
      ),
      _TravelCoursePlaceSpec(
        nameKeywords: ['영금정', '등대', '항'],
        categories: _seaCategories,
        editorial: '바위와 파도가 가까운 곳에서는 풍경이 조금 더 선명해져요. 짧게 들러도 인상이 남는 장소입니다.',
        featureLabel: '해안 전망',
        imageAsset:
            'assets/stamps/passport/spots/passport_spot_10_yeonggeumjeong.png',
      ),
      _TravelCoursePlaceSpec(
        nameKeywords: ['장호', '서피', '낙산'],
        categories: _seaCategories,
        editorial: '마지막은 탁 트인 해변으로 이어가보세요. 걷기만 해도 여행의 끝이 산뜻해집니다.',
        featureLabel: '해변 산책',
        imageAsset:
            'assets/stamps/passport/spots/passport_spot_11_jangho_port.png',
      ),
    ],
  ),
  _TravelCourseDefinition(
    id: 'photo_mood',
    title: '그냥 찍어도 분위기 좋은 곳 📷',
    categoryTitle: '사진 찍기 좋은 느좋 코스',
    description: '전망, 건축, 자연이 예쁘게 남는 장소를 골랐어요.',
    editorialIntro: '많이 꾸미지 않아도 사진 한 장이 여행 기록처럼 남는 코스',
    tags: ['포토스팟', '감성', '풍경'],
    heroImageAsset:
        'assets/stamps/passport/spots/passport_spot_28_naksansa.png',
    estimatedDuration: '약 4~6시간',
    focusLabel: '사진 중심',
    placeSpecs: [
      _TravelCoursePlaceSpec(
        nameKeywords: ['뮤지엄', '미술관', '건축'],
        categories: _tourCategories,
        heading: '선과 여백이 예쁜 공간',
        editorial: '선과 여백이 예쁜 공간은 사진을 어렵지 않게 만들어줘요. 천천히 걸으며 마음에 드는 구도를 찾아보세요.',
        featureLabel: '건축 감성',
        imageAsset:
            'assets/stamps/passport/spots/passport_spot_03_museum_san.png',
        transitionText: '공간의 사진을 담았다면 이번에는 넓게 열린 풍경을 만나러 가요.',
      ),
      _TravelCoursePlaceSpec(
        nameKeywords: ['낙산', '전망대', '고석정', '경포'],
        categories: _tourCategories,
        editorial: '풍경이 넓게 열리는 곳에서는 한 장만 찍어도 여행 분위기가 살아납니다. 해 질 무렵이면 더 좋아요.',
        featureLabel: '전망 명소',
        imageAsset:
            'assets/stamps/passport/spots/passport_spot_28_naksansa.png',
      ),
      _TravelCoursePlaceSpec(
        nameKeywords: ['자작', '숲', '꽃', '해변'],
        categories: _tourCategories,
        editorial: '자연의 색이 좋은 장소는 오래 보아도 질리지 않아요. 앨범에 남기기 좋은 느긋한 마무리 코스입니다.',
        featureLabel: '자연 사진',
        imageAsset:
            'assets/stamps/passport/spots/passport_spot_25_wondaeri_birch_forest.png',
      ),
    ],
  ),
];
