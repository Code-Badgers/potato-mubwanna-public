CREATE TABLE potatoes (
    potato_id BIGSERIAL PRIMARY KEY,
    code VARCHAR(80) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    region VARCHAR(80) NOT NULL,
    rarity VARCHAR(30) NOT NULL,
    description VARCHAR(500) NOT NULL,
    acquisition_hint VARCHAR(255) NOT NULL,
    image_url VARCHAR(500),
    growth_goal_distance DOUBLE PRECISION NOT NULL,
    display_order INTEGER NOT NULL UNIQUE,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE user_potatoes (
    user_potato_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    potato_id BIGINT NOT NULL REFERENCES potatoes(potato_id),
    acquired_at TIMESTAMP WITH TIME ZONE NOT NULL,
    level INTEGER NOT NULL DEFAULT 1,
    growth_distance DOUBLE PRECISION NOT NULL DEFAULT 0,
    representative BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT uk_user_potatoes_user_potato UNIQUE (user_id, potato_id)
);

CREATE INDEX idx_potatoes_active_display_order
    ON potatoes(active, display_order);

CREATE INDEX idx_user_potatoes_user_id
    ON user_potatoes(user_id);

CREATE INDEX idx_user_potatoes_user_id_representative
    ON user_potatoes(user_id, representative);

INSERT INTO potatoes (
    code,
    name,
    region,
    rarity,
    description,
    acquisition_hint,
    image_url,
    growth_goal_distance,
    display_order,
    active,
    created_at,
    updated_at
) VALUES
    (
        'POTATO_HAJI_GANGNEUNG',
        '하지감자',
        '강릉시',
        'COMMON',
        '강릉 여행길에서 처음 만나기 좋은 기본 감자입니다.',
        '강릉 감자 스팟 방문 인증',
        NULL,
        3000,
        1,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    ),
    (
        'POTATO_GONDRE_JEONGSEON',
        '곤드레감자',
        '정선군',
        'RARE',
        '정선 장터와 곤드레 향토 음식 이야기를 품은 희귀 감자입니다.',
        '정선 5일장 스탬프 또는 정선 미션 완료',
        NULL,
        4200,
        2,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    ),
    (
        'POTATO_GOLDEN_GANGWON',
        '황금감자',
        '강원특별자치도',
        'EPIC',
        '혼잡도가 낮은 숨은 명소에서 만날 확률이 높아지는 특별 감자입니다.',
        '한적한 감자 스팟 방문 인증 보너스',
        NULL,
        7000,
        3,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    ),
    (
        'POTATO_LEGEND_PYEONGCHANG',
        '전설감자',
        '평창군',
        'LEGENDARY',
        '강원 고랭지 여행을 오래 이어간 사용자에게 열리는 전설 등급 감자입니다.',
        '평창 희귀 미션 완료',
        NULL,
        10000,
        4,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    ),
    (
        'POTATO_PEACE_COSUNG',
        '평화감자',
        '고성군',
        'RARE',
        '고성 북쪽 여행지에서 평화의 의미를 담아 획득하는 감자입니다.',
        '고성 DMZ 연계 미션 완료',
        NULL,
        5000,
        5,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );
