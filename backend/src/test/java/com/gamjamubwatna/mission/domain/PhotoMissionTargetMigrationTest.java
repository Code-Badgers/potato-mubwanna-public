package com.gamjamubwatna.mission.domain;

import static org.assertj.core.api.Assertions.assertThat;

import java.sql.DriverManager;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;

class PhotoMissionTargetMigrationTest {
    @Test
    void leavesAmbiguousTargetsUnlinkedDuringUpgrade() throws Exception {
        String url = "jdbc:h2:mem:photo_target_upgrade;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1";
        Flyway.configure().dataSource(url, "sa", "").target("47").load().migrate();
        try (var connection = DriverManager.getConnection(url, "sa", "");
             var statement = connection.createStatement()) {
            // 실제 운영처럼 기존 데이터에 동명 장소가 추가된 상태에서 이관한다.
            statement.executeUpdate("""
                INSERT INTO tourist_spots(content_id, content_type_id, name, category, latitude, longitude,
                    address, city_name, source, congestion_level, verification_radius_meter,
                    stamp_enabled, active, created_at, updated_at, rallybook_featured)
                SELECT 'TEST:DUPLICATE:PHOTO', content_type_id, name, category, latitude, longitude,
                    address, city_name, source, congestion_level, verification_radius_meter,
                    stamp_enabled, active, created_at, updated_at, rallybook_featured
                FROM tourist_spots WHERE name = '영금정' AND city_name = '속초시' AND active = TRUE
                """);
        }
        Flyway.configure().dataSource(url, "sa", "").load().migrate();
        try (var connection = DriverManager.getConnection(url, "sa", "");
             var statement = connection.createStatement();
             var rows = statement.executeQuery("""
                 SELECT active, target_spot_id FROM missions
                 WHERE code = 'MISSION_SOKCHO_YEONGGEUMJEONG_PHOTO'
                 """)) {
            assertThat(rows.next()).isTrue();
            assertThat(rows.getBoolean("active")).isFalse();
            assertThat(rows.getObject("target_spot_id")).isNull();
        }
    }
}
