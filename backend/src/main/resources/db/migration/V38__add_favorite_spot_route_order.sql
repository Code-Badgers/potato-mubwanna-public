ALTER TABLE favorite_spots
    ADD COLUMN route_order INTEGER;

UPDATE favorite_spots
SET route_order = 1
WHERE route_order IS NULL;

ALTER TABLE favorite_spots
    ALTER COLUMN route_order SET NOT NULL;

CREATE INDEX idx_favorite_spots_user_route_order
    ON favorite_spots(user_id, route_order);
