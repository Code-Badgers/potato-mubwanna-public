package com.gamjamubwatna.visit.domain;

import static org.assertj.core.api.Assertions.assertThat;

import java.sql.Connection;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.sql.DataSource;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = {
    "spring.datasource.url=jdbc:h2:mem:user_visit_migration;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.jpa.hibernate.ddl-auto=validate",
    "auth.jwt.secret=test-jwt-secret-must-be-long-enough"
})
class UserVisitMigrationTest {

    @Autowired
    private UserVisitRepository userVisitRepository;

    @Autowired
    private DataSource dataSource;

    @Test
    void createsUserVisitTableAndUniqueConstraint() throws Exception {
        assertThat(userVisitRepository.findAll()).isEmpty();

        Map<String, List<String>> uniqueIndexColumns = new HashMap<>();
        try (
            Connection connection = dataSource.getConnection();
            ResultSet indexes = connection.getMetaData()
                .getIndexInfo(null, null, "user_visits", false, false)
        ) {
            while (indexes.next()) {
                String indexName = indexes.getString("INDEX_NAME");
                String columnName = indexes.getString("COLUMN_NAME");
                if (indexName != null && columnName != null && !indexes.getBoolean("NON_UNIQUE")) {
                    uniqueIndexColumns.computeIfAbsent(indexName, ignored -> new ArrayList<>())
                        .add(columnName.toLowerCase());
                }
            }
        }

        assertThat(uniqueIndexColumns.values())
            .contains(List.of("user_id", "tourist_spot_id"));
    }
}
