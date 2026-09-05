package com.gamjamubwatna.visit.domain;

import static org.assertj.core.api.Assertions.assertThat;

import java.sql.DriverManager;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;

class PhotoVisitRewardMigrationTest {
    @Test
    void onlyUnrewardedPhotoOriginRecordsBecomeRetryable() throws Exception {
        String url = "jdbc:h2:mem:photo_visit_reward_migration;MODE=PostgreSQL;"
            + "DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH;DB_CLOSE_DELAY=-1";
        Flyway.configure().dataSource(url, "sa", "").target("46").load().migrate();
        try (var connection = DriverManager.getConnection(url, "sa", "");
             var statement = connection.createStatement()) {
            for (int scenario = 1; scenario <= 4; scenario++) {
                statement.executeUpdate("""
                    INSERT INTO users(provider, provider_user_id, nickname, created_at, updated_at)
                    VALUES ('KAKAO', 'photo-migration-%d', '사진 검증', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                    """.formatted(scenario));
                statement.executeUpdate("""
                    INSERT INTO user_visits(user_id, tourist_spot_id, distance_meters, visited_at)
                    SELECT u.user_id, s.tourist_spot_id, 0, TIMESTAMP '2026-09-05 00:00:00'
                    FROM users u CROSS JOIN (SELECT MIN(tourist_spot_id) tourist_spot_id FROM stamps) s
                    WHERE u.provider_user_id = 'photo-migration-%d'
                    """.formatted(scenario));
                // 1: 사진 최초 기록, 2: 사진 전에 정상 방문, 3: 스탬프 지급 완료, 4: 사진 없음
                if (scenario <= 3) {
                    String completedAt = scenario == 2 ? "2026-09-05 01:00:00" : "2026-09-05 00:00:00";
                    statement.executeUpdate("""
                        INSERT INTO user_missions(user_id, mission_id, completed_at, completion_period,
                            evidence_upload_key, tourist_spot_id)
                        SELECT v.user_id, (SELECT MIN(mission_id) FROM missions), TIMESTAMP '%s', 'ONCE',
                            'mission-uploads/test.jpg', v.tourist_spot_id
                        FROM user_visits v JOIN users u ON u.user_id = v.user_id
                        WHERE u.provider_user_id = 'photo-migration-%d'
                        """.formatted(completedAt, scenario));
                }
                if (scenario == 3) {
                    statement.executeUpdate("""
                        INSERT INTO user_stamps(user_id, stamp_id, tourist_spot_id, acquired_at)
                        SELECT v.user_id, s.stamp_id, v.tourist_spot_id, v.visited_at
                        FROM user_visits v JOIN users u ON u.user_id = v.user_id
                        JOIN stamps s ON s.tourist_spot_id = v.tourist_spot_id
                        WHERE u.provider_user_id = 'photo-migration-3'
                        """);
                }
            }
        }
        Flyway.configure().dataSource(url, "sa", "").load().migrate();
        try (var connection = DriverManager.getConnection(url, "sa", "");
             var statement = connection.createStatement();
             var rows = statement.executeQuery("""
                 SELECT u.provider_user_id, v.visit_rewards_processed FROM user_visits v
                 JOIN users u ON u.user_id = v.user_id ORDER BY u.provider_user_id
                 """)) {
            int count = 0;
            while (rows.next()) {
                assertThat(rows.getBoolean(2)).isEqualTo(!rows.getString(1).equals("photo-migration-1"));
                count++;
            }
            assertThat(count).isEqualTo(4);
        }
    }
}
