CREATE TABLE user_daily_activities (
    user_daily_activity_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    activity_date DATE NOT NULL,
    steps INTEGER NOT NULL,
    distance_meters DOUBLE PRECISION NOT NULL,
    source VARCHAR(30) NOT NULL,
    synced_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT uk_user_daily_activities_user_date_source UNIQUE (user_id, activity_date, source),
    CONSTRAINT ck_user_daily_activities_steps_non_negative CHECK (steps >= 0),
    CONSTRAINT ck_user_daily_activities_distance_non_negative CHECK (distance_meters >= 0)
);

CREATE INDEX idx_user_daily_activities_user_date
    ON user_daily_activities(user_id, activity_date);
