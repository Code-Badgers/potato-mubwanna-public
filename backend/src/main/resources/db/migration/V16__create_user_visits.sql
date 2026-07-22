CREATE TABLE user_visits (
    user_visit_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    tourist_spot_id BIGINT NOT NULL,
    distance_meters NUMERIC(10, 2) NOT NULL,
    visited_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT fk_user_visits_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id),
    CONSTRAINT fk_user_visits_tourist_spot
        FOREIGN KEY (tourist_spot_id)
        REFERENCES tourist_spots(tourist_spot_id),
    CONSTRAINT uk_user_visits_user_spot
        UNIQUE (user_id, tourist_spot_id),
    CONSTRAINT chk_user_visits_distance_meters
        CHECK (distance_meters >= 0)
);

CREATE INDEX idx_user_visits_user_visited_at
    ON user_visits(user_id, visited_at DESC);

CREATE INDEX idx_user_visits_tourist_spot_id
    ON user_visits(tourist_spot_id);
