CREATE TABLE user_push_tokens (
    user_push_token_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    token VARCHAR(512) NOT NULL,
    platform VARCHAR(20) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT uk_user_push_tokens_token UNIQUE (token),
    CONSTRAINT ck_user_push_tokens_platform CHECK (
        platform IN ('ANDROID', 'IOS', 'WEB')
    )
);

CREATE INDEX idx_user_push_tokens_user_id
    ON user_push_tokens(user_id);

CREATE INDEX idx_user_push_tokens_updated_at
    ON user_push_tokens(updated_at);
