package com.gamjamubwatna.stamp.domain;

import static org.assertj.core.api.Assertions.assertThat;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.MigrationVersion;
import org.junit.jupiter.api.Test;

class PassportStampDataMigrationTest {

    private static final String DATABASE_URL = "jdbc:h2:mem:passport_stamp_data_migration;"
        + "MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH;DB_CLOSE_DELAY=-1";

    @Test
    void migratesOnlyVisitedPassportSpotsFromLegacyCityStamps() throws Exception {
        Flyway.configure()
            .dataSource(DATABASE_URL, "sa", "")
            .target(MigrationVersion.fromVersion("37"))
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
                    ('KAKAO', 'passport-migration-user', NULL, '패스포트 사용자', NULL,
                        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
                    ('KAKAO', 'legacy-city-user', NULL, '도시 스탬프 사용자', NULL,
                        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """);
            statement.executeUpdate("""
                INSERT INTO tourist_spots (
                    content_id, content_type_id, name, category, latitude, longitude,
                    address, city_name, image_url, source, potato_tags, congestion_level,
                    verification_radius_meter, stamp_enabled, active, created_at, updated_at,
                    rallybook_featured
                ) VALUES (
                    'non-passport-chuncheon', 12, '비패스포트 춘천 관광지', 'POTATO_TOUR',
                    37.8, 127.7, '춘천시', '춘천시', NULL, 'TOUR_API', NULL, 'NORMAL',
                    100, TRUE, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, FALSE
                )
                """);
            statement.executeUpdate("""
                INSERT INTO user_stamps (user_id, stamp_id, tourist_spot_id, acquired_at)
                SELECT user_row.user_id, city_stamp.stamp_id, spot.tourist_spot_id,
                       CURRENT_TIMESTAMP
                FROM users user_row
                JOIN stamps city_stamp ON city_stamp.city_name = '춘천시'
                JOIN tourist_spots spot ON spot.content_id = '128019'
                WHERE user_row.provider_user_id = 'passport-migration-user'
                """);
            statement.executeUpdate("""
                INSERT INTO user_stamps (user_id, stamp_id, tourist_spot_id, acquired_at)
                SELECT user_row.user_id, city_stamp.stamp_id, spot.tourist_spot_id,
                       CURRENT_TIMESTAMP
                FROM users user_row
                JOIN stamps city_stamp ON city_stamp.city_name = '춘천시'
                JOIN tourist_spots spot ON spot.content_id = 'non-passport-chuncheon'
                WHERE user_row.provider_user_id = 'legacy-city-user'
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
            assertThat(singleInt(statement, "SELECT COUNT(*) FROM stamps")).isEqualTo(29);
            assertThat(singleInt(
                statement,
                "SELECT COUNT(*) FROM legacy_city_stamps_v38_archive"
            )).isEqualTo(18);
            assertThat(singleInt(
                statement,
                "SELECT COUNT(*) FROM legacy_user_stamps_v38_archive"
            )).isEqualTo(2);
            assertThat(singleInt(statement, """
                SELECT COUNT(*)
                FROM user_stamps user_stamp
                JOIN users user_row ON user_row.user_id = user_stamp.user_id
                JOIN stamps stamp ON stamp.stamp_id = user_stamp.stamp_id
                WHERE user_row.provider_user_id = 'passport-migration-user'
                  AND stamp.tourist_spot_id = user_stamp.tourist_spot_id
                """)).isEqualTo(1);
            assertThat(singleInt(statement, """
                SELECT COUNT(*)
                FROM user_stamps user_stamp
                JOIN users user_row ON user_row.user_id = user_stamp.user_id
                WHERE user_row.provider_user_id = 'legacy-city-user'
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
