package com.gamjamubwatna.coupon.domain;

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
    "spring.datasource.url=jdbc:h2:mem:coupon_migration;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.jpa.hibernate.ddl-auto=validate",
    "auth.jwt.secret=test-jwt-secret-must-be-long-enough"
})
class CouponMigrationTest {

    @Autowired
    private DataSource dataSource;

    @Autowired
    private CouponRepository couponRepository;

    @Test
    void seedsMissionAndStampRewardCouponCatalog() {
        List<Coupon> coupons = couponRepository.findAll();
        List<Coupon> seededCoupons = coupons.stream()
            .filter(coupon -> coupon.getCode() != null)
            .toList();

        assertThat(seededCoupons)
            .hasSize(10)
            .extracting(Coupon::getCode)
            .contains(
                "CP_PYEONGCHANG_EXPERIENCE",
                "CP_HWACHEON_FISH_FREE",
                "CP_STAMP_6_LOCAL_3000",
                "CP_STAMP_12_LOCAL_5000",
                "CP_STAMP_18_COMPLETE_10000"
            );
        assertThat(seededCoupons)
            .allSatisfy(coupon -> assertThat(coupon.getValidDays()).isEqualTo(30));
        assertThat(seededCoupons.stream()
            .filter(coupon -> coupon.getCode().startsWith("CP_STAMP_")))
            .hasSize(3);
        assertThat(seededCoupons.stream()
            .filter(coupon -> !coupon.getCode().startsWith("CP_STAMP_")))
            .hasSize(7);

        assertThat(couponRepository.findByCode("CP_STAMP_6_LOCAL_3000"))
            .get()
            .extracting(Coupon::getName, Coupon::getBenefitAmount)
            .containsExactly("강원 감자 제휴점 3,000원 할인권", 3000);
        assertThat(couponRepository.findByCode("CP_STAMP_12_LOCAL_5000"))
            .get()
            .extracting(Coupon::getName, Coupon::getBenefitAmount)
            .containsExactly("강원 감자 제휴점 5,000원 할인권", 5000);
        assertThat(couponRepository.findByCode("CP_STAMP_18_COMPLETE_10000"))
            .get()
            .extracting(Coupon::getName, Coupon::getBenefitAmount)
            .containsExactly("강원 감자 랠리 완주 10,000원 할인권", 10000);
    }

    @Test
    void createsUserCouponLookupIndexes() throws Exception {
        Set<String> indexNames = new HashSet<>();
        try (
            Connection connection = dataSource.getConnection();
            ResultSet indexes = connection.getMetaData()
                .getIndexInfo(null, null, "user_coupons", false, false)
        ) {
            while (indexes.next()) {
                String indexName = indexes.getString("INDEX_NAME");
                if (indexName != null) {
                    indexNames.add(indexName.toLowerCase());
                }
            }
        }

        assertThat(indexNames).contains(
            "idx_user_coupons_user_id_issued_at",
            "idx_user_coupons_coupon_id"
        );
    }
}
