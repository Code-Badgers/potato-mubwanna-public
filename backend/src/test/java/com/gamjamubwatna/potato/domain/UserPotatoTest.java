package com.gamjamubwatna.potato.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;

import com.gamjamubwatna.auth.domain.User;
import java.time.Instant;
import org.junit.jupiter.api.Test;

class UserPotatoTest {

    @Test
    void addsGrowthDistanceWithoutLevelUpBeforeGoal() {
        UserPotato userPotato = userPotato(2, 1500.0);

        userPotato.addGrowthDistance(1000.0);

        assertThat(userPotato.getLevel()).isEqualTo(2);
        assertThat(userPotato.getGrowthDistance()).isEqualTo(2500.0);
    }

    @Test
    void carriesRemainingDistanceAcrossMultipleLevelUps() {
        UserPotato userPotato = userPotato(2, 2500.0);

        userPotato.addGrowthDistance(4000.0);

        assertThat(userPotato.getLevel()).isEqualTo(4);
        assertThat(userPotato.getGrowthDistance()).isEqualTo(500.0);
    }

    @Test
    void capsCompletedPotatoAtMaximumLevelAndFullProgress() {
        UserPotato userPotato = userPotato(4, 2500.0);

        userPotato.addGrowthDistance(4000.0);

        assertThat(userPotato.getLevel()).isEqualTo(5);
        assertThat(userPotato.getGrowthDistance()).isEqualTo(3000.0);
    }

    private UserPotato userPotato(int level, double growthDistance) {
        Potato potato = new Potato(
            "POTATO_TEST",
            "테스트감자",
            "강릉시",
            PotatoRarity.COMMON,
            "테스트 설명",
            "테스트 획득 방법",
            null,
            3000.0,
            1,
            true,
            Instant.parse("2026-07-01T00:00:00Z")
        );
        return new UserPotato(
            mock(User.class),
            potato,
            Instant.parse("2026-07-01T00:00:00Z"),
            level,
            growthDistance,
            true
        );
    }
}
