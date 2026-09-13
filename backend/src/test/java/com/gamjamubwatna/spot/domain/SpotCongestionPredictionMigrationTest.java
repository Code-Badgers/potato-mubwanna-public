package com.gamjamubwatna.spot.domain;

import static org.assertj.core.api.Assertions.assertThat;

import java.sql.Connection;
import java.sql.ResultSet;
import java.util.HashSet;
import java.util.Set;
import javax.sql.DataSource;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = {
    "spring.datasource.url=jdbc:h2:mem:spot_congestion_migration;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.jpa.hibernate.ddl-auto=validate",
    "auth.jwt.secret=test-jwt-secret-must-be-long-enough"
})
class SpotCongestionPredictionMigrationTest {

    @Autowired
    private SpotCongestionPredictionRepository spotCongestionPredictionRepository;

    @Autowired
    private DataSource dataSource;

    @Autowired
    private TouristSpotRepository touristSpotRepository;

    @Test
    @org.springframework.transaction.annotation.Transactional
    void batchQueryReturnsOnlyRequestedSpotsAndTodayInNewestSourceOrder() {
        var spot = touristSpotRepository.findAll().getFirst();
        var today = java.time.LocalDate.of(2026, 9, 13);
        var instant = java.time.Instant.parse("2026-09-13T00:00:00Z");
        for (int offset : new int[]{-1, 0, 1}) {
            spotCongestionPredictionRepository.save(new SpotCongestionPrediction(
                spot, today.plusDays(offset), 10, 100, CongestionLevel.LOW, "OLD_SOURCE", instant));
        }
        spotCongestionPredictionRepository.saveAndFlush(new SpotCongestionPrediction(
            spot, today, 80, 100, CongestionLevel.HIGH, "NEW_SOURCE", instant.plusSeconds(60)));
        var results = spotCongestionPredictionRepository.findTodayPredictions(java.util.List.of(spot.getId()), today);
        assertThat(results).hasSize(2);
        assertThat(results).extracting(SpotCongestionPrediction::getSource)
            .containsExactly("NEW_SOURCE", "OLD_SOURCE");
        assertThat(results).allMatch(prediction -> prediction.getPredictionDate().equals(today));
        assertThat(spotCongestionPredictionRepository.findTodayPredictions(java.util.List.of(-1L), today)).isEmpty();
    }

    @Test
    void createsSpotCongestionPredictionTableAndLookupIndexes() throws Exception {
        assertThat(spotCongestionPredictionRepository.findAll()).isEmpty();

        Set<String> indexNames = new HashSet<>();
        try (
            Connection connection = dataSource.getConnection();
            ResultSet indexes = connection.getMetaData()
                .getIndexInfo(null, null, "spot_congestion_predictions", false, false)
        ) {
            while (indexes.next()) {
                String indexName = indexes.getString("INDEX_NAME");
                if (indexName != null) {
                    indexNames.add(indexName.toLowerCase());
                }
            }
        }

        assertThat(indexNames)
            .contains("idx_spot_congestion_predictions_spot_date");
    }
}
