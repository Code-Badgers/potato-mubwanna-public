package com.gamjamubwatna.potato.application;

import com.gamjamubwatna.potato.domain.PotatoCareStatus;
import com.gamjamubwatna.potato.domain.PotatoInteractionAction;
import com.gamjamubwatna.potato.domain.UserPotato;
import com.gamjamubwatna.potato.domain.UserPotatoInteraction;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Set;
import org.springframework.stereotype.Component;

@Component
public class PotatoCareStatusPolicy {

    private static final int INITIAL_SCORE = 70;
    private static final int CARED_SCORE = 100;
    private static final int MINIMUM_SCORE = 20;

    public PotatoCareStatus calculate(
        UserPotato userPotato,
        List<UserPotatoInteraction> interactions,
        Instant now
    ) {
        return new PotatoCareStatus(
            score(userPotato, interactions, now, Set.of(PotatoInteractionAction.SNACK), 3),
            score(userPotato, interactions, now, Set.of(PotatoInteractionAction.WATER), 4),
            score(
                userPotato,
                interactions,
                now,
                Set.of(PotatoInteractionAction.PAT, PotatoInteractionAction.WALK),
                2
            ),
            now
        );
    }

    private int score(
        UserPotato userPotato,
        List<UserPotatoInteraction> interactions,
        Instant now,
        Set<PotatoInteractionAction> actions,
        int decayPerHour
    ) {
        Instant lastCareAt = interactions.stream()
            .filter(interaction -> actions.contains(interaction.getAction()))
            .map(UserPotatoInteraction::getInteractedAt)
            .max(Instant::compareTo)
            .orElse(null);
        Instant referenceAt = lastCareAt == null ? userPotato.getAcquiredAt() : lastCareAt;
        int startingScore = lastCareAt == null ? INITIAL_SCORE : CARED_SCORE;
        long elapsedHours = now.isAfter(referenceAt)
            ? Duration.between(referenceAt, now).toHours()
            : 0;
        long decayedScore = startingScore - elapsedHours * decayPerHour;
        return (int) Math.max(MINIMUM_SCORE, decayedScore);
    }
}
