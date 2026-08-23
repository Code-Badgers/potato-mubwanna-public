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
) VALUES (
    'POTATO_DEFAULT_BEGINNER',
    '새싹 감자',
    '강원 여행길',
    'COMMON',
    '강원 여행을 시작한 모든 사용자에게 지급되는 첫 감자예요. 돌봄과 걸음으로 함께 키워 보세요.',
    '회원가입 시 기본 지급',
    NULL,
    3000,
    0,
    TRUE,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);

INSERT INTO user_potatoes (
    user_id,
    potato_id,
    acquired_at,
    level,
    growth_distance,
    representative
)
SELECT
    app_user.user_id,
    starter_potato.potato_id,
    CURRENT_TIMESTAMP,
    1,
    0,
    TRUE
FROM users app_user
CROSS JOIN potatoes starter_potato
WHERE starter_potato.code = 'POTATO_DEFAULT_BEGINNER'
  AND NOT EXISTS (
      SELECT 1
      FROM user_potatoes owned_potato
      WHERE owned_potato.user_id = app_user.user_id
  );
