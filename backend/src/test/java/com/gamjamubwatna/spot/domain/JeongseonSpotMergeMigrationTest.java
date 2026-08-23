package com.gamjamubwatna.spot.domain;

import static org.assertj.core.api.Assertions.assertThat;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.MigrationVersion;
import org.junit.jupiter.api.Test;

class JeongseonSpotMergeMigrationTest {

    private static final String DATABASE_URL = "jdbc:h2:mem:jeongseon_spot_merge;"
        + "MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH;DB_CLOSE_DELAY=-1";

    @Test
    void movesDuplicateSpotRelationsToOfficialTourApiSpot() throws Exception {
        Flyway.configure()
            .dataSource(DATABASE_URL, "sa", "")
            .target(MigrationVersion.fromVersion("39"))
            .load()
            .migrate();

        try (
            Connection connection = DriverManager.getConnection(DATABASE_URL, "sa", "");
            Statement statement = connection.createStatement()
        ) {
            long duplicateSpotId = singleLong(statement, """
                SELECT tourist_spot_id
                FROM tourist_spots
                WHERE content_id = 'CURATED:NOTION:JEONGSEON_ARIRANG_MARKET'
                """);
            statement.executeUpdate("""
                INSERT INTO users (
                    provider, provider_user_id, email, nickname, profile_image,
                    created_at, updated_at
                ) VALUES (
                    'KAKAO', 'jeongseon-merge-user', NULL, '정선 사용자', NULL,
                    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
                )
                """);
            long userId = singleLong(statement, """
                SELECT user_id FROM users WHERE provider_user_id = 'jeongseon-merge-user'
                """);

            statement.executeUpdate("""
                INSERT INTO favorite_spots (
                    user_id, tourist_spot_id, created_at, route_order
                ) VALUES (%d, %d, CURRENT_TIMESTAMP, 1)
                """.formatted(userId, duplicateSpotId));
            statement.executeUpdate("""
                INSERT INTO user_visits (
                    user_id, tourist_spot_id, distance_meters, visited_at
                ) VALUES (%d, %d, 18.5, CURRENT_TIMESTAMP)
                """.formatted(userId, duplicateSpotId));
            statement.executeUpdate("""
                INSERT INTO audio_guides (
                    tourist_spot_id, external_story_id, title, audio_url, script,
                    character_script, language, created_at, updated_at
                ) VALUES (
                    %d, 'jeongseon-story', '정선 아리랑시장',
                    'https://example.com/jeongseon.mp3', NULL, NULL, 'ko',
                    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
                )
                """.formatted(duplicateSpotId));
            statement.executeUpdate("""
                INSERT INTO spot_congestion_predictions (
                    tourist_spot_id, prediction_date, predicted_visitors,
                    baseline_visitors, congestion_level, source, created_at
                ) VALUES (
                    %d, DATE '2026-08-23', 120, 100, 'NORMAL', 'TEST', CURRENT_TIMESTAMP
                )
                """.formatted(duplicateSpotId));
            statement.executeUpdate("""
                INSERT INTO tourist_spot_menu_items (
                    tourist_spot_id, name, price_won, price_note, display_order,
                    source_url, verified_on, active
                ) VALUES (
                    %d, '곤드레 감자전', 10000, NULL, 1,
                    'https://example.com/menu', DATE '2026-08-23', TRUE
                )
                """.formatted(duplicateSpotId));
            statement.executeUpdate("""
                INSERT INTO user_missions (
                    user_id, mission_id, completed_at, completion_period,
                    evidence_upload_key, tourist_spot_id
                )
                SELECT %d, mission_id, CURRENT_TIMESTAMP, 'ONCE',
                       'mission-uploads/jeongseon.jpg', %d
                FROM missions
                WHERE code = 'MISSION_JEONGSEON_MARKET_QUIZ'
                """.formatted(userId, duplicateSpotId));
            statement.executeUpdate("""
                INSERT INTO stamps (
                    stamp_key, city_name, tourist_spot_id, stamp_name, stamp_image,
                    display_order, created_at, updated_at
                ) VALUES (
                    'LEGACY_JEONGSEON_ALIAS', '정선군', %d, '정선아리랑시장', NULL,
                    30, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
                )
                """.formatted(duplicateSpotId));
            statement.executeUpdate("""
                INSERT INTO user_stamps (
                    user_id, stamp_id, tourist_spot_id, acquired_at
                )
                SELECT %d, stamp_id, %d, CURRENT_TIMESTAMP
                FROM stamps
                WHERE stamp_key = 'LEGACY_JEONGSEON_ALIAS'
                """.formatted(userId, duplicateSpotId));
        }

        Flyway.configure()
            .dataSource(DATABASE_URL, "sa", "")
            .load()
            .migrate();

        try (
            Connection connection = DriverManager.getConnection(DATABASE_URL, "sa", "");
            Statement statement = connection.createStatement()
        ) {
            long officialSpotId = singleLong(statement, """
                SELECT tourist_spot_id FROM tourist_spots WHERE content_id = '132003'
                """);
            long duplicateSpotId = singleLong(statement, """
                SELECT tourist_spot_id
                FROM tourist_spots
                WHERE content_id = 'CURATED:NOTION:JEONGSEON_ARIRANG_MARKET'
                """);

            assertThat(singleLong(statement, """
                SELECT COUNT(*) FROM tourist_spots
                WHERE tourist_spot_id = %d
                  AND active = FALSE
                  AND stamp_enabled = FALSE
                  AND rallybook_featured = FALSE
                """.formatted(duplicateSpotId))).isEqualTo(1);
            assertRelationMoved(statement, "favorite_spots", officialSpotId, duplicateSpotId);
            assertRelationMoved(statement, "user_visits", officialSpotId, duplicateSpotId);
            assertRelationMoved(statement, "audio_guides", officialSpotId, duplicateSpotId);
            assertRelationMoved(
                statement,
                "spot_congestion_predictions",
                officialSpotId,
                duplicateSpotId
            );
            assertRelationMoved(
                statement,
                "tourist_spot_menu_items",
                officialSpotId,
                duplicateSpotId
            );
            assertRelationMoved(statement, "user_missions", officialSpotId, duplicateSpotId);
            assertRelationMoved(statement, "user_stamps", officialSpotId, duplicateSpotId);
            assertThat(singleLong(statement, """
                SELECT COUNT(*) FROM stamps WHERE tourist_spot_id = %d
                """.formatted(duplicateSpotId))).isZero();
        }
    }

    private void assertRelationMoved(
        Statement statement,
        String tableName,
        long officialSpotId,
        long duplicateSpotId
    ) throws Exception {
        assertThat(singleLong(statement, """
            SELECT COUNT(*) FROM %s WHERE tourist_spot_id = %d
            """.formatted(tableName, officialSpotId))).isEqualTo(1);
        assertThat(singleLong(statement, """
            SELECT COUNT(*) FROM %s WHERE tourist_spot_id = %d
            """.formatted(tableName, duplicateSpotId))).isZero();
    }

    private long singleLong(Statement statement, String sql) throws Exception {
        try (ResultSet resultSet = statement.executeQuery(sql)) {
            resultSet.next();
            return resultSet.getLong(1);
        }
    }
}
