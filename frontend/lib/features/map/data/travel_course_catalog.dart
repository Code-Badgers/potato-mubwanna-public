import '../domain/map_spot.dart';

class TravelCourse {
  const TravelCourse({
    required this.id,
    required this.title,
    required this.categoryTitle,
    required this.description,
    required this.editorialIntro,
    required this.tags,
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
    required this.transitionText,
  });

  final MapSpot spot;
  final String heading;
  final String editorial;
  final String featureLabel;
  final String transitionText;
}

class _TravelCourseDefinition {
  const _TravelCourseDefinition({
    required this.id,
    required this.title,
    required this.categoryTitle,
    required this.focusLabel,
    required this.placeSpecs,
  });

  final String id;
  final String title;
  final String categoryTitle;
  final String focusLabel;
  final List<_TravelCoursePlaceSpec> placeSpecs;

  TravelCourse? resolve(List<MapSpot> spots) {
    final byCity = <String, List<MapSpot>>{};
    for (final spot in spots) {
      final city = spot.cityName.trim().replaceFirst(RegExp(r'(시|군)$'), '');
      if (city.isNotEmpty) {
        byCity.putIfAbsent(city, () => []).add(spot);
      }
    }

    var selectedCity = '';
    var selected = <(_TravelCoursePlaceSpec, MapSpot)>[];
    // 같은 시군 안에서 설명에 맞는 장소가 가장 많이 모이는 코스를 선택한다.
    for (final entry in byCity.entries) {
      final usedIds = <String>{};
      final matches = <(_TravelCoursePlaceSpec, MapSpot)>[];
      for (final spec in placeSpecs) {
        final spot = spec.match(entry.value, usedIds);
        if (spot != null) {
          usedIds.add(spot.id);
          matches.add((spec, spot));
        }
      }
      if (matches.length > selected.length) {
        selectedCity = entry.key;
        selected = matches;
      }
    }
    if (selected.length < 2) return null;

    final isComplete = selected.length == placeSpecs.length;
    final stops = [
      for (final (spec, spot) in selected)
        TravelCourseStop(
          spot: spot,
          heading: spec.featureLabel,
          editorial: isComplete
              ? spec.editorial
              : '${spot.name}에서 ${spec.featureLabel}을 즐겨보세요. 방문 전 운영 정보를 확인해주세요.',
          featureLabel: spec.featureLabel,
          // 누락된 다음 장소를 안내하지 않도록 고정 전환 문구는 생략한다.
          transitionText: '',
        ),
    ];
    final images = stops.expand((stop) => stop.spot.effectiveImageUrls);
    return TravelCourse(
      id: id,
      title: title,
      categoryTitle: categoryTitle,
      description: '$selectedCity에서 함께 둘러볼 ${stops.length}곳을 골랐어요.',
      editorialIntro: stops.map((stop) => stop.spot.name).join(' → '),
      tags: [selectedCity, ...stops.map((stop) => stop.featureLabel)],
      heroImageUrl: images.isEmpty ? null : images.first,
      estimatedDuration: '차량 이동시간 미산정',
      focusLabel: focusLabel,
      stops: stops,
    );
  }
}

class _TravelCoursePlaceSpec {
  const _TravelCoursePlaceSpec({
    required this.nameKeywords,
    required this.categories,
    required this.editorial,
    required this.featureLabel,
  });

  final List<String> nameKeywords;
  final Set<String> categories;
  final String editorial;
  final String featureLabel;

  MapSpot? match(List<MapSpot> spots, Set<String> usedSpotIds) {
    for (final spot in spots) {
      if (usedSpotIds.contains(spot.id) ||
          !categories.contains(spot.category)) {
        continue;
      }
      final text = spot.name;
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
      .whereType<TravelCourse>()
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
          spot.imageUrls.join(','),
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
    focusLabel: '먹거리 중심',
    placeSpecs: [
      _TravelCoursePlaceSpec(
        nameKeywords: ['감자', '옹심이'],
        categories: {'POTATO_RESTAURANT'},
        editorial:
            '강원도 감자 여행은 든든한 한 끼에서 시작해요. 고소하고 따뜻한 맛을 먼저 채워두면 다음 걸음도 가벼워집니다.',
        featureLabel: '감자 요리',
      ),
      _TravelCoursePlaceSpec(
        nameKeywords: ['시장', '5일장', '중앙시장'],
        categories: _foodCategories,
        editorial: '시장 골목에서는 걷는 속도도 조금 느려져요. 간식 하나 고르는 재미까지 여행의 일부로 남겨보세요.',
        featureLabel: '시장 먹거리',
      ),
      _TravelCoursePlaceSpec(
        nameKeywords: ['감자빵', '카페', '빵'],
        categories: {'POTATO_CAFE', 'POTATO_SNACK'},
        editorial: '마지막은 달콤한 감자 디저트로 가볍게 쉬어가기 좋아요. 사진 한 장 남기기에도 부담 없는 코스예요.',
        featureLabel: '감자 디저트',
      ),
    ],
  ),
  _TravelCourseDefinition(
    id: 'people_energy',
    title: '사람 구경도 여행이지! 👋',
    categoryTitle: '활기찬 강원 여행',
    focusLabel: '활기찬 장소',
    placeSpecs: [
      _TravelCoursePlaceSpec(
        nameKeywords: ['시장', '5일장', '중앙시장'],
        categories: _tourCategories,
        editorial: '사람들이 모이는 곳에는 그 지역의 리듬이 있어요. 가볍게 둘러보며 강원도의 오늘을 만나보세요.',
        featureLabel: '시장 산책',
      ),
      _TravelCoursePlaceSpec(
        nameKeywords: ['해변', '서피', '안목', '거리'],
        categories: _seaCategories,
        editorial: '바다 근처의 활기찬 거리는 그냥 걸어도 여행 기분이 납니다. 커피나 간식을 곁들이면 더 좋아요.',
        featureLabel: '해변 거리',
      ),
      _TravelCoursePlaceSpec(
        nameKeywords: ['체험', '축제', '파크'],
        categories: _tourCategories,
        editorial: '조금 더 움직이고 싶을 때 들르기 좋은 곳이에요. 여행의 텐션을 한 번 끌어올려줍니다.',
        featureLabel: '체험 명소',
      ),
    ],
  ),
  _TravelCourseDefinition(
    id: 'gangwon_hotplace',
    title: '강원도에서 요즘 제일 핫한 곳 🔥',
    categoryTitle: '강원 핫플 코스',
    focusLabel: '인기 명소',
    placeSpecs: [
      _TravelCoursePlaceSpec(
        nameKeywords: ['뮤지엄', '미술관', '아트'],
        categories: _tourCategories,
        editorial: '공간 자체가 기억에 남는 곳이에요. 천천히 둘러보다 보면 여행 사진도 자연스럽게 채워집니다.',
        featureLabel: '문화 공간',
      ),
      _TravelCoursePlaceSpec(
        nameKeywords: ['카페', '감자빵', '안목'],
        categories: _foodCategories,
        editorial: '쉬어가는 시간이 여행의 중심이 될 때가 있어요. 창밖 풍경과 함께 잠깐 멈춰보세요.',
        featureLabel: '감성 카페',
      ),
      _TravelCoursePlaceSpec(
        nameKeywords: ['서피', '해변', '경포'],
        categories: _seaCategories,
        editorial: '가볍게 걷고 사진 남기기 좋은 바다 쪽 코스예요. 날씨가 좋다면 더 오래 머물고 싶어집니다.',
        featureLabel: '바다 포토스팟',
      ),
    ],
  ),
  _TravelCourseDefinition(
    id: 'introvert',
    title: '사람 많은 곳은 조금 힘들어요 🌿',
    categoryTitle: '내향인을 위한 여유로운 강원 여행',
    focusLabel: '여유로운 산책',
    placeSpecs: [
      _TravelCoursePlaceSpec(
        nameKeywords: ['자작', '숲', '수타사'],
        categories: _tourCategories,
        editorial: '사람 많은 곳보다 나무 사이 바람이 더 반가운 날이 있죠. 조용히 걸으며 마음을 정리하기 좋아요.',
        featureLabel: '숲길 산책',
      ),
      _TravelCoursePlaceSpec(
        nameKeywords: ['호수', '청령포', '두타연'],
        categories: _tourCategories,
        editorial: '물가를 따라 걷는 코스는 발걸음을 재촉하지 않아요. 잠깐 앉아 쉬기에도 좋은 분위기예요.',
        featureLabel: '물가 풍경',
      ),
      _TravelCoursePlaceSpec(
        nameKeywords: ['문학관', '미술관', '박물관'],
        categories: _tourCategories,
        editorial: '조용한 전시 공간은 여행의 속도를 낮춰줘요. 복잡한 일정 대신 한 곳을 오래 보는 날에 어울립니다.',
        featureLabel: '차분한 전시',
      ),
    ],
  ),
  _TravelCourseDefinition(
    id: 'east_sea',
    title: '오늘은 바다만 보고 싶어 🌊',
    categoryTitle: '동해 바다 여행',
    focusLabel: '바다 중심',
    placeSpecs: [
      _TravelCoursePlaceSpec(
        nameKeywords: ['안목', '해변', '오션뷰'],
        categories: {'POTATO_CAFE'},
        editorial: '바다를 보며 쉬고 싶다면 첫 목적지로 좋아요. 커피 한 잔과 파도 소리만으로도 충분합니다.',
        featureLabel: '오션뷰 카페',
      ),
      _TravelCoursePlaceSpec(
        nameKeywords: ['영금정', '등대', '항'],
        categories: _seaCategories,
        editorial: '바위와 파도가 가까운 곳에서는 풍경이 조금 더 선명해져요. 짧게 들러도 인상이 남는 장소입니다.',
        featureLabel: '해안 전망',
      ),
      _TravelCoursePlaceSpec(
        nameKeywords: ['장호', '서피', '낙산'],
        categories: _seaCategories,
        editorial: '마지막은 탁 트인 해변으로 이어가보세요. 걷기만 해도 여행의 끝이 산뜻해집니다.',
        featureLabel: '해변 산책',
      ),
    ],
  ),
  _TravelCourseDefinition(
    id: 'photo_mood',
    title: '그냥 찍어도 분위기 좋은 곳 📷',
    categoryTitle: '사진 찍기 좋은 느좋 코스',
    focusLabel: '사진 중심',
    placeSpecs: [
      _TravelCoursePlaceSpec(
        nameKeywords: ['뮤지엄', '미술관', '건축'],
        categories: _tourCategories,
        editorial: '선과 여백이 예쁜 공간은 사진을 어렵지 않게 만들어줘요. 천천히 걸으며 마음에 드는 구도를 찾아보세요.',
        featureLabel: '건축 감성',
      ),
      _TravelCoursePlaceSpec(
        nameKeywords: ['낙산', '전망대', '고석정', '경포'],
        categories: _tourCategories,
        editorial: '풍경이 넓게 열리는 곳에서는 한 장만 찍어도 여행 분위기가 살아납니다. 해 질 무렵이면 더 좋아요.',
        featureLabel: '전망 명소',
      ),
      _TravelCoursePlaceSpec(
        nameKeywords: ['자작', '숲', '꽃', '해변'],
        categories: _tourCategories,
        editorial: '자연의 색이 좋은 장소는 오래 보아도 질리지 않아요. 앨범에 남기기 좋은 느긋한 마무리 코스입니다.',
        featureLabel: '자연 사진',
      ),
    ],
  ),
];
