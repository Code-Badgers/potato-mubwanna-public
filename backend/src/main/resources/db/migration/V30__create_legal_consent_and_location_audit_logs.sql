CREATE TABLE legal_consent_events (
    legal_consent_event_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    consent_type VARCHAR(40) NOT NULL,
    document_version VARCHAR(80) NOT NULL,
    accepted BOOLEAN NOT NULL,
    recorded_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_legal_consent_events_latest
    ON legal_consent_events(user_id, consent_type, recorded_at DESC, legal_consent_event_id DESC);

CREATE TABLE location_usage_logs (
    location_usage_log_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    used_at TIMESTAMP WITH TIME ZONE NOT NULL,
    acquisition_source VARCHAR(40) NOT NULL,
    purpose VARCHAR(60) NOT NULL,
    service_result VARCHAR(40) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_location_usage_logs_user_used_at
    ON location_usage_logs(user_id, used_at DESC);

CREATE INDEX idx_location_usage_logs_expires_at
    ON location_usage_logs(expires_at);
