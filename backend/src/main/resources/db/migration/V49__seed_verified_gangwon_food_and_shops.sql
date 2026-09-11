-- Collected on request on 2026-09-10/11 from Korea Tourism Organization KorService2.
-- Reproduce with searchKeyword2(keyword=감자/유리알유희/동그란책, lDongRegnCd=51)
-- and detailIntro2(contentId, contentTypeId), using a server-side service key.
-- Keep numeric TourAPI IDs so image/detail enrichment does not need name matching.
-- These are discovery places, not additional passport destinations or reward rules.
INSERT INTO tourist_spots (
    content_id, content_type_id, name, category, latitude, longitude,
    address, city_name, image_url, source, potato_tags, congestion_level,
    verification_radius_meter, stamp_enabled, active, created_at, updated_at,
    rallybook_featured
)
SELECT seed.content_id, seed.content_type_id, seed.name, seed.category,
       seed.latitude, seed.longitude, seed.address, seed.city_name, seed.image_url,
       'TOUR_API', seed.potato_tags, 'NORMAL', 100, FALSE, TRUE,
       CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, FALSE
FROM (VALUES
    ('1828984', 39, '감나무집 감자옹심이', 'POTATO_RESTAURANT', 38.2043134, 128.5909035,
     '강원특별자치도 속초시 중앙시장로 110-8 (중앙동)', '속초시', NULL, '감자,감자옹심이,속초,시장먹거리'),
    ('2876420', 39, '감자골옹심이', 'POTATO_RESTAURANT', 37.8670280, 127.7294009,
     '강원특별자치도 춘천시 공지로317번길 20 (효자동)', '춘천시', NULL, '감자,감자옹심이,메밀칼국수,춘천'),
    ('133817', 39, '강릉감자옹심 강릉본점', 'POTATO_RESTAURANT', 37.7564709, 128.8949084,
     '강원특별자치도 강릉시 토성로 171 (임당동)', '강릉시', NULL, '감자,감자옹심이,감자송편,강릉'),
    -- Image copyright division: Type3 (KTO attribution, no modification).
    ('2790029', 39, '봉평감자옹심이', 'POTATO_RESTAURANT', 37.6183574, 128.3765177,
     '강원특별자치도 평창군 봉평면 기풍로 182', '평창군',
     'https://tong.visitkorea.or.kr/cms/resource/89/2789989_image2_1.jpg', '감자,감자옹심이,감자전,봉평'),
    -- Image copyright division: Type3 (KTO attribution, no modification).
    ('2779972', 39, '샘터감자옹심이', 'POTATO_RESTAURANT', 37.3669007, 128.3942681,
     '강원특별자치도 평창군 평창읍 백오1길 18', '평창군',
     'https://tong.visitkorea.or.kr/cms/resource/47/2779947_image2_1.jpg', '감자,감자옹심이,메밀국수,평창'),
    ('2815461', 39, '한입감자', 'POTATO_CAFE', 37.3417944, 127.9235584,
     '강원특별자치도 원주시 만대로 17 매머드시티 무실 4차', '원주시', NULL, '감자,감자빵,고구마빵,원주'),
    -- Image copyright division: Type1 (KTO attribution).
    ('4093743', 38, '유리알유희', 'POTATO_SHOP', 37.7945347, 128.9182993,
     '강원특별자치도 강릉시 창해로 351-2 (강문동)', '강릉시',
     'https://tong.visitkorea.or.kr/cms/resource/36/4093336_image2_1.jpg', '소품샵,유리공예,여행기념품,강릉'),
    -- Independent shop inside the shipyard; do not merge it with the existing cafe.
    -- Preserve TourAPI's cultural content type 14 for detailIntro2 field mapping.
    -- Image copyright division: Type3 (KTO attribution, no modification).
    ('3041240', 14, '동그란책', 'POTATO_SHOP', 38.1984815, 128.5832997,
     '강원특별자치도 속초시 중앙로46번길 45 (교동)', '속초시',
     'https://tong.visitkorea.or.kr/cms/resource/21/3041221_image2_1.jpg', '소품샵,독립서점,그림책,속초')
) AS seed(content_id, content_type_id, name, category, latitude, longitude,
          address, city_name, image_url, potato_tags)
WHERE NOT EXISTS (
    SELECT 1 FROM tourist_spots spot
    WHERE spot.content_id = seed.content_id
       OR (spot.name = seed.name AND spot.city_name = seed.city_name
           AND ABS(spot.latitude - seed.latitude) < 0.0005
           AND ABS(spot.longitude - seed.longitude) < 0.0005)
);

-- detailIntro2 confirms menu names but provides no price for these restaurants.
-- Persist the source and collection date; never turn a missing price into zero.
INSERT INTO tourist_spot_menu_items (
    tourist_spot_id, name, price_won, price_note, display_order, source_url, verified_on, active
)
SELECT spot.tourist_spot_id, menu.name, NULL, '매장 가격 확인', menu.display_order,
       'https://apis.data.go.kr/B551011/KorService2/detailIntro2?contentId=' || menu.content_id || '&contentTypeId=39',
       DATE '2026-09-10', TRUE
FROM (VALUES
    ('1828984', '감자옹심이', 1),
    ('2876420', '감자옹심이', 1),
    ('2876420', '옹심이메밀칼국수', 2),
    ('133817', '순감자옹심이', 1),
    ('133817', '감자옹심이칼국수', 2),
    ('133817', '감자송편', 3),
    ('2790029', '감자옹심이', 1),
    ('2790029', '감자전', 2),
    ('2779972', '옹심이', 1),
    ('2779972', '메밀국수옹심이', 2),
    ('2815461', '한입감자빵', 1),
    ('2815461', '한입고구마빵', 2)
) AS menu(content_id, name, display_order)
JOIN tourist_spots spot ON spot.content_id = menu.content_id
WHERE NOT EXISTS (
    SELECT 1 FROM tourist_spot_menu_items existing
    WHERE existing.tourist_spot_id = spot.tourist_spot_id AND existing.name = menu.name
);
