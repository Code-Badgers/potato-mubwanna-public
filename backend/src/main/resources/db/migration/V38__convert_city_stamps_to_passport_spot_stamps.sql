-- Preserve the original unique city column as a stable technical key, then make
-- city_name descriptive so multiple passport spots can belong to the same city.
ALTER TABLE stamps RENAME COLUMN city_name TO stamp_key;

ALTER TABLE stamps ADD COLUMN city_name VARCHAR(100);
ALTER TABLE stamps ADD COLUMN tourist_spot_id BIGINT;

-- Keep a recovery copy because this migration intentionally removes the active
-- city-stamp model and remaps user achievements to passport spots.
CREATE TABLE legacy_city_stamps_v38_archive AS
SELECT
    stamp_id,
    stamp_key AS city_name,
    stamp_name,
    stamp_image,
    display_order,
    created_at,
    updated_at
FROM stamps;

CREATE TABLE legacy_user_stamps_v38_archive AS
SELECT *
FROM user_stamps;

CREATE TEMPORARY TABLE passport_stamp_seed AS
SELECT
    spot.tourist_spot_id,
    spot.content_id,
    spot.name AS spot_name,
    spot.city_name,
    spot.image_url,
    CAST(ROW_NUMBER() OVER (
        ORDER BY city_stamp.display_order, spot.name, spot.tourist_spot_id
    ) AS INTEGER) AS display_order
FROM tourist_spots spot
JOIN stamps city_stamp
  ON city_stamp.stamp_key = spot.city_name
WHERE spot.active = TRUE
  AND spot.stamp_enabled = TRUE
  AND spot.rallybook_featured = TRUE;

-- Offset display_order while the legacy 1..18 rows still occupy the unique range.
INSERT INTO stamps (
    stamp_key,
    city_name,
    tourist_spot_id,
    stamp_name,
    stamp_image,
    display_order,
    created_at,
    updated_at
)
SELECT
    'PASSPORT_SPOT_' || content_id,
    city_name,
    tourist_spot_id,
    spot_name,
    image_url,
    display_order + 1000,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM passport_stamp_seed;

-- Existing city stamps always retain the exact tourist spot that issued them,
-- so achievements can be moved without granting unvisited passport stamps.
UPDATE user_stamps user_stamp
SET stamp_id = passport_stamp.stamp_id
FROM stamps passport_stamp
WHERE passport_stamp.tourist_spot_id = user_stamp.tourist_spot_id;

-- A legacy city stamp could be issued at a non-passport spot. Keep its visit
-- history, but remove the city achievement instead of granting an unvisited stamp.
DELETE FROM user_stamps
WHERE stamp_id IN (
    SELECT stamp_id
    FROM stamps
    WHERE tourist_spot_id IS NULL
);

DELETE FROM stamps
WHERE tourist_spot_id IS NULL;

UPDATE stamps
SET display_order = display_order - 1000;

ALTER TABLE stamps ALTER COLUMN city_name SET NOT NULL;
ALTER TABLE stamps ALTER COLUMN tourist_spot_id SET NOT NULL;
ALTER TABLE stamps ADD CONSTRAINT fk_stamps_tourist_spot
    FOREIGN KEY (tourist_spot_id) REFERENCES tourist_spots(tourist_spot_id);
ALTER TABLE stamps ADD CONSTRAINT uk_stamps_tourist_spot UNIQUE (tourist_spot_id);

CREATE INDEX idx_stamps_tourist_spot_id ON stamps(tourist_spot_id);

-- The 18-stamp coupon remains an earned milestone, but is no longer the full rally completion.
UPDATE coupons
SET name = '강원 관광지 18곳 달성 10,000원 할인권',
    description = '강원 관광지 18곳 달성 기념으로 제휴점에서 10,000원 할인받을 수 있습니다.'
WHERE code = 'CP_STAMP_18_COMPLETE_10000';

DROP TABLE passport_stamp_seed;
