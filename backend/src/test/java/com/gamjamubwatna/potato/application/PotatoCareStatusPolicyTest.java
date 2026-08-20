package com.gamjamubwatna.potato.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.potato.domain.PotatoCareStatus;
import com.gamjamubwatna.potato.domain.PotatoInteractionAction;
import com.gamjamubwatna.potato.domain.UserPotato;
import com.gamjamubwatna.potato.domain.UserPotatoInteraction;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.Test;

class PotatoCareStatusPolicyTest {

    private final PotatoCareStatusPolicy policy = new PotatoCareStatusPolicy();

    @Test
    void decaysInitialStatusFromAcquisitionTime() {
        Instant acquiredAt = Instant.parse("2026-08-20T00:00:00Z");
        UserPotato userPotato = userPotato(acquiredAt);

        PotatoCareStatus status = policy.calculate(
            userPotato,
            List.of(),
            Instant.parse("2026-08-20T05:00:00Z")
        );

        assertThat(status.satiety()).isEqualTo(55);
        assertThat(status.moisture()).isEqualTo(50);
        assertThat(status.mood()).isEqualTo(60);
    }

    @Test
    void restoresEachStatusFromPersistedCareActions() {
        UserPotato userPotato = userPotato(Instant.parse("2026-08-01T00:00:00Z"));
        List<UserPotatoInteraction> interactions = List.of(
            interaction(PotatoInteractionAction.SNACK, "2026-08-20T03:00:00Z"),
            interaction(PotatoInteractionAction.WATER, "2026-08-20T00:00:00Z"),
            interaction(PotatoInteractionAction.PAT, "2026-08-20T02:00:00Z"),
            interaction(PotatoInteractionAction.WALK, "2026-08-20T04:00:00Z")
        );

        PotatoCareStatus status = policy.calculate(
            userPotato,
            interactions,
            Instant.parse("2026-08-20T05:00:00Z")
        );

        assertThat(status.satiety()).isEqualTo(94);
        assertThat(status.moisture()).isEqualTo(80);
        assertThat(status.mood()).isEqualTo(98);
    }

    @Test
    void keepsEveryStatusAtMinimumAfterLongInactivity() {
        UserPotato userPotato = userPotato(Instant.parse("2026-08-01T00:00:00Z"));

        PotatoCareStatus status = policy.calculate(
            userPotato,
            List.of(),
            Instant.parse("2026-08-20T00:00:00Z")
        );

        assertThat(status.satiety()).isEqualTo(20);
        assertThat(status.moisture()).isEqualTo(20);
        assertThat(status.mood()).isEqualTo(20);
    }

    private UserPotato userPotato(Instant acquiredAt) {
        UserPotato userPotato = mock(UserPotato.class);
        when(userPotato.getAcquiredAt()).thenReturn(acquiredAt);
        return userPotato;
    }

    private UserPotatoInteraction interaction(PotatoInteractionAction action, String interactedAt) {
        UserPotatoInteraction interaction = mock(UserPotatoInteraction.class);
        when(interaction.getAction()).thenReturn(action);
        when(interaction.getInteractedAt()).thenReturn(Instant.parse(interactedAt));
        return interaction;
    }
}
