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
    updated_at
)
SELECT
    'CURATED:GANGNEUNG_GAMJAGEOK_1BEONJI',
    39,
    '감자적1번지',
    'POTATO_RESTAURANT',
    37.7539000,
    128.9418000,
    '강원특별자치도 강릉시 공항길29번길 7',
    '강릉시',
    NULL,
    'CURATED',
    '감자,감자전,감자옹심이,로컬맛집',
    'NORMAL',
    100,
    TRUE,
    TRUE,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
WHERE NOT EXISTS (
    SELECT 1
    FROM tourist_spots
    WHERE content_id = 'CURATED:GANGNEUNG_GAMJAGEOK_1BEONJI'
       OR (name = '감자적1번지' AND address = '강원특별자치도 강릉시 공항길29번길 7')
);

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
    updated_at
)
SELECT
    'CURATED:GANGNEUNG_GILGAMJA',
    39,
    '강릉 길감자',
    'POTATO_SNACK',
    37.7548000,
    128.8972000,
    '강원특별자치도 강릉시 금성로 16 해인빌딩 103호',
    '강릉시',
    NULL,
    'CURATED',
    '감자,길거리간식,핫도그,중앙시장',
    'NORMAL',
    100,
    TRUE,
    TRUE,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
WHERE NOT EXISTS (
    SELECT 1
    FROM tourist_spots
    WHERE content_id = 'CURATED:GANGNEUNG_GILGAMJA'
       OR (name = '강릉 길감자' AND address = '강원특별자치도 강릉시 금성로 16 해인빌딩 103호')
);

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
    updated_at
)
SELECT
    'CURATED:BAHWE_VILLAGE',
    12,
    '바회마을',
    'POTATO_EXPERIENCE',
    37.8583000,
    128.0067000,
    '강원특별자치도 홍천군 두촌면 광석로 922-8',
    '홍천군',
    NULL,
    'CURATED',
    '감자,고랭지감자,수확체험,농촌체험',
    'LOW',
    100,
    TRUE,
    TRUE,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
WHERE NOT EXISTS (
    SELECT 1
    FROM tourist_spots
    WHERE content_id = 'CURATED:BAHWE_VILLAGE'
       OR (name = '바회마을' AND address = '강원특별자치도 홍천군 두촌면 광석로 922-8')
);

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
    updated_at
)
SELECT
    'CURATED:GAMJA_ISLAND_CHUNCHEON',
    39,
    '감자아일랜드 춘천',
    'POTATO_BREWERY',
    37.8655000,
    127.7236000,
    '강원특별자치도 춘천시 퇴계로 18',
    '춘천시',
    NULL,
    'CURATED',
    '감자,감자맥주,브루펍,바페어링',
    'NORMAL',
    100,
    TRUE,
    TRUE,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
WHERE NOT EXISTS (
    SELECT 1
    FROM tourist_spots
    WHERE content_id = 'CURATED:GAMJA_ISLAND_CHUNCHEON'
       OR (name = '감자아일랜드 춘천' AND address = '강원특별자치도 춘천시 퇴계로 18')
);

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
    updated_at
)
SELECT
    'CURATED:DAEGWALLYEONG_BAU_FARMERS',
    38,
    '대관령원예농협 바우파머스',
    'POTATO_SHOP',
    37.6707000,
    128.7069000,
    '강원특별자치도 평창군 대관령면 대관령로 94',
    '평창군',
    NULL,
    'CURATED',
    '감자,로컬푸드,직매장,농산물',
    'LOW',
    100,
    TRUE,
    TRUE,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
WHERE NOT EXISTS (
    SELECT 1
    FROM tourist_spots
    WHERE content_id = 'CURATED:DAEGWALLYEONG_BAU_FARMERS'
       OR (name = '대관령원예농협 바우파머스' AND address = '강원특별자치도 평창군 대관령면 대관령로 94')
);
