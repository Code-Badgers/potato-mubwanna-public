CREATE TABLE audio_guides (
    audio_guide_id BIGSERIAL PRIMARY KEY,
    tourist_spot_id BIGINT NOT NULL REFERENCES tourist_spots(tourist_spot_id) ON DELETE CASCADE,
    external_story_id VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    audio_url VARCHAR(1000) NOT NULL,
    script TEXT,
    character_script TEXT,
    language VARCHAR(20) NOT NULL DEFAULT 'ko',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT uk_audio_guides_spot_language UNIQUE (tourist_spot_id, language)
);

CREATE INDEX idx_audio_guides_tourist_spot_id ON audio_guides(tourist_spot_id);
