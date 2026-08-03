CREATE TABLE tourist_spot_menu_items (
    tourist_spot_menu_item_id BIGSERIAL PRIMARY KEY,
    tourist_spot_id BIGINT NOT NULL REFERENCES tourist_spots(tourist_spot_id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    price_won INTEGER,
    price_note VARCHAR(50),
    display_order INTEGER NOT NULL,
    source_url VARCHAR(500) NOT NULL,
    verified_on DATE NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uk_tourist_spot_menu_item UNIQUE (tourist_spot_id, name),
    CONSTRAINT ck_tourist_spot_menu_price_non_negative CHECK (price_won IS NULL OR price_won >= 0),
    CONSTRAINT ck_tourist_spot_menu_price_value CHECK (
        (price_won IS NOT NULL AND price_note IS NULL)
        OR (price_won IS NULL AND price_note IS NOT NULL)
    )
);

CREATE INDEX idx_tourist_spot_menu_items_lookup
    ON tourist_spot_menu_items(tourist_spot_id, active, display_order);

INSERT INTO tourist_spot_menu_items (
    tourist_spot_id, name, price_won, price_note, display_order, source_url, verified_on, active
)
SELECT spot.tourist_spot_id, menu.name, menu.price_won, NULL, menu.display_order,
       'https://place.map.kakao.com/169361798', DATE '2026-08-03', TRUE
FROM tourist_spots spot
CROSS JOIN (VALUES
    ('감자빵', 3300, 1),
    ('감자빵 BOX(10ea)', 29700, 2),
    ('아메리카노', 4800, 3)
) AS menu(name, price_won, display_order)
WHERE spot.content_id = 'CURATED:GAMZABATT';

INSERT INTO tourist_spot_menu_items (
    tourist_spot_id, name, price_won, price_note, display_order, source_url, verified_on, active
)
SELECT spot.tourist_spot_id, menu.name, menu.price_won, NULL, menu.display_order,
       'https://place.map.kakao.com/308572457', DATE '2026-08-03', TRUE
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
       'https://place.map.kakao.com/1545071550', DATE '2026-08-03', TRUE
FROM tourist_spots spot
CROSS JOIN (VALUES
    ('컵~길감자', 3100, 1),
    ('소세지 길감자', 4200, 2)
) AS menu(name, price_won, display_order)
WHERE spot.content_id = 'CURATED:GANGNEUNG_GILGAMJA';

INSERT INTO tourist_spot_menu_items (
    tourist_spot_id, name, price_won, price_note, display_order, source_url, verified_on, active
)
SELECT spot.tourist_spot_id, menu.name, menu.price_won, NULL, menu.display_order,
       'https://place.map.kakao.com/2100584967', DATE '2026-08-03', TRUE
FROM tourist_spots spot
CROSS JOIN (VALUES
    ('감자둥둥섬', 18800, 1),
    ('감자 맥주', 6000, 2),
    ('감자 선장의 해물 보따리', 36800, 3)
) AS menu(name, price_won, display_order)
WHERE spot.content_id = 'CURATED:GAMJA_ISLAND_CHUNCHEON';
