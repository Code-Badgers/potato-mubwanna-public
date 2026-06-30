CREATE TABLE stamps (
    stamp_id BIGSERIAL PRIMARY KEY,
    city_name VARCHAR(100) NOT NULL UNIQUE,
    stamp_name VARCHAR(100) NOT NULL,
    stamp_image VARCHAR(500),
    display_order INTEGER NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE user_stamps (
    user_stamp_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    stamp_id BIGINT NOT NULL REFERENCES stamps(stamp_id),
    tourist_spot_id BIGINT NOT NULL REFERENCES tourist_spots(tourist_spot_id),
    acquired_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT uk_user_stamps_user_stamp UNIQUE (user_id, stamp_id)
);

CREATE INDEX idx_user_stamps_user_id ON user_stamps(user_id);
CREATE INDEX idx_user_stamps_stamp_id ON user_stamps(stamp_id);
CREATE INDEX idx_user_stamps_tourist_spot_id ON user_stamps(tourist_spot_id);

INSERT INTO stamps (city_name, stamp_name, stamp_image, display_order, created_at, updated_at) VALUES
    ('강릉시', '하지감자', NULL, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('정선군', '곤드레감자', NULL, 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('평창군', '눈꽃감자', NULL, 3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('춘천시', '호반감자', NULL, 4, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('속초시', '바다감자', NULL, 5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('홍천군', '찰감자', NULL, 6, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('횡성군', '한우감자', NULL, 7, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('영월군', '별빛감자', NULL, 8, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('원주시', '원주감자', NULL, 9, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('동해시', '동해감자', NULL, 10, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('태백시', '태백감자', NULL, 11, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('삼척시', '삼척감자', NULL, 12, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('양양군', '양양감자', NULL, 13, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('고성군', '고성감자', NULL, 14, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('인제군', '인제감자', NULL, 15, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('양구군', '양구감자', NULL, 16, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('화천군', '화천감자', NULL, 17, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('철원군', '철원감자', NULL, 18, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
