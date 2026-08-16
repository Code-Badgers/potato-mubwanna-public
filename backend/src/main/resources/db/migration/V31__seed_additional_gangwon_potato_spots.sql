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
        ('CURATED:KAKAO:331311679', 39, '감자유원지', 'POTATO_CAFE', 37.7563539, 128.8973864, '강원특별자치도 강릉시 임당동 103-12', '강릉시', '감자,감자빵,디저트,강릉카페', 'NORMAL'),
        ('CURATED:KAKAO:1350494319', 39, '대관령감자빵', 'POTATO_CAFE', 37.6708122, 128.7089922, '강원특별자치도 평창군 대관령면 횡계리 343-6', '평창군', '감자,감자빵,디저트,대관령', 'LOW'),
        ('CURATED:KAKAO:1398042905', 38, '속초감자빵', 'POTATO_SNACK', 38.1886581, 128.5386406, '강원특별자치도 속초시 노학동 901-13', '속초시', '감자,감자빵,간식,기념품', 'NORMAL'),
        ('CURATED:KAKAO:487698285', 39, '속초불탄감자빵 본점', 'POTATO_SNACK', 38.2032065, 128.5248995, '강원특별자치도 속초시 노학동 1028', '속초시', '감자,감자빵,베이커리,간식', 'NORMAL'),
        ('CURATED:KAKAO:1004538025', 39, '강릉이래요', 'POTATO_CAFE', 37.7542403, 128.8986883, '강원특별자치도 강릉시 성남동 50', '강릉시', '감자,감자빵,디저트카페,중앙시장', 'NORMAL'),
        ('CURATED:KAKAO:10344302', 39, '만낭포감자떡 본점', 'POTATO_SNACK', 37.3466240, 127.8468307, '강원특별자치도 원주시 지정면 간현리 396', '원주시', '감자,감자떡,전통간식,원주', 'LOW'),
        ('CURATED:KAKAO:11542807', 39, '감자적본부', 'POTATO_RESTAURANT', 37.7620858, 128.9397658, '강원특별자치도 강릉시 병산동 361', '강릉시', '감자,감자전,감자적,향토음식', 'NORMAL'),
        ('CURATED:KAKAO:11395119', 39, '옹심이장칼국수 감자바우', 'POTATO_RESTAURANT', 37.7531069, 128.8970743, '강원특별자치도 강릉시 성남동 97-17', '강릉시', '감자,옹심이,장칼국수,감자전', 'NORMAL'),
        ('CURATED:KAKAO:2132461576', 39, '강릉대관령감자옹심이', 'POTATO_RESTAURANT', 37.7695680, 128.9094481, '강원특별자치도 강릉시 포남동 1174-12', '강릉시', '감자,감자옹심이,향토음식', 'NORMAL'),
        ('CURATED:KAKAO:8965991', 39, '동부감자옹심이', 'POTATO_RESTAURANT', 37.7600096, 128.9009055, '강원특별자치도 강릉시 옥천동 223', '강릉시', '감자,감자옹심이,강릉맛집', 'NORMAL'),
        ('CURATED:KAKAO:1988084034', 39, '신토불이감자옹심이', 'POTATO_RESTAURANT', 38.2042016, 128.5905580, '강원특별자치도 속초시 중앙동 471-4', '속초시', '감자,감자옹심이,속초맛집', 'NORMAL'),
        ('CURATED:KAKAO:990336635', 39, '공가네감자옹심이', 'POTATO_RESTAURANT', 38.1966622, 128.5803877, '강원특별자치도 속초시 교동 1019-18', '속초시', '감자,감자옹심이,향토음식', 'NORMAL'),
        ('CURATED:KAKAO:638380784', 39, '감자골 감자옹심이전문점', 'POTATO_RESTAURANT', 38.2052601, 128.5894234, '강원특별자치도 속초시 중앙동 493-5', '속초시', '감자,감자옹심이,전문점', 'NORMAL'),
        ('CURATED:KAKAO:1901004322', 39, '카페김감자', 'POTATO_CAFE', 37.5131534, 129.1234638, '강원특별자치도 동해시 용정동 519-3', '동해시', '감자,카페,동해카페', 'NORMAL'),
        ('CURATED:KAKAO:910172743', 39, '카페 감자', 'POTATO_CAFE', 37.7705878, 128.3892703, '강원특별자치도 홍천군 내면 창촌리 1612-19', '홍천군', '감자,카페,홍천카페', 'LOW'),
        ('CURATED:KAKAO:1883445066', 39, '감자창고', 'POTATO_CAFE', 37.6878605, 128.5586884, '강원특별자치도 평창군 진부면 두일리 276', '평창군', '감자,카페,창고카페,평창', 'LOW'),
        ('CURATED:KAKAO:302096086', 39, '감자아일랜드 온의점', 'POTATO_BREWERY', 37.8695342, 127.7203255, '강원특별자치도 춘천시 온의동 601', '춘천시', '감자,수제맥주,브루펍,바페어링', 'NORMAL'),
        ('CURATED:KAKAO:958078592', 38, '삶은감자', 'POTATO_SHOP', 37.7589404, 128.8917179, '강원특별자치도 강릉시 교동 893-34', '강릉시', '감자,소품샵,기념품,강릉소품', 'NORMAL')
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
