ALTER TABLE missions ADD COLUMN target_spot_id BIGINT;
ALTER TABLE missions ADD CONSTRAINT fk_missions_target_spot
    FOREIGN KEY (target_spot_id) REFERENCES tourist_spots (tourist_spot_id);

-- 이름은 기존 데이터 이관에만 사용한다. 동명이거나 미등록인 장소는 추정하지 않는다.
UPDATE missions
SET target_spot_id = (
    SELECT MIN(s.tourist_spot_id) FROM tourist_spots s
    WHERE s.name = missions.spot_name AND s.city_name = missions.city_name AND s.active = TRUE
)
WHERE mission_type IN ('PHOTO', 'PHOTO_OCR')
  AND (SELECT COUNT(*) FROM tourist_spots s
       WHERE s.name = missions.spot_name AND s.city_name = missions.city_name AND s.active = TRUE) = 1;

-- 매장을 특정할 수 없는 기존 미션은 완료/보상 기록을 보존한 채 노출을 중단한다.
UPDATE missions SET active = FALSE, updated_at = CURRENT_TIMESTAMP
WHERE mission_type IN ('PHOTO', 'PHOTO_OCR') AND target_spot_id IS NULL;

ALTER TABLE missions ADD CONSTRAINT ck_active_photo_mission_target
    CHECK (active = FALSE OR mission_type NOT IN ('PHOTO', 'PHOTO_OCR') OR target_spot_id IS NOT NULL);
CREATE INDEX idx_missions_target_spot ON missions (target_spot_id);
