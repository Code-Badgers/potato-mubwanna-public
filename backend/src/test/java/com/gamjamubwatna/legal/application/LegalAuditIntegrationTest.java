package com.gamjamubwatna.legal.application;

import static org.assertj.core.api.Assertions.assertThat;

import com.gamjamubwatna.legal.api.LegalConsentSnapshotResponse;
import com.gamjamubwatna.legal.api.LegalConsentSyncRequest;
import java.time.Instant;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;

@SpringBootTest(properties = {
    "spring.datasource.url=jdbc:h2:mem:legal_audit;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.jpa.hibernate.ddl-auto=validate",
    "auth.jwt.secret=test-jwt-secret-must-be-long-enough"
})
class LegalAuditIntegrationTest {

    @Autowired
    private LegalConsentService legalConsentService;

    @Autowired
    private LocationUsageLogService locationUsageLogService;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @BeforeEach
    void setUpUser() {
        jdbcTemplate.update("DELETE FROM legal_consent_events");
        jdbcTemplate.update("DELETE FROM location_usage_logs");
        jdbcTemplate.update("DELETE FROM users WHERE user_id = 3001");
        jdbcTemplate.update("""
            INSERT INTO users (
                user_id, provider, provider_user_id, email, nickname, created_at, updated_at
            ) VALUES (
                3001, 'KAKAO', 'legal-audit-user', 'legal@example.com', '동의검증',
                CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
            )
            """);
    }

    @Test
    void keepsIdempotentConsentHistoryAndRecordsWithdrawal() {
        LegalConsentSyncRequest accepted = new LegalConsentSyncRequest(
            "2026-08-14-v1",
            "2026-08-14-v1",
            null
        );

        legalConsentService.synchronize(3001L, accepted);
        legalConsentService.synchronize(3001L, accepted);

        assertThat(consentEventCount()).isEqualTo(2);

        legalConsentService.synchronize(
            3001L,
            new LegalConsentSyncRequest("2026-08-14-v1", null, null)
        );

        assertThat(consentEventCount()).isEqualTo(3);
        Boolean latestLocationAccepted = jdbcTemplate.queryForObject("""
            SELECT accepted
            FROM legal_consent_events
            WHERE user_id = 3001 AND consent_type = 'PERSONAL_LOCATION'
            ORDER BY recorded_at DESC, legal_consent_event_id DESC
            LIMIT 1
            """, Boolean.class);
        assertThat(latestLocationAccepted).isFalse();
    }

    @Test
    void returnsOnlyLatestAcceptedConsentVersions() {
        legalConsentService.synchronize(
            3001L,
            new LegalConsentSyncRequest(
                "2026-08-15-v2",
                "2026-08-14-v1",
                "2026-08-14-v1"
            )
        );
        legalConsentService.synchronize(
            3001L,
            new LegalConsentSyncRequest("2026-08-15-v2", null, "2026-08-14-v1")
        );

        LegalConsentSnapshotResponse snapshot = legalConsentService.getSnapshot(3001L);

        assertThat(snapshot.requiredDocumentsVersion()).isEqualTo("2026-08-15-v2");
        assertThat(snapshot.personalLocationConsentVersion()).isNull();
        assertThat(snapshot.healthDataConsentVersion()).isEqualTo("2026-08-14-v1");
    }

    @Test
    void storesLocationUsageWithoutCoordinatesAndPurgesExpiredRows() {
        Instant usedAt = Instant.parse("2026-08-14T00:00:00Z");

        locationUsageLogService.recordVisitVerification(3001L, usedAt, true);

        assertThat(jdbcTemplate.queryForObject(
            "SELECT COUNT(*) FROM location_usage_logs WHERE user_id = 3001",
            Integer.class
        )).isEqualTo(1);
        assertThat(jdbcTemplate.queryForObject(
            "SELECT acquisition_source FROM location_usage_logs WHERE user_id = 3001",
            String.class
        )).isEqualTo("DEVICE_GPS");
        assertThat(jdbcTemplate.queryForObject(
            "SELECT purpose FROM location_usage_logs WHERE user_id = 3001",
            String.class
        )).isEqualTo("VISIT_VERIFICATION");
        assertThat(jdbcTemplate.queryForObject(
            "SELECT expires_at FROM location_usage_logs WHERE user_id = 3001",
            Instant.class
        )).isEqualTo(Instant.parse("2027-02-14T00:00:00Z"));

        jdbcTemplate.update(
            "UPDATE location_usage_logs SET expires_at = CURRENT_TIMESTAMP - INTERVAL '1' DAY"
        );
        locationUsageLogService.purgeExpired();

        assertThat(jdbcTemplate.queryForObject(
            "SELECT COUNT(*) FROM location_usage_logs WHERE user_id = 3001",
            Integer.class
        )).isZero();
    }

    private int consentEventCount() {
        Integer count = jdbcTemplate.queryForObject(
            "SELECT COUNT(*) FROM legal_consent_events WHERE user_id = 3001",
            Integer.class
        );
        return count == null ? 0 : count;
    }
}
