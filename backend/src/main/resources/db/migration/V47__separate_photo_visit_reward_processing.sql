ALTER TABLE user_visits
    ADD COLUMN visit_rewards_processed BOOLEAN NOT NULL DEFAULT TRUE;

-- 사진 미션이 최초 생성한 기록만 복구 대상으로 구분한다. 기존 방문/사진 기록은 보존한다.
-- 이미 해당 장소 스탬프를 지급한 방문은 다시 보상 처리하지 않는다.
UPDATE user_visits
SET visit_rewards_processed = FALSE
WHERE EXISTS (
    SELECT 1 FROM user_missions photo
    WHERE photo.user_id = user_visits.user_id
      AND photo.tourist_spot_id = user_visits.tourist_spot_id
      AND photo.completed_at = user_visits.visited_at
      AND photo.evidence_upload_key IS NOT NULL
)
AND NOT EXISTS (
    SELECT 1 FROM user_stamps stamp
    WHERE stamp.user_id = user_visits.user_id
      AND stamp.tourist_spot_id = user_visits.tourist_spot_id
);
