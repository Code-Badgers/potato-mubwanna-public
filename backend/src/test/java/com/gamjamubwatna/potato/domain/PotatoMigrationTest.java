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

        assertThat(potatoes).hasSize(15);
        assertThat(potatoes.getFirst().getCode()).isEqualTo("POTATO_HAJI_GANGNEUNG");
        assertThat(potatoes.getFirst().getRarity()).isEqualTo(PotatoRarity.COMMON);
        assertThat(potatoes.getLast().getCode()).isEqualTo("POTATO_RARE_SEED");
        assertThat(potatoes)
            .extracting(Potato::getCode)
            .containsExactly(
                "POTATO_HAJI_GANGNEUNG",
                "POTATO_GONDRE_JEONGSEON",
                "POTATO_GOLDEN_GANGWON",
                "POTATO_LEGEND_PYEONGCHANG",
                "POTATO_PEACE_COSUNG",
                "POTATO_HAJI_SEED",
                "POTATO_JAJU_SEED",
                "POTATO_DURUMI_SEED",
                "POTATO_HANWOO_SEED",
                "POTATO_COMMON_SEED",
                "POTATO_GOLDEN_HONGCHEON",
                "POTATO_JAJAK_INJE",
                "POTATO_LEGEND_YANGGU",
                "POTATO_HOBAN_CHUNCHEON",
                "POTATO_RARE_SEED"
            );
    }

    @Test
    void everyPotatoMissionRewardCodeExistsInCatalog() throws Exception {
        Set<String> potatoCodes = new HashSet<>();
        Set<String> potatoRewardLabels = new HashSet<>();
        try (
            Connection connection = dataSource.getConnection();
            ResultSet potatoes = connection.createStatement()
                .executeQuery("SELECT code FROM potatoes WHERE active = TRUE");
        ) {
            while (potatoes.next()) {
                potatoCodes.add(potatoes.getString("code"));
            }
        }
        try (
            Connection connection = dataSource.getConnection();
            ResultSet rewards = connection.createStatement()
                .executeQuery("SELECT reward_label FROM missions WHERE reward_type = 'POTATO'");
        ) {
            while (rewards.next()) {
                potatoRewardLabels.add(rewards.getString("reward_label"));
            }
        }

        assertThat(potatoRewardLabels).isNotEmpty();
        Set<String> missingRewardLabels = new HashSet<>(potatoRewardLabels);
        missingRewardLabels.removeAll(potatoCodes);
        assertThat(missingRewardLabels).isEmpty();
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
