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
        UserPotato userPotato = userPotato(PotatoRarity.RARE, 2, 2500.0);

        userPotato.addGrowthDistance(4000.0);

        assertThat(userPotato.getLevel()).isEqualTo(4);
        assertThat(userPotato.getGrowthDistance()).isEqualTo(500.0);
    }

    @Test
    void capsCommonPotatoAtLevelThreeAndFullProgress() {
        UserPotato userPotato = userPotato(PotatoRarity.COMMON, 2, 2500.0);

        userPotato.addGrowthDistance(4000.0);

        assertThat(userPotato.getLevel()).isEqualTo(3);
        assertThat(userPotato.getGrowthDistance()).isEqualTo(3000.0);
    }

    @Test
    void appliesRarityBasedMaximumLevels() {
        assertThat(potato(PotatoRarity.COMMON).getMaxGrowthLevel()).isEqualTo(3);
        assertThat(potato(PotatoRarity.RARE).getMaxGrowthLevel()).isEqualTo(5);
        assertThat(potato(PotatoRarity.EPIC).getMaxGrowthLevel()).isEqualTo(8);
        assertThat(potato(PotatoRarity.LEGENDARY).getMaxGrowthLevel()).isEqualTo(10);
    }

    private UserPotato userPotato(int level, double growthDistance) {
        return userPotato(PotatoRarity.COMMON, level, growthDistance);
    }

    private UserPotato userPotato(PotatoRarity rarity, int level, double growthDistance) {
        Potato potato = potato(rarity);
        return new UserPotato(
            mock(User.class),
            potato,
            Instant.parse("2026-07-01T00:00:00Z"),
            level,
            growthDistance,
            true
        );
    }

    private Potato potato(PotatoRarity rarity) {
        return new Potato(
            "POTATO_TEST",
            "테스트감자",
            "강릉시",
            rarity,
            "테스트 설명",
            "테스트 획득 방법",
            null,
            3000.0,
            1,
            true,
            Instant.parse("2026-07-01T00:00:00Z")
        );
    }
}
