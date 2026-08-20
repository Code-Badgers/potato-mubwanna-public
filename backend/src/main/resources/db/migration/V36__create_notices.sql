CREATE TABLE notices (
    notice_id BIGSERIAL PRIMARY KEY,
    title VARCHAR(160) NOT NULL,
    content VARCHAR(2000) NOT NULL,
    published BOOLEAN NOT NULL,
    published_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_notices_published_at
    ON notices(published, published_at DESC, notice_id DESC);

INSERT INTO notices (
    title,
    content,
    published,
    published_at,
    created_at,
    updated_at
) VALUES
(
    '감자 스팟 데이터는 계속 보정됩니다',
    '감자 스팟은 강원도 관광지와 지역 맛집 데이터를 바탕으로 제공되며, 위치·분류·설명은 확인된 최신 정보에 맞춰 계속 보정됩니다.',
    TRUE,
    '2026-08-16 00:00:00+00',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
),
(
    '방문 인증은 현장 위치를 기준으로 합니다',
    '스탬프는 지정된 장소 근처에서 위치 확인을 마치면 찍을 수 있습니다. 위치 권한이 꺼져 있으면 인증이 제한될 수 있으니 여행 전 앱 위치 권한을 확인해 주세요.',
    TRUE,
    '2026-08-16 00:00:00+00',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);
