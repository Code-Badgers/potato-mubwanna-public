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
        'POTATO_HAJI_SEED',
        '하지 씨앗감자',
        '강릉시',
        'COMMON',
        '안목 해변 미션에서 처음 싹을 틔우는 밝은 씨앗 감자입니다.',
        '안목 해변 사진 인증 미션 완료',
        NULL,
        2800,
        6,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    ),
    (
        'POTATO_JAJU_SEED',
        '자주감자',
        '삼척시',
        'RARE',
        '동굴 속 보랏빛 광물을 닮은 호기심 많은 자주색 감자입니다.',
        '환선굴 퀴즈 미션 완료',
        NULL,
        4600,
        7,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    ),
    (
        'POTATO_DURUMI_SEED',
        '두루미감자',
        '철원군',
        'RARE',
        '철원 고석정의 철새 이야기를 담은 우아한 두루미 감자입니다.',
        '철원 고석정 QR 미션 완료',
        NULL,
        5200,
        8,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    ),
    (
        'POTATO_HANWOO_SEED',
        '한우감자',
        '횡성군',
        'RARE',
        '횡성의 요리 체험을 따라 따뜻한 갈색으로 익어가는 감자입니다.',
        '횡성 한우 체험 QR 미션 완료',
        NULL,
        5400,
        9,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    ),
    (
        'POTATO_COMMON_SEED',
        '일반 씨앗감자',
        '평창군',
        'COMMON',
        '대관령 여행길에서 누구나 만날 수 있는 소박한 기본 씨앗 감자입니다.',
        '대관령 양떼목장 방문 미션 완료',
        NULL,
        3000,
        10,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    ),
    (
        'POTATO_GOLDEN_HONGCHEON',
        '홍천 황금감자',
        '홍천군',
        'EPIC',
        '한적한 수타사 산소길에서 발견되는 숲빛 황금 감자입니다.',
        '홍천 수타사 산소길 걷기 미션 완료',
        NULL,
        7600,
        11,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    ),
    (
        'POTATO_JAJAK_INJE',
        '자작감자',
        '인제군',
        'RARE',
        '인제 자작나무 숲의 하얀 결을 품은 차분한 숲길 감자입니다.',
        '인제 자작나무 숲 걷기 미션 완료',
        NULL,
        6200,
        12,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    ),
    (
        'POTATO_LEGEND_YANGGU',
        '양구 전설감자',
        '양구군',
        'LEGENDARY',
        '두타연의 숨은 계곡과 밤하늘을 담은 전설 등급 감자입니다.',
        '양구 두타연 방문 미션 완료',
        NULL,
        10500,
        13,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );

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
        'POTATO_HOBAN_CHUNCHEON',
        '호반감자',
        '춘천시',
        'COMMON',
        '춘천 호반 산책길에서 조용히 자라나는 산뜻한 감자입니다.',
        '남이섬 감자 산책 미션 완료',
        NULL,
        3200,
        14,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    ),
    (
        'POTATO_RARE_SEED',
        '희귀 감자 씨앗',
        '강원특별자치도',
        'RARE',
        '여러 시군을 누빈 여행자에게만 싹을 틔우는 특별한 씨앗 감자입니다.',
        '주간 시군 방문 미션 완료',
        NULL,
        6000,
        15,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );

UPDATE missions
SET reward_label = 'POTATO_HOBAN_CHUNCHEON',
    updated_at = CURRENT_TIMESTAMP
WHERE code = 'MISSION_NAMI_ISLAND_WALK'
  AND reward_type = 'POTATO';

UPDATE missions
SET reward_label = 'POTATO_RARE_SEED',
    updated_at = CURRENT_TIMESTAMP
WHERE code = 'MISSION_WEEKLY_CITIES'
  AND reward_type = 'POTATO';
