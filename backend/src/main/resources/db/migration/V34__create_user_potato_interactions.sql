CREATE TABLE user_potato_interactions (
    user_potato_interaction_id BIGSERIAL PRIMARY KEY,
    user_potato_id BIGINT NOT NULL REFERENCES user_potatoes(user_potato_id) ON DELETE CASCADE,
    action VARCHAR(30) NOT NULL,
    growth_distance_added DOUBLE PRECISION NOT NULL,
    interacted_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_user_potato_interactions_lookup
    ON user_potato_interactions(user_potato_id, action, interacted_at DESC);
