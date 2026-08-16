-- Align curated potato spots with the Notion category policy.
-- The DB keeps legacy enum values while the app groups them into five public categories.
INSERT INTO tourist_spots (
    content_id,
    content_type_id,
    name,
    category,
    latitude,
    longitude,
    address,
    city_name,
    image_url,
    source,
    potato_tags,
    congestion_level,
    verification_radius_meter,
    stamp_enabled,
    active,
    created_at,
    updated_at,
    rallybook_featured
)
SELECT
    seed.content_id,
    seed.content_type_id,
    seed.name,
    seed.category,
    seed.latitude,
    seed.longitude,
    seed.address,
    seed.city_name,
    NULL,
    'CURATED',
    seed.potato_tags,
    seed.congestion_level,
    100,
    TRUE,
    TRUE,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    FALSE
FROM (
    VALUES
        ('CURATED:KAKAO:20112823', 39, '감자네', 'POTATO_RESTAURANT', 37.6877726, 128.5590675, '강원특별자치도 평창군 진부면 방아다리로 360', '평창군', '감자,감자전,꿀치즈감자채전,식당', 'LOW'),
        ('CURATED:KAKAO:299186117', 39, '강릉감자천국', 'POTATO_CAFE', 37.7517752, 128.8977641, '강원특별자치도 강릉시 곶감전길 17', '강릉시', '감자,감자둥글레,감자채와플,카페디저트', 'NORMAL'),
        ('CURATED:KAKAO:1699821631', 39, '감자마을', 'POTATO_RESTAURANT', 37.8862570, 128.8252700, '강원특별자치도 강릉시 주문진읍 주문로 25-2', '강릉시', '감자,향토음식,식당,주문진', 'NORMAL'),
        ('CURATED:KAKAO:333181363', 39, '감자뭉팅이', 'POTATO_CAFE', 37.7532951, 128.8998725, '강원특별자치도 강릉시 중앙시장2길 46-1', '강릉시', '감자,감자뭉팅이,감자핫도그,카페디저트', 'NORMAL'),
        ('CURATED:KAKAO:9694908', 14, '감자꽃스튜디오', 'POTATO_EXPERIENCE', 37.3688085, 128.4388593, '강원특별자치도 평창군 평창읍 고길천로 105', '평창군', '감자,감자꽃,농촌문화예술,체험', 'LOW'),
        ('CURATED:ADDRESS:MEMILAE_GAMJA', 39, '메밀애감자', 'POTATO_RESTAURANT', 37.8709032, 128.8390941, '강원특별자치도 강릉시 연곡면 영진리 353-27', '강릉시', '감자,메밀,식당,향토음식', 'NORMAL'),
        ('CURATED:ADDRESS:YUKNAMMAE_GAMJA_BREAD', 39, '육남매감자빵', 'POTATO_CAFE', 37.9331171, 127.7882666, '강원특별자치도 춘천시 신북읍 상천2길 45 1층', '춘천시', '감자,감자빵,카페디저트,춘천', 'NORMAL'),
        ('CURATED:ADDRESS:APE_LOUNGE', 39, '에이프라운지', 'POTATO_CAFE', 37.3285742, 127.9889784, '강원특별자치도 원주시 웅비4길 11', '원주시', '감자,스모크포테이토버거,통감자그라탕,카페디저트', 'NORMAL'),
        ('CURATED:KAKAO:19304705', 14, '늘햇살 만우농촌체험마을', 'POTATO_EXPERIENCE', 37.5628575, 129.0755515, '강원특별자치도 동해시 마상천길 245', '동해시', '감자,감자캐기,농촌체험,체험', 'LOW'),
        ('CURATED:KAKAO:26985090', 38, '주문진수산시장', 'POTATO_MARKET', 37.8911119, 128.8277406, '강원특별자치도 강릉시 주문진읍 시장길 38', '강릉시', '감자,시장상권,로컬푸드,감자점포확인필요', 'NORMAL'),
        ('CURATED:KAKAO:10023986', 39, '포남사골옹심이', 'POTATO_RESTAURANT', 37.7650263, 128.9073738, '강원특별자치도 강릉시 남구길10번길 11', '강릉시', '감자,사골옹심이,감자송편,식당', 'NORMAL'),
        ('CURATED:ADDRESS:MAEUITAEJA_CLASS', 14, '마의태자권역마을 로컬 클래스', 'POTATO_EXPERIENCE', 37.8810990, 128.2566587, '강원특별자치도 인제군 상남면 김부대왕로 2376', '인제군', '감자,감자빵만들기,원데이클래스,체험', 'LOW'),
        ('CURATED:ADDRESS:GOTANSANDEULMI', 14, '고탄산들미마을', 'POTATO_EXPERIENCE', 37.9884866, 127.7042607, '강원특별자치도 춘천시 사북면 춘화로 485', '춘천시', '감자,감자캐기,농촌체험,체험', 'LOW'),
        ('CURATED:KAKAO:16108175', 39, '감자바우', 'POTATO_RESTAURANT', 37.8965530, 128.0365033, '강원특별자치도 홍천군 두촌면 장남리 411-1', '홍천군', '감자,향토음식,식당,홍천', 'LOW'),
        ('CURATED:KAKAO:1977116251', 39, '대관령감자옹심이', 'POTATO_RESTAURANT', 37.6800041, 128.7001895, '강원특별자치도 평창군 대관령면 경강로 5193', '평창군', '감자,감자옹심이,식당,대관령', 'LOW')
) AS seed(
    content_id,
    content_type_id,
    name,
    category,
    latitude,
    longitude,
    address,
    city_name,
    potato_tags,
    congestion_level
)
WHERE NOT EXISTS (
    SELECT 1
    FROM tourist_spots spot
    WHERE spot.content_id = seed.content_id
       OR (spot.name = seed.name AND spot.address = seed.address)
);

UPDATE tourist_spots
SET
    address = '강원특별자치도 강릉시 경강로2115번길 7',
    potato_tags = '감자,감자유원지,감자다방,포테이토교,굿즈,포파칩,관광쇼핑',
    updated_at = CURRENT_TIMESTAMP
WHERE content_id = 'CURATED:KAKAO:331311679';

UPDATE tourist_spots
SET
    name = '속초불탄감자빵 본점 아궁이카페',
    potato_tags = '감자,감자빵,아궁이카페,베이커리,카페디저트',
    updated_at = CURRENT_TIMESTAMP
WHERE content_id = 'CURATED:KAKAO:487698285';

UPDATE tourist_spots
SET
    potato_tags = '감자,감자빵,치즈감자빵,감자라떼,카페디저트',
    updated_at = CURRENT_TIMESTAMP
WHERE content_id = 'CURATED:GAMZABATT';

UPDATE tourist_spots
SET
    address = '강원특별자치도 강릉시 공항길30번길 5',
    potato_tags = '감자,감자적,감자전,옹심이,감자떡,식당',
    updated_at = CURRENT_TIMESTAMP
WHERE content_id = 'CURATED:KAKAO:11542807';

UPDATE tourist_spots
SET
    potato_tags = '감자,옹심이,장칼국수,감자전,식당',
    updated_at = CURRENT_TIMESTAMP
WHERE content_id = 'CURATED:KAKAO:11395119';

UPDATE tourist_spots
SET
    potato_tags = '감자,소품샵,기념품,관광쇼핑',
    updated_at = CURRENT_TIMESTAMP
WHERE content_id = 'CURATED:KAKAO:777074207';

UPDATE tourist_spots
SET
    potato_tags = '감자,감자맥주,브루펍,페어링,식당',
    updated_at = CURRENT_TIMESTAMP
WHERE category = 'POTATO_BREWERY';

INSERT INTO tourist_spot_menu_items (
    tourist_spot_id, name, price_won, price_note, display_order, source_url, verified_on, active
)
SELECT spot.tourist_spot_id, menu.name, menu.price_won, NULL, menu.display_order,
       'https://app.notion.com/p/3be51ca118cf803cb1aacbe1cb448423', DATE '2026-08-16', TRUE
FROM tourist_spots spot
JOIN (VALUES
    ('CURATED:KAKAO:20112823', '감자전', 10000, 1),
    ('CURATED:KAKAO:20112823', '꿀치즈감자채전', 15000, 2),
    ('CURATED:KAKAO:299186117', '감자 둥글레 6알', 4500, 1),
    ('CURATED:KAKAO:299186117', '감자 둥글레 10알', 7000, 2),
    ('CURATED:KAKAO:299186117', '감자채 와플', 5500, 3),
    ('CURATED:KAKAO:333181363', '감자뭉팅이', 5000, 1),
    ('CURATED:KAKAO:333181363', '청양감자뭉팅이', 5000, 2),
    ('CURATED:KAKAO:333181363', '치즈감자뭉팅이', 5500, 3),
    ('CURATED:KAKAO:333181363', '감자핫도그', 5000, 4),
    ('CURATED:KAKAO:10023986', '사골옹심이국수', 10000, 1),
    ('CURATED:KAKAO:10023986', '사골순옹심이', 11000, 2),
    ('CURATED:KAKAO:10023986', '감자송편', 11000, 3),
    ('CURATED:GAMZABATT', '감자빵', 3300, 2),
    ('CURATED:GAMZABATT', '치즈 감자빵', 3800, 3),
    ('CURATED:GAMZABATT', '감자라떼', 6000, 4),
    ('CURATED:KAKAO:11542807', '순옹심이', 8000, 2),
    ('CURATED:KAKAO:11542807', '칼옹심이', 8000, 3),
    ('CURATED:KAKAO:11542807', '흑임자 옹심이', 12000, 4),
    ('CURATED:KAKAO:11542807', '치즈말이 감자전', 9000, 5),
    ('CURATED:KAKAO:11542807', '감자떡', 7000, 6)
) AS menu(content_id, name, price_won, display_order)
    ON spot.content_id = menu.content_id
WHERE NOT EXISTS (
    SELECT 1
    FROM tourist_spot_menu_items existing
    WHERE existing.tourist_spot_id = spot.tourist_spot_id
      AND existing.name = menu.name
);
