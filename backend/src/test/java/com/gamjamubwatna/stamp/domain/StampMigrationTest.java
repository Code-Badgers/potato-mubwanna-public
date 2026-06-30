package com.gamjamubwatna.stamp.domain;

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
    "spring.datasource.url=jdbc:h2:mem:stamp_migration;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.jpa.hibernate.ddl-auto=validate",
    "auth.jwt.secret=test-jwt-secret-must-be-long-enough"
})
class StampMigrationTest {

    @Autowired
    private StampRepository stampRepository;

    @Autowired
    private DataSource dataSource;

    @Test
    void seedsEighteenGangwonStampsInDisplayOrder() {
        List<Stamp> stamps = stampRepository.findAllByOrderByDisplayOrderAsc();

        assertThat(stamps).hasSize(18);
        assertThat(stamps.getFirst().getCityName()).isEqualTo("강릉시");
        assertThat(stamps.getLast().getCityName()).isEqualTo("철원군");
        assertThat(stamps)
            .extracting(Stamp::getDisplayOrder)
            .containsExactlyElementsOf(java.util.stream.IntStream.rangeClosed(1, 18).boxed().toList());
    }

    @Test
    void createsTouristSpotForeignKeyIndex() throws Exception {
        Set<String> indexNames = new HashSet<>();
        try (
            Connection connection = dataSource.getConnection();
            ResultSet indexes = connection.getMetaData()
                .getIndexInfo(null, null, "user_stamps", false, false)
        ) {
            while (indexes.next()) {
                String indexName = indexes.getString("INDEX_NAME");
                if (indexName != null) {
                    indexNames.add(indexName.toLowerCase());
                }
            }
        }

        assertThat(indexNames).contains("idx_user_stamps_tourist_spot_id");
    }
}
