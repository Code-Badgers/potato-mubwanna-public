UPDATE coupons
SET
    name = '[공모전 시연용] ' || name,
    description = '공모전 시연용 쿠폰으로 실제 매장에서는 사용할 수 없습니다. ' || description,
    usage_place = '공모전 시연 전용 · 실제 사용처 없음'
WHERE code IS NOT NULL
  AND name NOT LIKE '[공모전 시연용]%';
