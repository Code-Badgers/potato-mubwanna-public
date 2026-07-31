package com.gamjamubwatna.push.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import javax.sql.DataSource;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = {
    "spring.datasource.url=jdbc:h2:mem:push_token_migration;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.jpa.hibernate.ddl-auto=validate",
    "auth.jwt.secret=test-jwt-secret-must-be-long-enough"
})
class PushTokenMigrationTest {

    @Autowired
    private DataSource dataSource;

    @Test
    void createsUniqueTokensAndCascadesAccountDeletion() throws Exception {
        try (Connection connection = dataSource.getConnection()) {
            long firstUserId = insertUser(connection, "push-migration-1");
            long secondUserId = insertUser(connection, "push-migration-2");
            insertToken(connection, firstUserId, "shared-token", "ANDROID");
            insertToken(connection, firstUserId, "ios-token", "IOS");

            assertThatThrownBy(() ->
                insertToken(connection, secondUserId, "shared-token", "ANDROID")
            ).isInstanceOf(java.sql.SQLException.class);

            deleteUser(connection, firstUserId);

            assertThat(countTokens(connection, firstUserId)).isZero();
            deleteUser(connection, secondUserId);
        }
    }

    private long insertUser(Connection connection, String providerUserId) throws Exception {
        try (PreparedStatement insert = connection.prepareStatement("""
            INSERT INTO users (
                provider,
                provider_user_id,
                nickname,
                created_at,
                updated_at
            ) VALUES ('KAKAO', ?, 'push-test', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            """, Statement.RETURN_GENERATED_KEYS)) {
            insert.setString(1, providerUserId);
            insert.executeUpdate();
            try (ResultSet keys = insert.getGeneratedKeys()) {
                assertThat(keys.next()).isTrue();
                return keys.getLong(1);
            }
        }
    }

    private void insertToken(
        Connection connection,
        long userId,
        String token,
        String platform
    ) throws Exception {
        try (PreparedStatement insert = connection.prepareStatement("""
            INSERT INTO user_push_tokens (
                user_id,
                token,
                platform,
                created_at,
                updated_at
            ) VALUES (?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            """)) {
            insert.setLong(1, userId);
            insert.setString(2, token);
            insert.setString(3, platform);
            insert.executeUpdate();
        }
    }

    private void deleteUser(Connection connection, long userId) throws Exception {
        try (PreparedStatement delete = connection.prepareStatement(
            "DELETE FROM users WHERE user_id = ?"
        )) {
            delete.setLong(1, userId);
            delete.executeUpdate();
        }
    }

    private long countTokens(Connection connection, long userId) throws Exception {
        try (PreparedStatement select = connection.prepareStatement(
            "SELECT COUNT(*) FROM user_push_tokens WHERE user_id = ?"
        )) {
            select.setLong(1, userId);
            try (ResultSet row = select.executeQuery()) {
                assertThat(row.next()).isTrue();
                return row.getLong(1);
            }
        }
    }
}
