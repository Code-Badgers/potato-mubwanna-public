CREATE TABLE mission_verification_policies (
    mission_verification_policy_id BIGSERIAL PRIMARY KEY,
    mission_id BIGINT NOT NULL REFERENCES missions(mission_id) ON DELETE CASCADE,
    verification_type VARCHAR(30) NOT NULL,
    expected_answer VARCHAR(160),
    expected_qr_code VARCHAR(160),
    required_upload BOOLEAN NOT NULL DEFAULT FALSE,
    min_step_count INTEGER,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT uk_mission_verification_policies_mission UNIQUE (mission_id)
);

CREATE INDEX idx_mission_verification_policies_mission_id
    ON mission_verification_policies(mission_id);

INSERT INTO mission_verification_policies (
    mission_id,
    verification_type,
    expected_answer,
    expected_qr_code,
    required_upload,
    min_step_count,
    created_at,
    updated_at
)
SELECT
    mission_id,
    mission_type,
    CASE code
        WHEN 'MISSION_JEONGSEON_MARKET_QUIZ' THEN '곤드레감자'
        WHEN 'MISSION_SAMCHEOK_HWANSEONGUL_QUIZ' THEN '감자'
        WHEN 'MISSION_YANGYANG_SURFYBEACH_QUIZ' THEN '감자'
        ELSE NULL
    END,
    CASE
        WHEN mission_type = 'QR_SCAN' THEN 'mock-qr'
        ELSE NULL
    END,
    mission_type IN ('PHOTO', 'PHOTO_OCR'),
    CASE
        WHEN mission_type = 'VISIT_AND_STEP' THEN target
        ELSE NULL
    END,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM missions
WHERE mission_type IN ('QUIZ', 'VISIT_AND_STEP', 'PHOTO', 'PHOTO_OCR', 'QR_SCAN');
