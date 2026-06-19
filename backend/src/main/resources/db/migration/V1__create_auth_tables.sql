CREATE TABLE users (
    user_id BIGSERIAL PRIMARY KEY,
    provider VARCHAR(30) NOT NULL,
    provider_user_id VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    nickname VARCHAR(100) NOT NULL,
    profile_image VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT uk_users_provider_user UNIQUE (provider, provider_user_id)
);

CREATE TABLE refresh_tokens (
    refresh_token_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(user_id),
    token VARCHAR(500) NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    revoked BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
