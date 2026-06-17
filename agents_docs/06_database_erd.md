# 06_database_erd.md

# Database ERD

아래 SQL은 ERDCloud 시각화를 위해 붙여넣기 쉬운 MySQL DDL 형식으로 작성한 참고용이다.
실제 구현과 Flyway migration은 PostgreSQL + PostGIS 기준으로 작성한다.
좌표 기반 검색은 운영 스키마에서 PostGIS 컬럼과 공간 인덱스로 확장한다.

```sql
CREATE TABLE `user_coupons` (
    `user_coupon_id`    BIGINT    NOT NULL,
    `user_id`    BIGINT    NOT NULL,
    `coupon_id`    BIGINT    NOT NULL,
    `qr_code`    VARCHAR(500)    NULL,
    `used`    BOOLEAN    NOT NULL    DEFAULT FALSE,
    `issued_at`    DATETIME    NOT NULL    DEFAULT CURRENT_TIMESTAMP,
    `used_at`    DATETIME    NULL
);

CREATE TABLE `audio_guides` (
    `audio_guides_id`    BIGINT    NOT NULL,
    `tourist_spot_id`    BIGINT    NOT NULL,
    `title`    VARCHAR(255)    NOT NULL,
    `audio_url`    VARCHAR(500)    NULL,
    `script`    TEXT    NULL,
    `character_script`    TEXT    NULL,
    `language`    VARCHAR(20)    NOT NULL    DEFAULT 'ko',
    `created_at`    DATETIME    NOT NULL    DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    DATETIME    NOT NULL    DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE `user_potatoes` (
    `user_potatoes_id`    BIGINT    NOT NULL,
    `user_id`    BIGINT    NOT NULL,
    `potato_id`    BIGINT    NOT NULL,
    `level`    INT    NOT NULL    DEFAULT 1,
    `distance`    DECIMAL(10, 2)    NOT NULL    DEFAULT 0.00    COMMENT '누적 이동 거리, meter',
    `acquired_at`    DATETIME    NOT NULL    DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    DATETIME    NOT NULL    DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE `potatoes` (
    `potato_id`    BIGINT    NOT NULL,
    `name`    VARCHAR(100)    NOT NULL,
    `rarity`    VARCHAR(30)    NOT NULL    COMMENT 'NORMAL, RARE, GOLD, LEGEND',
    `region`    VARCHAR(100)    NOT NULL,
    `description`    TEXT    NULL,
    `image_url`    VARCHAR(500)    NULL,
    `base_probability`    DECIMAL(5, 2)    NULL    DEFAULT 0.00,
    `created_at`    DATETIME    NOT NULL    DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    DATETIME    NOT NULL    DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE `users` (
    `user_id`    BIGINT    NOT NULL,
    `nickname`    VARCHAR(100)    NOT NULL,
    `kakao_id`    VARCHAR(100)    NOT NULL    COMMENT '카카오 인증 서버에서 발급한 고유 회원 번호',
    `profile_image`    VARCHAR(500)    NULL,
    `created_at`    TIMESTAMP    NOT NULL    DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE `reward_histories` (
    `reward_history_id`    BIGINT    NOT NULL,
    `reward_type`    VARCHAR(30)    NOT NULL    COMMENT 'STAMP, POTATO, COUPON, ITEM',
    `reward_name`    VARCHAR(255)    NOT NULL,
    `source_type`    VARCHAR(30)    NULL    COMMENT 'STAMP, MISSION, EVENT',
    `source_id`    BIGINT    NULL,
    `created_at`    DATETIME    NOT NULL    DEFAULT CURRENT_TIMESTAMP,
    `user_id`    BIGINT    NOT NULL
);

CREATE TABLE `tourist_spots` (
    `tourist_spot_id`    BIGINT    NOT NULL,
    `content_id`    VARCHAR(100)    NULL    COMMENT '한국관광공사 contentId',
    `name`    VARCHAR(255)    NOT NULL,
    `category`    VARCHAR(50)    NOT NULL    COMMENT '장소_카테고리 (관광지/음식점/체험 등)',
    `latitude`    DECIMAL(10, 7)    NOT NULL,
    `longitude`    DECIMAL(10, 7)    NOT NULL,
    `address`    VARCHAR(500)    NULL,
    `description`    TEXT    NULL,
    `image_url`    VARCHAR(500)    NULL,
    `city_name`    VARCHAR(100)    NOT NULL    COMMENT '강릉시, 평창군 등',
    `congestion_level`    VARCHAR(30)    NULL    DEFAULT 'NORMAL'    COMMENT '실시간_혼잡도_단계 (LOW, NORMAL, HIGH)',
    `stamp_enabled`    BOOLEAN    NOT NULL    DEFAULT TRUE,
    `verification_radius_meter`    INT    NOT NULL    DEFAULT 100    COMMENT 'GPS_인증_가능_반경',
    `created_at`    DATETIME    NOT NULL    DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    DATETIME    NOT NULL    DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE `user_missions` (
    `user_mission_id`    BIGINT    NOT NULL,
    `mission_id`    BIGINT    NOT NULL,
    `status`    VARCHAR(30)    NOT NULL    DEFAULT 'IN_PROGRESS'    COMMENT 'IN_PROGRESS, COMPLETED, FAILED',
    `completed_at`    DATETIME    NULL,
    `created_at`    DATETIME    NOT NULL    DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    DATETIME    NOT NULL    DEFAULT CURRENT_TIMESTAMP,
    `user_id`    BIGINT    NOT NULL
);

CREATE TABLE `coupons` (
    `coupon_id`    BIGINT    NOT NULL,
    `title`    VARCHAR(255)    NOT NULL,
    `description`    TEXT    NULL,
    `benefit`    VARCHAR(255)    NULL,
    `partner_name`    VARCHAR(255)    NULL,
    `total_quantity`    INT    NULL,
    `issued_quantity`    INT    NOT NULL    DEFAULT 0,
    `expired_at`    DATETIME    NOT NULL,
    `active`    BOOLEAN    NOT NULL    DEFAULT TRUE,
    `created_at`    DATETIME    NOT NULL    DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    DATETIME    NOT NULL    DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE `visit_logs` (
    `visit_logs_id`    BIGINT    NOT NULL,
    `user_id`    BIGINT    NOT NULL,
    `tourist_spot_id`    BIGINT    NOT NULL,
    `latitude`    DECIMAL(10, 7)    NOT NULL,
    `longitude`    DECIMAL(10, 7)    NOT NULL,
    `distance_meter`    DECIMAL(10, 2)    NULL,
    `verification_result`    VARCHAR(30)    NOT NULL    COMMENT 'SUCCESS, FAILED',
    `visited_at`    DATETIME    NOT NULL    DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE `user_stamps` (
    `user_stamp_id`    BIGINT    NOT NULL,
    `user_id`    BIGINT    NOT NULL,
    `stamp_id`    BIGINT    NOT NULL,
    `tourist_spot_id`    BIGINT    NOT NULL,
    `acquired_at`    DATETIME    NOT NULL    DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE `missions` (
    `mission_id`    BIGINT    NOT NULL,
    `tourist_spot_id`    BIGINT    NOT NULL,
    `title`    VARCHAR(255)    NOT NULL,
    `description`    TEXT    NOT NULL,
    `mission_type`    VARCHAR(30)    NOT NULL    COMMENT 'VISIT, QR, QUIZ, PHOTO',
    `dialogue`    TEXT    NULL,
    `reward_type`    VARCHAR(30)    NOT NULL    COMMENT 'POTATO, COUPON, ITEM, STAMP',
    `reward_value`    VARCHAR(255)    NULL,
    `active`    BOOLEAN    NOT NULL    DEFAULT TRUE,
    `start_at`    DATETIME    NULL,
    `end_at`    DATETIME    NULL,
    `created_at`    DATETIME    NOT NULL    DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    DATETIME    NOT NULL    DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE `stamps` (
    `stamp_id`    BIGINT    NOT NULL,
    `city_name`    VARCHAR(100)    NOT NULL,
    `stamp_name`    VARCHAR(100)    NOT NULL,
    `stamp_image`    VARCHAR(500)    NULL,
    `description`    VARCHAR(500)    NULL,
    `created_at`    DATETIME    NOT NULL    DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    DATETIME    NOT NULL    DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE `user_coupons` ADD CONSTRAINT `PK_USER_COUPONS` PRIMARY KEY (
    `user_coupon_id`
);

ALTER TABLE `audio_guides` ADD CONSTRAINT `PK_AUDIO_GUIDES` PRIMARY KEY (
    `audio_guides_id`
);

ALTER TABLE `user_potatoes` ADD CONSTRAINT `PK_USER_POTATOES` PRIMARY KEY (
    `user_potatoes_id`
);

ALTER TABLE `potatoes` ADD CONSTRAINT `PK_POTATOES` PRIMARY KEY (
    `potato_id`
);

ALTER TABLE `users` ADD CONSTRAINT `PK_USERS` PRIMARY KEY (
    `user_id`
);

ALTER TABLE `reward_histories` ADD CONSTRAINT `PK_REWARD_HISTORIES` PRIMARY KEY (
    `reward_history_id`
);

ALTER TABLE `tourist_spots` ADD CONSTRAINT `PK_TOURIST_SPOTS` PRIMARY KEY (
    `tourist_spot_id`
);

ALTER TABLE `user_missions` ADD CONSTRAINT `PK_USER_MISSIONS` PRIMARY KEY (
    `user_mission_id`
);

ALTER TABLE `coupons` ADD CONSTRAINT `PK_COUPONS` PRIMARY KEY (
    `coupon_id`
);

ALTER TABLE `visit_logs` ADD CONSTRAINT `PK_VISIT_LOGS` PRIMARY KEY (
    `visit_logs_id`
);

ALTER TABLE `user_stamps` ADD CONSTRAINT `PK_USER_STAMPS` PRIMARY KEY (
    `user_stamp_id`
);

ALTER TABLE `missions` ADD CONSTRAINT `PK_MISSIONS` PRIMARY KEY (
    `mission_id`
);

ALTER TABLE `stamps` ADD CONSTRAINT `PK_STAMPS` PRIMARY KEY (
    `stamp_id`
);
```

## 주요 관계

- users 1:N user_stamps
- users 1:N user_potatoes
- users 1:N user_missions
- users 1:N user_coupons
- users 1:N visit_logs
- users 1:N reward_histories
- tourist_spots 1:N missions
- tourist_spots 1:N visit_logs
- tourist_spots 1:N audio_guides
- stamps 1:N user_stamps
- potatoes 1:N user_potatoes
- coupons 1:N user_coupons
