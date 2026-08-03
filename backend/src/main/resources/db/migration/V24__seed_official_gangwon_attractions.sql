-- 2026-08-03 한국관광공사 국문 관광정보 서비스(KorService2) 기준.
-- 기존 수기 좌표 두 건은 공식 content ID, 좌표, 주소, 대표 이미지로 교체한다.
UPDATE tourist_spots
SET content_id = '128019',
    content_type_id = 12,
    latitude = 37.7962651,
    longitude = 127.5254892,
    address = '강원특별자치도 춘천시 남이섬길 1 남이섬',
    city_name = '춘천시',
    image_url = 'https://tong.visitkorea.or.kr/cms/resource/45/4067545_image2_1.jpg',
    source = 'TOUR_API',
    potato_tags = '관광,산책,호반,스탬프',
    stamp_enabled = TRUE,
    active = TRUE,
    updated_at = CURRENT_TIMESTAMP
WHERE content_id = 'CURATED:NAMI_ISLAND'
  AND NOT EXISTS (
      SELECT 1 FROM tourist_spots WHERE content_id = '128019'
  );

UPDATE tourist_spots
SET content_id = '132003',
    content_type_id = 38,
    latitude = 37.3805311,
    longitude = 128.6647911,
    address = '강원특별자치도 정선군 정선읍 5일장길 40',
    city_name = '정선군',
    image_url = 'https://tong.visitkorea.or.kr/cms/resource_photo/04/4073504_image2_1.jpg',
    source = 'TOUR_API',
    potato_tags = '전통시장,로컬푸드,아리랑시장,스탬프',
    stamp_enabled = TRUE,
    active = TRUE,
    updated_at = CURRENT_TIMESTAMP
WHERE content_id = 'CURATED:JEONGSEON_MARKET'
  AND NOT EXISTS (
      SELECT 1 FROM tourist_spots WHERE content_id = '132003'
  );

-- 이미 TourAPI 동기화로 같은 content ID가 존재하는 운영 DB에서는 기존 curated
-- PK를 지우지 않고 비활성화해 방문/스탬프 이력을 보존한다.
UPDATE tourist_spots
SET stamp_enabled = FALSE,
    active = FALSE,
    updated_at = CURRENT_TIMESTAMP
WHERE content_id IN ('CURATED:NAMI_ISLAND', 'CURATED:JEONGSEON_MARKET')
  AND (
      (content_id = 'CURATED:NAMI_ISLAND' AND EXISTS (
          SELECT 1 FROM tourist_spots WHERE content_id = '128019'
      ))
      OR
      (content_id = 'CURATED:JEONGSEON_MARKET' AND EXISTS (
          SELECT 1 FROM tourist_spots WHERE content_id = '132003'
      ))
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
    attraction.content_id,
    attraction.content_type_id,
    attraction.name,
    attraction.category,
    attraction.latitude,
    attraction.longitude,
    attraction.address,
    attraction.city_name,
    attraction.image_url,
    'TOUR_API',
    attraction.potato_tags,
    'NORMAL',
    100,
    TRUE,
    TRUE,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM (VALUES
    ('2396037', 12, '소양강 스카이워크', 'POTATO_TOUR', 37.8932774, 127.7236633, '강원특별자치도 춘천시 영서로 2663', '춘천시', 'https://tong.visitkorea.or.kr/cms/resource/64/4087664_image2_1.jpg', '관광,전망,호반,스탬프'),
    ('2633832', 14, '뮤지엄 산', 'POTATO_TOUR', 37.4153326, 127.8234091, '강원특별자치도 원주시 지정면 오크밸리2길 260', '원주시', 'https://tong.visitkorea.or.kr/cms/resource/08/3584408_image2_1.jpg', '관광,미술관,건축,스탬프'),
    ('127722', 12, '안목해변', 'POTATO_TOUR', 37.7722618, 128.9482754, '강원특별자치도 강릉시 창해로14번길 20-1', '강릉시', 'https://tong.visitkorea.or.kr/cms/resource/58/4075958_image2_1.jpg', '관광,해변,카페거리,스탬프'),
    ('125790', 12, '경포대', 'POTATO_TOUR', 37.7955137, 128.8964840, '강원특별자치도 강릉시 경포로 365', '강릉시', 'https://tong.visitkorea.or.kr/cms/resource/52/3501452_image2_1.jpg', '관광,누정,호수,스탬프'),
    ('129176', 12, '묵호등대', 'POTATO_TOUR', 37.5548307, 129.1184741, '강원특별자치도 동해시 해맞이길 289 (묵호진동)', '동해시', 'https://tong.visitkorea.or.kr/cms/resource/84/2741884_image2_1.jpg', '관광,등대,전망,스탬프'),
    ('1223212', 28, '논골담길', 'POTATO_TOUR', 37.5522210, 129.1183391, '강원특별자치도 동해시 일출로 97', '동해시', 'https://tong.visitkorea.or.kr/cms/resource/65/1220365_image2_1.jpg', '관광,벽화마을,산책,스탬프'),
    ('125740', 12, '황지연못', 'POTATO_TOUR', 37.1727622, 128.9910509, '강원특별자치도 태백시 황지연못길 12 (황지동)', '태백시', 'https://tong.visitkorea.or.kr/cms/resource/02/3564402_image2_1.jpg', '관광,연못,발원지,스탬프'),
    ('1260275', 38, '속초관광수산시장', 'POTATO_MARKET', 38.2039357, 128.5905230, '강원특별자치도 속초시 중앙로147번길 12', '속초시', 'https://tong.visitkorea.or.kr/cms/resource/67/4041467_image2_1.jpg', '전통시장,로컬푸드,관광,스탬프'),
    ('125779', 12, '영금정', 'POTATO_TOUR', 38.2119012, 128.6014625, '강원특별자치도 속초시 영금정로 43 (동명동)', '속초시', 'https://tong.visitkorea.or.kr/cms/resource/01/3576201_image2_1.jpg', '관광,정자,해돋이,스탬프'),
    ('126729', 12, '환선굴', 'POTATO_TOUR', 37.3263563, 129.0212227, '강원특별자치도 삼척시 신기면 환선로 800', '삼척시', 'https://tong.visitkorea.or.kr/cms/resource/51/3503951_image2_1.jpg', '관광,동굴,자연,스탬프'),
    ('125711', 12, '장호항', 'POTATO_TOUR', 37.2859000, 129.3142000, '강원특별자치도 삼척시 근덕면 장호리', '삼척시', 'https://tong.visitkorea.or.kr/cms/resource_photo/64/3478664_image2_1.jpg', '관광,항구,해변,스탬프'),
    ('125764', 12, '수타사', 'POTATO_TOUR', 37.6987236, 127.9592114, '강원특별자치도 홍천군 영귀미면 수타사로 473', '홍천군', 'https://tong.visitkorea.or.kr/cms/resource/82/3532982_image2_1.jpg', '관광,사찰,산책,스탬프'),
    ('131301', 28, '비발디파크', 'POTATO_EXPERIENCE', 37.6523905, 127.6873541, '강원특별자치도 홍천군 서면 한치골길 262', '홍천군', 'https://tong.visitkorea.or.kr/cms/resource/70/2779470_image2_1.jpg', '관광,레저,체험,스탬프'),
    ('2774026', 28, '횡성호수길', 'POTATO_TOUR', 37.5455564, 128.0670139, '강원특별자치도 횡성군 갑천면 태기로구방5길 40', '횡성군', 'https://tong.visitkorea.or.kr/cms/resource/85/3499285_image2_1.jpg', '관광,호수길,걷기,스탬프'),
    ('125785', 12, '청령포', 'POTATO_TOUR', 37.1752740, 128.4446100, '강원특별자치도 영월군 남면 광천리', '영월군', 'https://tong.visitkorea.or.kr/cms/resource/65/4041365_image2_1.jpg', '관광,역사,산책,스탬프'),
    ('125794', 12, '장릉', 'POTATO_TOUR', 37.1950936, 128.4549970, '강원특별자치도 영월군 영월읍 단종로 190', '영월군', 'https://tong.visitkorea.or.kr/cms/resource/15/4041415_image2_1.png', '관광,세계유산,역사,스탬프'),
    ('129263', 12, '대관령 양떼목장', 'POTATO_TOUR', 37.6875878, 128.7533012, '강원특별자치도 평창군 대관령면 대관령마루길 483-32', '평창군', 'https://tong.visitkorea.or.kr/cms/resource/99/3486899_image2_1.jpg', '관광,목장,체험,스탬프'),
    ('130415', 14, '이효석문학관', 'POTATO_TOUR', 37.6131733, 128.3699845, '강원특별자치도 평창군 봉평면 효석문학길 73-25', '평창군', 'https://tong.visitkorea.or.kr/cms/resource/70/3318470_image2_1.jpg', '관광,문학관,문화,스탬프'),
    ('2615225', 12, '고석정', 'POTATO_TOUR', 38.1860265, 127.2869221, '강원특별자치도 철원군 동송읍 태봉로 1825', '철원군', 'https://tong.visitkorea.or.kr/cms/resource/67/3351667_image2_1.jpg', '관광,지질공원,한탄강,스탬프'),
    ('507599', 15, '산천어축제장', 'POTATO_TOUR', 38.1126243, 127.7098812, '강원특별자치도 화천군 화천읍 산천어길 137', '화천군', 'https://tong.visitkorea.or.kr/cms/resource/46/4071246_image2_1.jpg', '관광,축제,겨울,스탬프'),
    ('130493', 14, '박수근미술관', 'POTATO_TOUR', 38.0962972, 127.9815974, '강원특별자치도 양구군 양구읍 박수근로 265-15', '양구군', 'https://tong.visitkorea.or.kr/cms/resource/78/3533378_image2_1.jpg', '관광,미술관,문화,스탬프'),
    ('126603', 12, '두타연', 'POTATO_TOUR', 38.2467825, 127.9816922, '강원특별자치도 양구군 방산면 두타연로 297', '양구군', 'https://tong.visitkorea.or.kr/cms/resource/00/4081700_image2_1.jpg', '관광,지질공원,계곡,스탬프'),
    ('1818945', 12, '원대리 자작나무숲', 'POTATO_TOUR', 38.0092101, 128.1942815, '강원특별자치도 인제군 인제읍 자작나무숲길 760', '인제군', 'https://tong.visitkorea.or.kr/cms/resource/33/3558333_image2_1.jpg', '관광,자작나무숲,걷기,스탬프'),
    ('128171', 12, '통일전망대', 'POTATO_TOUR', 38.5147706, 128.4173975, '강원특별자치도 고성군 현내면 금강산로 481', '고성군', 'https://tong.visitkorea.or.kr/cms/resource/54/2599054_image2_1.jpg', '관광,전망대,DMZ,스탬프'),
    ('125706', 12, '화진포', 'POTATO_TOUR', 38.4787852, 128.4390957, '강원특별자치도 고성군 거진읍 현내면', '고성군', 'https://tong.visitkorea.or.kr/cms/resource/80/4059880_image2_1.jpg', '관광,호수,지질공원,스탬프'),
    ('2501905', 28, '서피비치', 'POTATO_EXPERIENCE', 38.0280443, 128.7173077, '강원특별자치도 양양군 현북면 하조대해안길 119', '양양군', 'https://tong.visitkorea.or.kr/cms/resource/90/2745190_image2_1.jpg', '관광,서핑,체험,스탬프'),
    ('125773', 12, '낙산사', 'POTATO_TOUR', 38.1247989, 128.6273275, '강원특별자치도 양양군 강현면 낙산사로 100', '양양군', 'https://tong.visitkorea.or.kr/cms/resource/41/4064941_image2_1.jpg', '관광,사찰,해안,스탬프')
) AS attraction(
    content_id,
    content_type_id,
    name,
    category,
    latitude,
    longitude,
    address,
    city_name,
    image_url,
    potato_tags
)
WHERE NOT EXISTS (
    SELECT 1
    FROM tourist_spots existing
    WHERE existing.content_id = attraction.content_id
       OR (existing.name = attraction.name AND existing.address = attraction.address)
);
