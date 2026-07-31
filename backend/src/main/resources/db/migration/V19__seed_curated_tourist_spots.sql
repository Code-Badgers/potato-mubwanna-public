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
    'CURATED:JEONGSEON_MARKET',
    38,
    '정선 5일장',
    'POTATO_MARKET',
    37.3804724,
    128.6646448,
    '강원특별자치도 정선군 정선읍 5일장길 36',
    '정선군',
    NULL,
    'CURATED',
    '감자,전통시장,로컬푸드',
    'NORMAL',
    100,
    TRUE,
    TRUE,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
WHERE NOT EXISTS (
    SELECT 1
    FROM tourist_spots
    WHERE content_id = 'CURATED:JEONGSEON_MARKET'
       OR (name = '정선 5일장' AND address = '강원특별자치도 정선군 정선읍 5일장길 36')
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
    'CURATED:NAMI_ISLAND',
    12,
    '남이섬',
    'POTATO_TOUR',
    37.7917285,
    127.5251440,
    '강원특별자치도 춘천시 남산면 남이섬길 1',
    '춘천시',
    NULL,
    'CURATED',
    '관광,산책,호반',
    'NORMAL',
    100,
    TRUE,
    TRUE,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
WHERE NOT EXISTS (
    SELECT 1
    FROM tourist_spots
    WHERE content_id = 'CURATED:NAMI_ISLAND'
       OR (name = '남이섬' AND address = '강원특별자치도 춘천시 남산면 남이섬길 1')
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
    'CURATED:GAMZABATT',
    39,
    '감자밭',
    'POTATO_CAFE',
    37.9256574,
    127.7500695,
    '강원특별자치도 춘천시 신북읍 신샘밭로 674',
    '춘천시',
    NULL,
    'CURATED',
    '감자,감자빵,카페',
    'NORMAL',
    100,
    TRUE,
    TRUE,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
WHERE NOT EXISTS (
    SELECT 1
    FROM tourist_spots
    WHERE content_id = 'CURATED:GAMZABATT'
       OR (name = '감자밭' AND address = '강원특별자치도 춘천시 신북읍 신샘밭로 674')
);
