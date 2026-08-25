CREATE TABLE IF NOT EXISTS tourist_spot_google_place_cache (
    tourist_spot_id BIGINT PRIMARY KEY,
    google_place_id VARCHAR(255),
    details_payload TEXT,
    matched_at TIMESTAMP,
    details_fetched_at TIMESTAMP,
    details_expires_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_google_place_details_cache_spot
        FOREIGN KEY (tourist_spot_id)
        REFERENCES tourist_spots(tourist_spot_id)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_google_place_details_cache_place_id
    ON tourist_spot_google_place_cache(google_place_id);
