CREATE TABLE coupons (
    coupon_id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description VARCHAR(500) NOT NULL,
    benefit_amount INTEGER NOT NULL,
    usage_place VARCHAR(255) NOT NULL,
    CONSTRAINT ck_coupons_benefit_amount_non_negative CHECK (benefit_amount >= 0)
);

CREATE TABLE user_coupons (
    user_coupon_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    coupon_id BIGINT NOT NULL REFERENCES coupons(coupon_id),
    status VARCHAR(20) NOT NULL,
    issued_at TIMESTAMP WITH TIME ZONE NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    used_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT ck_user_coupons_status CHECK (status IN ('AVAILABLE', 'USED')),
    CONSTRAINT ck_user_coupons_used_at CHECK (
        (status = 'AVAILABLE' AND used_at IS NULL)
        OR (status = 'USED' AND used_at IS NOT NULL)
    ),
    CONSTRAINT ck_user_coupons_expiration CHECK (expires_at > issued_at)
);

CREATE INDEX idx_user_coupons_user_id_issued_at
    ON user_coupons(user_id, issued_at DESC);

CREATE INDEX idx_user_coupons_coupon_id
    ON user_coupons(coupon_id);
