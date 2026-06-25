CREATE TABLE favorite_spots (
    favorite_spot_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    tourist_spot_id BIGINT NOT NULL REFERENCES tourist_spots(tourist_spot_id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT uk_favorite_spots_user_spot UNIQUE (user_id, tourist_spot_id)
);

CREATE INDEX idx_favorite_spots_user_id ON favorite_spots(user_id);
CREATE INDEX idx_favorite_spots_tourist_spot_id ON favorite_spots(tourist_spot_id);
