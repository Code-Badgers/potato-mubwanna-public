package com.gamjamubwatna.mission.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
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
    private MissionVerificationPolicyRepository missionVerificationPolicyRepository;

    @Autowired
    private DataSource dataSource;

    @Test
    void seedsMvpMissionsInDisplayOrder() {
        List<Mission> missions = missionRepository.findAllByOrderByDisplayOrderAsc();

        assertThat(missions).hasSize(24);
        assertThat(missions.getFirst().getCode()).isEqualTo("MISSION_JEONGSEON_MARKET_QUIZ");
        assertThat(missions.getLast().getCode()).isEqualTo("MISSION_YANGGU_DUTAYEON_VISIT");
        assertThat(missions.getFirst().getGroup()).isEqualTo(MissionGroup.JUMSOONI);
        assertThat(missions)
            .extracting(Mission::getType)
            .contains(MissionType.PHOTO_OCR);
    }

    @Test
    void seedsMissionVerificationPolicies() {
        List<MissionVerificationPolicy> policies = missionVerificationPolicyRepository.findAll();

        assertThat(policies).hasSize(17);
        assertThat(missionVerificationPolicyRepository.findByMissionId(1L))
            .get()
            .extracting(MissionVerificationPolicy::getExpectedAnswer)
            .isEqualTo("곤드레감자");
    }

    @Test
    void seedsPhotoOcrKeywords() throws Exception {
        try (
            Connection connection = dataSource.getConnection();
            ResultSet rows = connection.createStatement().executeQuery("""
                SELECT m.code, p.expected_answer
                FROM mission_verification_policies p
                JOIN missions m ON m.mission_id = p.mission_id
                WHERE m.code IN (
                    'MISSION_GANGNEUNG_ANMOK_PHOTO_OCR',
                    'MISSION_WONJU_MUSEUM_SAN_PHOTO_OCR',
                    'MISSION_GOSEONG_DMZ_PHOTO_OCR'
                )
                ORDER BY m.code
                """)
        ) {
            Set<String> policyPairs = new HashSet<>();
            while (rows.next()) {
                policyPairs.add(rows.getString("CODE") + "=" + rows.getString("EXPECTED_ANSWER"));
            }

            assertThat(policyPairs)
                .containsExactlyInAnyOrder(
                    "MISSION_GANGNEUNG_ANMOK_PHOTO_OCR=하지감자",
                    "MISSION_WONJU_MUSEUM_SAN_PHOTO_OCR=물의 정원",
                    "MISSION_GOSEONG_DMZ_PHOTO_OCR=평화의 종"
                );
        }
    }

    @Test
    void seedsMissionQrCodes() throws Exception {
        try (
            Connection connection = dataSource.getConnection();
            ResultSet rows = connection.createStatement().executeQuery("""
                SELECT m.code, p.expected_qr_code
                FROM mission_verification_policies p
                JOIN missions m ON m.mission_id = p.mission_id
                WHERE m.mission_type = 'QR_SCAN'
                ORDER BY m.code
                """)
        ) {
            Set<String> policyPairs = new HashSet<>();
            while (rows.next()) {
                policyPairs.add(rows.getString("CODE") + "=" + rows.getString("EXPECTED_QR_CODE"));
            }

            assertThat(policyPairs)
                .containsExactlyInAnyOrder(
                    "MISSION_CHEORWON_GOSEOKJEONG_QR=gamjamubwatna://mission/qr/MISSION_CHEORWON_GOSEOKJEONG_QR",
                    "MISSION_HOENGSEONG_HANWOO_QR=gamjamubwatna://mission/qr/MISSION_HOENGSEONG_HANWOO_QR",
                    "MISSION_HWACHEON_SANCHEONEO_QR=gamjamubwatna://mission/qr/MISSION_HWACHEON_SANCHEONEO_QR",
                    "MISSION_PYEONGCHANG_QR=gamjamubwatna://mission/qr/MISSION_PYEONGCHANG_QR",
                    "MISSION_SOKCHO_ONNURI_QR=gamjamubwatna://mission/qr/MISSION_SOKCHO_ONNURI_QR"
                );
        }
    }

    @Test
    void mapsEveryCouponRewardMissionToCouponCatalog() {
        List<Mission> missions = missionRepository.findAllByOrderByDisplayOrderAsc();

        assertThat(missions)
            .filteredOn(mission -> mission.getRewardType() == MissionRewardType.COUPON)
            .hasSize(7)
            .allSatisfy(mission -> assertThat(mission.getRewardCouponId()).isNotNull());
        assertThat(missions)
            .filteredOn(mission -> mission.getRewardType() != MissionRewardType.COUPON)
            .allSatisfy(mission -> assertThat(mission.getRewardCouponId()).isNull());
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
            .contains(
                "idx_user_missions_user_id",
                "idx_user_missions_mission_id",
                "idx_user_missions_travel_evidence"
            );
    }

    @Test
    void createsNullableMissionEvidenceColumns() throws Exception {
        Set<String> columnNames = new HashSet<>();
        try (
            Connection connection = dataSource.getConnection();
            ResultSet columns = connection.getMetaData()
                .getColumns(null, null, "user_missions", null)
        ) {
            while (columns.next()) {
                columnNames.add(columns.getString("COLUMN_NAME").toLowerCase());
            }
        }

        assertThat(columnNames).contains("evidence_upload_key", "tourist_spot_id");
    }

    @Test
    void createsRewardHistoryLookupIndex() throws Exception {
        Set<String> indexNames = new HashSet<>();
        try (
            Connection connection = dataSource.getConnection();
            ResultSet indexes = connection.getMetaData()
                .getIndexInfo(null, null, "reward_histories", false, false)
        ) {
            while (indexes.next()) {
                String indexName = indexes.getString("INDEX_NAME");
                if (indexName != null) {
                    indexNames.add(indexName.toLowerCase());
                }
            }
        }

        assertThat(indexNames)
            .contains("idx_reward_histories_user_id_created_at");
    }

    @Test
    void scopesMissionCompletionsAndRewardsByPeriod() throws Exception {
        try (Connection connection = dataSource.getConnection()) {
            long userId = insertPeriodTestUser(connection);
            long missionId = findMissionId(connection, "MISSION_DAILY_STEPS");
            try {
                insertUserMission(connection, userId, missionId, "DAY:2026-07-01");
                insertUserMission(connection, userId, missionId, "DAY:2026-07-02");

                assertThatThrownBy(() ->
                    insertUserMission(connection, userId, missionId, "DAY:2026-07-02")
                ).isInstanceOf(java.sql.SQLException.class);
                assertThat(countRows(connection, "user_missions", userId)).isEqualTo(2);

                insertRewardHistory(connection, userId, missionId, "DAY:2026-07-01");
                insertRewardHistory(connection, userId, missionId, "DAY:2026-07-02");

                assertThatThrownBy(() ->
                    insertRewardHistory(connection, userId, missionId, "DAY:2026-07-02")
                ).isInstanceOf(java.sql.SQLException.class);
                assertThat(countRows(connection, "reward_histories", userId)).isEqualTo(2);
            } finally {
                try (PreparedStatement delete = connection.prepareStatement(
                    "DELETE FROM users WHERE user_id = ?"
                )) {
                    delete.setLong(1, userId);
                    delete.executeUpdate();
                }
            }
        }
    }

    private long insertPeriodTestUser(Connection connection) throws Exception {
        try (PreparedStatement insert = connection.prepareStatement("""
            INSERT INTO users (
                provider,
                provider_user_id,
                nickname,
                created_at,
                updated_at
            ) VALUES ('KAKAO', 'period-test-177', 'period-test', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            """, Statement.RETURN_GENERATED_KEYS)) {
            insert.executeUpdate();
            try (ResultSet keys = insert.getGeneratedKeys()) {
                assertThat(keys.next()).isTrue();
                return keys.getLong(1);
            }
        }
    }

    private long findMissionId(Connection connection, String code) throws Exception {
        try (PreparedStatement select = connection.prepareStatement(
            "SELECT mission_id FROM missions WHERE code = ?"
        )) {
            select.setString(1, code);
            try (ResultSet row = select.executeQuery()) {
                assertThat(row.next()).isTrue();
                return row.getLong(1);
            }
        }
    }

    private void insertUserMission(
        Connection connection,
        long userId,
        long missionId,
        String period
    ) throws Exception {
        try (PreparedStatement insert = connection.prepareStatement("""
            INSERT INTO user_missions (user_id, mission_id, completed_at, completion_period)
            VALUES (?, ?, CURRENT_TIMESTAMP, ?)
            """)) {
            insert.setLong(1, userId);
            insert.setLong(2, missionId);
            insert.setString(3, period);
            insert.executeUpdate();
        }
    }

    private void insertRewardHistory(
        Connection connection,
        long userId,
        long missionId,
        String period
    ) throws Exception {
        try (PreparedStatement insert = connection.prepareStatement("""
            INSERT INTO reward_histories (
                user_id,
                reward_type,
                reward_name,
                source_type,
                source_id,
                source_period,
                created_at
            ) VALUES (?, 'ITEM', 'period-test', 'MISSION', ?, ?, CURRENT_TIMESTAMP)
            """)) {
            insert.setLong(1, userId);
            insert.setLong(2, missionId);
            insert.setString(3, period);
            insert.executeUpdate();
        }
    }

    private long countRows(Connection connection, String tableName, long userId) throws Exception {
        try (PreparedStatement select = connection.prepareStatement(
            "SELECT COUNT(*) FROM " + tableName + " WHERE user_id = ?"
        )) {
            select.setLong(1, userId);
            try (ResultSet row = select.executeQuery()) {
                assertThat(row.next()).isTrue();
                return row.getLong(1);
            }
        }
    }
}
