ALTER TABLE user_missions
    ADD COLUMN evidence_upload_key VARCHAR(500);

ALTER TABLE user_missions
    ADD COLUMN tourist_spot_id BIGINT;

ALTER TABLE user_missions
    ADD CONSTRAINT fk_user_missions_tourist_spot
        FOREIGN KEY (tourist_spot_id)
        REFERENCES tourist_spots(tourist_spot_id)
        ON DELETE SET NULL;

ALTER TABLE user_missions
    ADD CONSTRAINT ck_user_missions_evidence_spot
        CHECK (tourist_spot_id IS NULL OR evidence_upload_key IS NOT NULL);

CREATE INDEX idx_user_missions_travel_evidence
    ON user_missions(user_id, tourist_spot_id, completed_at);
