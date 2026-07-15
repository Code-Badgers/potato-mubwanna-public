ALTER TABLE coupons ADD COLUMN code VARCHAR(80);
ALTER TABLE coupons ADD COLUMN valid_days INTEGER NOT NULL DEFAULT 30;
ALTER TABLE coupons ADD CONSTRAINT uk_coupons_code UNIQUE (code);
ALTER TABLE coupons ADD CONSTRAINT ck_coupons_valid_days_positive CHECK (valid_days > 0);

ALTER TABLE missions
    ADD COLUMN reward_coupon_id BIGINT REFERENCES coupons(coupon_id);

INSERT INTO coupons (code, name, description, benefit_amount, usage_place, valid_days) VALUES
    ('CP_PYEONGCHANG_EXPERIENCE', '평창 감자 체험 할인 쿠폰', '평창 감자 체험장에서 사용할 수 있습니다.', 3000, '평창 감자 체험장', 30),
    ('CP_HWACHEON_LOCAL', '화천 지역 쿠폰', '화천 감자 축제 제휴점에서 사용할 수 있습니다.', 5000, '화천 감자 축제 제휴점', 30),
    ('CP_ONNURI_5000', '속초 온누리상품권 5,000원권', '속초 중앙시장 온누리상품권 가맹점에서 사용할 수 있습니다.', 5000, '속초 중앙시장 가맹점', 30),
    ('CP_WONJU_CAFE_3000', '원주 카페 3,000원 할인권', '원주 뮤지엄 산 인근 제휴 카페에서 사용할 수 있습니다.', 3000, '원주 제휴 카페', 30),
    ('CP_TAEBAEK_MARKET_5000', '태백 전통시장 5,000원권', '태백 전통시장 제휴점에서 사용할 수 있습니다.', 5000, '태백 전통시장 제휴점', 30),
    ('CP_YANGYANG_SURF_10', '양양 서핑 체험 10% 할인권', '양양 서피비치 제휴점에서 사용할 수 있습니다.', 10, '양양 서피비치 제휴점', 30),
    ('CP_HWACHEON_FISH_FREE', '화천 산천어 체험권', '화천 산천어 축제장에서 사용할 수 있습니다.', 0, '화천 산천어 축제장', 30);

UPDATE missions
SET reward_coupon_id = (SELECT coupon_id FROM coupons WHERE code = 'CP_PYEONGCHANG_EXPERIENCE')
WHERE code = 'MISSION_PYEONGCHANG_QR';

UPDATE missions
SET reward_coupon_id = (SELECT coupon_id FROM coupons WHERE code = 'CP_HWACHEON_LOCAL')
WHERE code = 'MISSION_EVENT_HWACHEON';

UPDATE missions
SET reward_coupon_id = (SELECT coupon_id FROM coupons WHERE code = 'CP_ONNURI_5000')
WHERE code = 'MISSION_SOKCHO_ONNURI_QR';

UPDATE missions
SET reward_coupon_id = (SELECT coupon_id FROM coupons WHERE code = 'CP_WONJU_CAFE_3000')
WHERE code = 'MISSION_WONJU_MUSEUM_SAN_PHOTO_OCR';

UPDATE missions
SET reward_coupon_id = (SELECT coupon_id FROM coupons WHERE code = 'CP_TAEBAEK_MARKET_5000')
WHERE code = 'MISSION_TAEBAEK_HWANGJI_VISIT';

UPDATE missions
SET reward_coupon_id = (SELECT coupon_id FROM coupons WHERE code = 'CP_YANGYANG_SURF_10')
WHERE code = 'MISSION_YANGYANG_SURFYBEACH_QUIZ';

UPDATE missions
SET reward_coupon_id = (SELECT coupon_id FROM coupons WHERE code = 'CP_HWACHEON_FISH_FREE')
WHERE code = 'MISSION_HWACHEON_SANCHEONEO_QR';

ALTER TABLE missions
    ADD CONSTRAINT ck_missions_coupon_reward_mapping CHECK (
        (reward_type = 'COUPON' AND reward_coupon_id IS NOT NULL)
        OR (reward_type <> 'COUPON' AND reward_coupon_id IS NULL)
    );
