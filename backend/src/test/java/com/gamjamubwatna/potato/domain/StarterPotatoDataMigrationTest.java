package com.gamjamubwatna.potato.domain;

import static org.assertj.core.api.Assertions.assertThat;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.MigrationVersion;
import org.junit.jupiter.api.Test;

class StarterPotatoDataMigrationTest {

    private static final String DATABASE_URL = "jdbc:h2:mem:starter_potato_migration;"
        + "MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH;DB_CLOSE_DELAY=-1";

    @Test
    void seedsCatalogAndBackfillsOnlyUsersWithoutPotatoes() throws Exception {
        Flyway.configure()
            .dataSource(DATABASE_URL, "sa", "")
            .target(MigrationVersion.fromVersion("40"))
            .load()
            .migrate();

        try (
            Connection connection = DriverManager.getConnection(DATABASE_URL, "sa", "");
            Statement statement = connection.createStatement()
        ) {
            statement.executeUpdate("""
                INSERT INTO users (
                    provider, provider_user_id, email, nickname, profile_image,
                    created_at, updated_at
                ) VALUES
                    ('KAKAO', 'empty-user', NULL, '무보유 사용자', NULL,
                        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
                    ('KAKAO', 'owner-user', NULL, '기존 보유 사용자', NULL,
                        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """);
            statement.executeUpdate("""
                INSERT INTO user_potatoes (
                    user_id, potato_id, acquired_at, level, growth_distance, representative
                )
                SELECT user_row.user_id, potato.potato_id, CURRENT_TIMESTAMP, 1, 0, TRUE
                FROM users user_row
                CROSS JOIN potatoes potato
                WHERE user_row.provider_user_id = 'owner-user'
                  AND potato.code = 'POTATO_HAJI_GANGNEUNG'
                """);
        }

        Flyway.configure()
            .dataSource(DATABASE_URL, "sa", "")
            .load()
            .migrate();

        try (
            Connection connection = DriverManager.getConnection(DATABASE_URL, "sa", "");
            Statement statement = connection.createStatement()
        ) {
            assertThat(singleInt(statement, """
                SELECT COUNT(*) FROM potatoes
                WHERE code = 'POTATO_DEFAULT_BEGINNER'
                  AND name = '새싹 감자'
                  AND acquisition_hint = '회원가입 시 기본 지급'
                  AND display_order = 0
                """)).isEqualTo(1);
            assertThat(singleInt(statement, """
                SELECT COUNT(*)
                FROM user_potatoes owned_potato
                JOIN users user_row ON user_row.user_id = owned_potato.user_id
                JOIN potatoes potato ON potato.potato_id = owned_potato.potato_id
                WHERE user_row.provider_user_id = 'empty-user'
                  AND potato.code = 'POTATO_DEFAULT_BEGINNER'
                  AND owned_potato.representative = TRUE
                """)).isEqualTo(1);
            assertThat(singleInt(statement, """
                SELECT COUNT(*)
                FROM user_potatoes owned_potato
                JOIN users user_row ON user_row.user_id = owned_potato.user_id
                WHERE user_row.provider_user_id = 'owner-user'
                """)).isEqualTo(1);
            assertThat(singleInt(statement, """
                SELECT COUNT(*)
                FROM user_potatoes owned_potato
                JOIN users user_row ON user_row.user_id = owned_potato.user_id
                JOIN potatoes potato ON potato.potato_id = owned_potato.potato_id
                WHERE user_row.provider_user_id = 'owner-user'
                  AND potato.code = 'POTATO_DEFAULT_BEGINNER'
                """)).isZero();
        }
    }

    private int singleInt(Statement statement, String sql) throws Exception {
        try (ResultSet resultSet = statement.executeQuery(sql)) {
            resultSet.next();
            return resultSet.getInt(1);
        }
    }
}
