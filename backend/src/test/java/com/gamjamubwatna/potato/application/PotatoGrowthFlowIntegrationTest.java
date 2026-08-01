package com.gamjamubwatna.potato.application;

import static org.assertj.core.api.Assertions.assertThat;

import com.gamjamubwatna.auth.domain.AuthProvider;
import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.potato.api.PotatoDailyActivitySyncRequest;
import com.gamjamubwatna.potato.api.PotatoDailyActivitySyncResponse;
import com.gamjamubwatna.potato.api.PotatoGrowthSummaryResponse;
import com.gamjamubwatna.potato.domain.ActivitySource;
import com.gamjamubwatna.potato.domain.Potato;
import com.gamjamubwatna.potato.domain.PotatoRepository;
import com.gamjamubwatna.potato.domain.UserPotato;
import com.gamjamubwatna.potato.domain.UserPotatoRepository;
import java.time.Instant;
import java.time.LocalDate;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = {
    "spring.datasource.url=jdbc:h2:mem:potato_growth_flow;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.jpa.hibernate.ddl-auto=validate",
    "auth.jwt.secret=test-jwt-secret-must-be-long-enough",
    "coupon.qr.secret=test-coupon-qr-secret-must-be-long-enough"
})
class PotatoGrowthFlowIntegrationTest {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PotatoRepository potatoRepository;

    @Autowired
    private UserPotatoRepository userPotatoRepository;

    @Autowired
    private PotatoCommandService potatoCommandService;

    @Autowired
    private PotatoQueryService potatoQueryService;

    @Test
    void appliesOnlyIncreasedDailyDistanceToRepresentativePotatoGrowth() {
        User user = userRepository.save(new User(
            AuthProvider.KAKAO,
            "potato-growth-user",
            null,
            "감자 성장 사용자",
            null,
            Instant.parse("2026-08-01T00:00:00Z")
        ));
        Potato potato = potatoRepository.findByActiveTrueOrderByDisplayOrderAsc()
            .getFirst();
        userPotatoRepository.save(new UserPotato(
            user,
            potato,
            Instant.parse("2026-08-01T00:00:00Z"),
            1,
            0.0,
            true
        ));
        LocalDate today = LocalDate.parse("2026-08-01");

        PotatoDailyActivitySyncResponse initial = sync(
            user.getId(),
            today,
            3000,
            2000.0
        );
        PotatoDailyActivitySyncResponse decreased = sync(
            user.getId(),
            today,
            2500,
            1500.0
        );
        PotatoDailyActivitySyncResponse leveledUp = sync(
            user.getId(),
            today,
            6000,
            4500.0
        );

        assertThat(initial.growthResult()).isNotNull();
        assertThat(initial.growthResult().leveledUp()).isFalse();
        assertThat(decreased.growthResult()).isNull();
        assertThat(leveledUp.growthResult()).isNotNull();
        assertThat(leveledUp.growthResult().previousLevel()).isEqualTo(1);
        assertThat(leveledUp.growthResult().currentLevel()).isEqualTo(2);
        assertThat(leveledUp.growthResult().leveledUp()).isTrue();

        UserPotato grownPotato = userPotatoRepository.findByUserId(user.getId()).getFirst();
        assertThat(grownPotato.getLevel()).isEqualTo(2);
        assertThat(grownPotato.getGrowthDistance()).isEqualTo(1500.0);

        PotatoGrowthSummaryResponse summary = potatoQueryService.getGrowthSummary(
            user.getId(),
            today
        );
        assertThat(summary.todaySteps()).isEqualTo(6000);
        assertThat(summary.weeklyDistanceKm()).isEqualTo(4.5);
        assertThat(summary.monthlyDistanceKm()).isEqualTo(4.5);
        assertThat(summary.remainingDistanceKmForRepresentative()).isEqualTo(1.5);
    }

    private PotatoDailyActivitySyncResponse sync(
        Long userId,
        LocalDate date,
        int steps,
        double distanceMeters
    ) {
        return potatoCommandService.syncDailyActivity(
            userId,
            new PotatoDailyActivitySyncRequest(
                date,
                steps,
                distanceMeters,
                ActivitySource.HEALTH_CONNECT
            )
        );
    }
}
