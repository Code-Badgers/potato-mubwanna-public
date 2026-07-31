ALTER TABLE missions
    ADD COLUMN starts_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE missions
    ADD COLUMN ends_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE missions
    ADD CONSTRAINT ck_missions_event_period CHECK (
        (
            mission_group <> 'EVENT'
            AND starts_at IS NULL
            AND ends_at IS NULL
        )
        OR (
            mission_group = 'EVENT'
            AND (
                (starts_at IS NULL AND ends_at IS NULL)
                OR (starts_at IS NOT NULL AND ends_at IS NOT NULL AND starts_at < ends_at)
            )
        )
    );

ALTER TABLE user_missions
    ADD COLUMN completion_period VARCHAR(40) NOT NULL DEFAULT 'ONCE';

ALTER TABLE user_missions
    DROP CONSTRAINT uk_user_missions_user_mission;

ALTER TABLE user_missions
    ADD CONSTRAINT uk_user_missions_user_mission
    UNIQUE (user_id, mission_id, completion_period);

ALTER TABLE reward_histories
    ADD COLUMN source_period VARCHAR(40) NOT NULL DEFAULT 'ONCE';

ALTER TABLE reward_histories
    DROP CONSTRAINT uk_reward_histories_user_source;

ALTER TABLE reward_histories
    ADD CONSTRAINT uk_reward_histories_user_source
    UNIQUE (user_id, source_type, source_id, source_period);
