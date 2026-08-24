ALTER TABLE potatoes
    ADD COLUMN IF NOT EXISTS acquisition_type VARCHAR(30) NOT NULL DEFAULT 'GROWTH';

UPDATE potatoes
SET acquisition_type = CASE
    WHEN acquisition_hint LIKE '%스탬프%' THEN 'STAMP'
    WHEN acquisition_hint LIKE '%방문 인증%' THEN 'VISIT'
    WHEN acquisition_hint LIKE '%방문 미션%' THEN 'MISSION'
    WHEN acquisition_hint LIKE '%미션%' THEN 'MISSION'
    WHEN acquisition_hint LIKE '%이벤트%' THEN 'EVENT'
    ELSE 'GROWTH'
END
WHERE acquisition_type = 'GROWTH';

ALTER TABLE user_potatoes
    ADD COLUMN IF NOT EXISTS acquisition_type VARCHAR(30) NOT NULL DEFAULT 'GROWTH';

UPDATE user_potatoes
SET acquisition_type = 'GROWTH'
WHERE acquisition_type IS NULL;
