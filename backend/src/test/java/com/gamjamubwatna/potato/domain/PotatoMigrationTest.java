package com.gamjamubwatna.potato.domain;

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
    "spring.datasource.url=jdbc:h2:mem:potato_migration;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.jpa.hibernate.ddl-auto=validate",
    "auth.jwt.secret=test-jwt-secret-must-be-long-enough"
})
class PotatoMigrationTest {

    @Autowired
    private PotatoRepository potatoRepository;

    @Autowired
    private DataSource dataSource;

    @Test
    void seedsBasePotatoCatalogInDisplayOrder() {
        List<Potato> potatoes = potatoRepository.findByActiveTrueOrderByDisplayOrderAsc();

        assertThat(potatoes).hasSize(5);
        assertThat(potatoes.getFirst().getCode()).isEqualTo("POTATO_HAJI_GANGNEUNG");
        assertThat(potatoes.getFirst().getRarity()).isEqualTo(PotatoRarity.COMMON);
        assertThat(potatoes.getLast().getCode()).isEqualTo("POTATO_PEACE_COSUNG");
    }

    @Test
    void createsUserPotatoLookupIndexes() throws Exception {
        Set<String> indexNames = new HashSet<>();
        try (
            Connection connection = dataSource.getConnection();
            ResultSet indexes = connection.getMetaData()
                .getIndexInfo(null, null, "user_potatoes", false, false)
        ) {
            while (indexes.next()) {
                String indexName = indexes.getString("INDEX_NAME");
                if (indexName != null) {
                    indexNames.add(indexName.toLowerCase());
                }
            }
        }

        assertThat(indexNames)
            .contains("idx_user_potatoes_user_id_representative");
    }
}
