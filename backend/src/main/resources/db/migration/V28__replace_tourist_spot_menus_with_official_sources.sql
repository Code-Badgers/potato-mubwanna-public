-- V26 is already deployed, so replace only its four curated menu sets in a new migration.
DELETE FROM tourist_spot_menu_items
WHERE tourist_spot_id IN (
    SELECT tourist_spot_id
    FROM tourist_spots
    WHERE content_id IN (
        'CURATED:GAMZABATT',
        'CURATED:GANGNEUNG_GAMJAGEOK_1BEONJI',
        'CURATED:GANGNEUNG_GILGAMJA',
        'CURATED:GAMJA_ISLAND_CHUNCHEON'
    )
);

INSERT INTO tourist_spot_menu_items (
    tourist_spot_id, name, price_won, price_note, display_order, source_url, verified_on, active
)
SELECT spot.tourist_spot_id, menu.name, menu.price_won, NULL, menu.display_order,
       'https://gamzabatt.com/all/?idx=1', DATE '2026-08-04', TRUE
FROM tourist_spots spot
CROSS JOIN (VALUES
    ('원조 감자빵 10개입 (공식몰)', 33000, 1)
) AS menu(name, price_won, display_order)
WHERE spot.content_id = 'CURATED:GAMZABATT';

INSERT INTO tourist_spot_menu_items (
    tourist_spot_id, name, price_won, price_note, display_order, source_url, verified_on, active
)
SELECT spot.tourist_spot_id, menu.name, menu.price_won, NULL, menu.display_order,
       'https://app.catchtable.co.kr/ct/shop/gamjageok1', DATE '2026-08-04', TRUE
FROM tourist_spots spot
CROSS JOIN (VALUES
    ('감자적', 6000, 1),
    ('도토리들깨수제비', 12000, 2),
    ('장칼국수', 8000, 3)
) AS menu(name, price_won, display_order)
WHERE spot.content_id = 'CURATED:GANGNEUNG_GAMJAGEOK_1BEONJI';

INSERT INTO tourist_spot_menu_items (
    tourist_spot_id, name, price_won, price_note, display_order, source_url, verified_on, active
)
SELECT spot.tourist_spot_id, menu.name, menu.price_won, NULL, menu.display_order,
       'https://www.instagram.com/gil_potato/reel/DQJBIyqkYU8/', DATE '2026-08-04', TRUE
FROM tourist_spots spot
CROSS JOIN (VALUES
    ('컵길감자', 3100, 1),
    ('소시지 길감자', 4200, 2)
) AS menu(name, price_won, display_order)
WHERE spot.content_id = 'CURATED:GANGNEUNG_GILGAMJA';

INSERT INTO tourist_spot_menu_items (
    tourist_spot_id, name, price_won, price_note, display_order, source_url, verified_on, active
)
SELECT spot.tourist_spot_id, menu.name, NULL, '매장 가격 확인', menu.display_order,
       'https://pf.kakao.com/_xbxfxgAs', DATE '2026-08-04', TRUE
FROM tourist_spots spot
CROSS JOIN (VALUES
    ('감자둥둥섬', 1),
    ('바삭 감자치킨', 2),
    ('수제맥주', 3)
) AS menu(name, display_order)
WHERE spot.content_id = 'CURATED:GAMJA_ISLAND_CHUNCHEON';
