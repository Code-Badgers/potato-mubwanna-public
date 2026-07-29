package com.gamjamubwatna.user.application;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;

@SpringBootTest(properties = {
    "spring.datasource.url=jdbc:h2:mem:user_account_withdrawal;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.jpa.hibernate.ddl-auto=validate",
    "auth.jwt.secret=test-jwt-secret-must-be-long-enough"
})
class UserAccountWithdrawalIntegrationTest {

    @Autowired
    private UserAccountService userAccountService;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void deletesAccountSessionsVisitsAndCascadeOwnedData() {
        jdbcTemplate.update("""
            INSERT INTO users (
                user_id, provider, provider_user_id, email, nickname, created_at, updated_at
            ) VALUES (
                1001, 'KAKAO', 'withdraw-user', 'withdraw@example.com', '탈퇴사용자',
                CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
            )
            """);
        jdbcTemplate.update("""
            INSERT INTO tourist_spots (
                tourist_spot_id, content_type_id, name, category, latitude, longitude,
                created_at, updated_at
            ) VALUES (
                2001, 12, '탈퇴 검증 관광지', 'TOURIST_SPOT', 37.0, 128.0,
                CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
            )
            """);
        jdbcTemplate.update("""
            INSERT INTO refresh_tokens (user_id, token, expires_at)
            VALUES (1001, 'withdraw-refresh-token', CURRENT_TIMESTAMP + INTERVAL '1' DAY)
            """);
        jdbcTemplate.update("""
            INSERT INTO user_visits (
                user_id, tourist_spot_id, distance_meters, visited_at
            ) VALUES (1001, 2001, 10.0, CURRENT_TIMESTAMP)
            """);
        jdbcTemplate.update("""
            INSERT INTO favorite_spots (user_id, tourist_spot_id, created_at)
            VALUES (1001, 2001, CURRENT_TIMESTAMP)
            """);

        userAccountService.withdraw(1001L);

        assertThat(count("users", 1001L)).isZero();
        assertThat(count("refresh_tokens", 1001L)).isZero();
        assertThat(count("user_visits", 1001L)).isZero();
        assertThat(count("favorite_spots", 1001L)).isZero();
    }

    private int count(String table, Long userId) {
        Integer count = jdbcTemplate.queryForObject(
            "SELECT COUNT(*) FROM %s WHERE user_id = ?".formatted(table),
            Integer.class,
            userId
        );
        return count == null ? 0 : count;
    }
}
