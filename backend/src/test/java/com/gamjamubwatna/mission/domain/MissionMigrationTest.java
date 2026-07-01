package com.gamjamubwatna.mission.domain;

import static org.assertj.core.api.Assertions.assertThat;

import java.sql.Connection;
import java.sql.ResultSet;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import javax.sql.DataSource;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = {
    "spring.datasource.url=jdbc:h2:mem:mission_migration;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.jpa.hibernate.ddl-auto=validate",
    "auth.jwt.secret=test-jwt-secret-must-be-long-enough"
})
class MissionMigrationTest {

    @Autowired
    private MissionRepository missionRepository;

    @Autowired
    private DataSource dataSource;

    @Test
    void seedsMvpMissionsInDisplayOrder() {
        List<Mission> missions = missionRepository.findAllByOrderByDisplayOrderAsc();

        assertThat(missions).hasSize(8);
        assertThat(missions.getFirst().getCode()).isEqualTo("MISSION_JEONGSEON_MARKET_QUIZ");
        assertThat(missions.getLast().getCode()).isEqualTo("MISSION_EVENT_HWACHEON");
        assertThat(missions.getFirst().getGroup()).isEqualTo(MissionGroup.JUMSOONI);
        assertThat(missions.getLast().getGroup()).isEqualTo(MissionGroup.EVENT);
    }

    @Test
    void createsUserMissionLookupIndexes() throws Exception {
        Set<String> indexNames = new HashSet<>();
        try (
            Connection connection = dataSource.getConnection();
            ResultSet indexes = connection.getMetaData()
                .getIndexInfo(null, null, "user_missions", false, false)
        ) {
            while (indexes.next()) {
                String indexName = indexes.getString("INDEX_NAME");
                if (indexName != null) {
                    indexNames.add(indexName.toLowerCase());
                }
            }
        }

        assertThat(indexNames)
            .contains("idx_user_missions_user_id", "idx_user_missions_mission_id");
    }
}
