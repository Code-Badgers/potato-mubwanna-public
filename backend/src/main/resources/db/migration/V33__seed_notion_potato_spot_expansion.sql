-- Expand map-visible potato spots from the Notion catalog.
-- These rows prioritize restaurants, cafes/desserts, tourism/shopping, and markets with confirmed Gangwon addresses.
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
        ('CURATED:NOTION:15_DAKGALBI_CHUNCHEON', 39, '1.5닭갈비 본점', 'POTATO_RESTAURANT', 37.8763504, 127.7531355, '강원특별자치도 춘천시 후만로 77', '춘천시', '감자,닭갈비,감자사리,식당,춘천', 'NORMAL'),
        ('CURATED:NOTION:GRISIM_PYEONGCHANG', 39, '그리심', 'POTATO_CAFE', 37.5882233, 128.4164393, '강원특별자치도 평창군 용평면 경강로 1686', '평창군', '감자,감자디저트,카페디저트,평창', 'LOW'),
        ('CURATED:NOTION:NAMGYEONG_RESTAURANT', 39, '남경식당', 'POTATO_RESTAURANT', 37.6852673, 128.7412057, '강원특별자치도 평창군 대관령면 대관령마루길 347', '평창군', '감자,황태감자전,향토음식,식당', 'NORMAL'),
        ('CURATED:NOTION:NANGMAN_ISLAND', 38, '낭만섬', 'POTATO_SHOP', 37.3410660, 127.9540817, '강원특별자치도 원주시 남원로 654 2층', '원주시', '감자,로컬굿즈,기념품,관광쇼핑', 'NORMAL'),
        ('CURATED:NOTION:LATTORAEYO_SOKCHO', 39, '라또래요', 'POTATO_CAFE', 38.2140509, 128.5963211, '강원특별자치도 속초시 영랑해안2길 2', '속초시', '감자,젤라또,카페디저트,속초', 'NORMAL'),
        ('CURATED:NOTION:MOTHER_COFFEE_GANGNEUNG', 39, '마더커피', 'POTATO_CAFE', 37.7958800, 128.9176037, '강원특별자치도 강릉시 창해로350번길 21 2층', '강릉시', '감자,감자디저트,카페디저트,강릉', 'NORMAL'),
        ('CURATED:NOTION:BUNPATTYBUN_GANGNEUNG', 39, '번패티번 강릉점', 'POTATO_RESTAURANT', 37.7754435, 128.9418546, '강원특별자치도 강릉시 견소동 264', '강릉시', '감자,감자튀김,버거,식당', 'NORMAL'),
        ('CURATED:NOTION:SANE_EONDEOGE', 39, '산에언덕에', 'POTATO_RESTAURANT', 37.8398380, 128.6567445, '강원특별자치도 강릉시 연곡면 진고개로 1016', '강릉시', '감자,감자전,향토음식,식당', 'LOW'),
        ('CURATED:NOTION:SANTORINI_CHUNCHEON', 39, '산토리니', 'POTATO_CAFE', 37.8913873, 127.7764949, '강원특별자치도 춘천시 동면 순환대로 1154-97', '춘천시', '감자,브런치,카페디저트,춘천', 'NORMAL'),
        ('CURATED:NOTION:SAMCHEOK_JUNGANG_MARKET', 38, '삼척중앙시장', 'POTATO_MARKET', 37.4420997, 129.1646219, '강원특별자치도 삼척시 진주로 12-21', '삼척시', '감자,전통시장,로컬푸드,시장상권', 'NORMAL'),
        ('CURATED:NOTION:SOKCHO_JUNGANG_MARKET', 38, '속초중앙전통시장', 'POTATO_MARKET', 38.2053994, 128.5893536, '강원특별자치도 속초시 중앙시장로6길 4', '속초시', '감자,전통시장,로컬푸드,시장상권', 'NORMAL'),
        ('CURATED:NOTION:YEONGWOL_SEOBU_MARKET', 38, '영월 서부공설시장', 'POTATO_MARKET', 37.1824381, 128.4661197, '강원특별자치도 영월군 영월읍 서부시장길 8-22', '영월군', '감자,전통시장,로컬푸드,시장상권', 'NORMAL'),
        ('CURATED:NOTION:WONJU_JUNGANG_MARKET', 38, '원주 중앙시장', 'POTATO_MARKET', 37.3500134, 127.9491921, '강원특별자치도 원주시 중앙시장길 6', '원주시', '감자,전통시장,로컬푸드,시장상권', 'NORMAL'),
        ('CURATED:NOTION:JEONGSEON_ARIRANG_MARKET', 38, '정선아리랑시장', 'POTATO_MARKET', 37.3804951, 128.6659646, '강원특별자치도 정선군 정선읍 5일장길 62', '정선군', '감자,정선5일장,아리랑시장,시장상권', 'NORMAL'),
        ('CURATED:NOTION:CHODANG_COFFEE_JEONGMISO', 39, '초당커피정미소', 'POTATO_CAFE', 37.7872355, 128.9137334, '강원특별자치도 강릉시 초당원길 67', '강릉시', '감자,초당디저트,카페디저트,강릉', 'NORMAL'),
        ('CURATED:NOTION:CHUNCHEON_JUNGANG_MARKET', 38, '춘천중앙시장', 'POTATO_MARKET', 37.8782115, 127.7253179, '강원특별자치도 춘천시 중앙로 81-3', '춘천시', '감자,전통시장,로컬푸드,시장상권', 'NORMAL'),
        ('CURATED:NOTION:CHILSEONG_SHIPYARD', 39, '칠성조선소', 'POTATO_CAFE', 38.1982450, 128.5833681, '강원특별자치도 속초시 중앙로46번길 45', '속초시', '감자,로컬카페,관광카페,카페디저트', 'NORMAL'),
        ('CURATED:NOTION:CAFE_CARBIN', 39, '카페 카빈', 'POTATO_CAFE', 37.8646657, 127.6925565, '강원특별자치도 춘천시 스포츠타운길 246', '춘천시', '감자,브런치,카페디저트,춘천', 'NORMAL'),
        ('CURATED:NOTION:CAFE_SUMI', 39, '카페수미', 'POTATO_CAFE', 37.6732523, 128.7087237, '강원특별자치도 평창군 대관령면 횡계길 24', '평창군', '감자,수미감자,카페디저트,평창', 'LOW'),
        ('CURATED:NOTION:TAESEONG_SILBI', 39, '태성실비식당', 'POTATO_RESTAURANT', 37.1589336, 128.9865791, '강원특별자치도 태백시 감천로 4', '태백시', '감자,한우,감자반찬,식당', 'NORMAL'),
        ('CURATED:NOTION:TOJI_ONGSIMI_WONJU', 39, '토지옹심이 원주', 'POTATO_RESTAURANT', 37.3263707, 127.9827968, '강원특별자치도 원주시 양지뜰2길 1', '원주시', '감자,감자옹심이,식당,원주', 'NORMAL'),
        ('CURATED:NOTION:PYEONGCHANG_MUI_ART', 12, '평창무이예술관', 'POTATO_TOUR', 37.6152756, 128.3487846, '강원특별자치도 평창군 봉평면 사리평길 233', '평창군', '감자,문화관광,관광쇼핑,평창', 'LOW')
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
