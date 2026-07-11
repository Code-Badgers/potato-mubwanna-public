CREATE TABLE reward_histories (
    reward_history_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    reward_type VARCHAR(30) NOT NULL,
    reward_name VARCHAR(255) NOT NULL,
    source_type VARCHAR(30) NOT NULL,
    source_id BIGINT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT uk_reward_histories_user_source UNIQUE (user_id, source_type, source_id)
);

CREATE INDEX idx_reward_histories_user_id_created_at
    ON reward_histories(user_id, created_at);
